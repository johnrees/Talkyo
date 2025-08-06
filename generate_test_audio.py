#!/usr/bin/env python3

import os
import requests
import json
from pathlib import Path

def generate_audio_with_elevenlabs(text, voice_id, api_key, output_path):
    """Generate audio using ElevenLabs API"""
    
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    
    headers = {
        "Accept": "audio/wav",
        "Content-Type": "application/json",
        "xi-api-key": api_key
    }
    
    data = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75,
            "style": 0.0,
            "use_speaker_boost": True
        }
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        response.raise_for_status()
        
        with open(output_path, 'wb') as f:
            f.write(response.content)
        
        print(f"Generated audio: {output_path}")
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"Failed to generate audio for '{text}': {e}")
        return False

def main():
    # Get API key from environment
    api_key = os.getenv('ELEVENLABS_API_KEY')
    if not api_key:
        print("Error: ELEVENLABS_API_KEY environment variable not set")
        return False
    
    # Create output directory
    output_dir = Path("TalkyoTests/TestAudio")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Japanese voice ID - using Rachel (multilingual) or can be changed
    voice_id = "21m00Tcm4TlvDq8ikWAM"  # Rachel voice, good for multiple languages
    
    # Test phrases for Japanese greetings
    test_phrases = [
        {
            "text": "こんにちは",
            "filename": "konnichiwa.wav",
            "expected": "こんにちは"
        },
        {
            "text": "ありがとうございます", 
            "filename": "arigatou.wav",
            "expected": "ありがとうございます"
        },
        {
            "text": "さようなら",
            "filename": "sayounara.wav", 
            "expected": "さようなら"
        },
        {
            "text": "今日は良い天気ですね",
            "filename": "weather.wav",
            "expected": "今日は良い天気ですね"
        },
        {
            "text": "図書館で本を読んでいます",
            "filename": "library.wav",
            "expected": "図書館で本を読んでいます"
        }
    ]
    
    success_count = 0
    
    # Generate audio files
    for phrase in test_phrases:
        output_path = output_dir / phrase["filename"]
        if generate_audio_with_elevenlabs(phrase["text"], voice_id, api_key, output_path):
            success_count += 1
    
    # Create metadata file for tests
    metadata = {
        "test_audio_files": [
            {
                "filename": phrase["filename"],
                "text": phrase["text"],
                "expected_transcription": phrase["expected"]
            }
            for phrase in test_phrases
        ],
        "audio_format": "wav",
        "sample_rate": 22050,
        "channels": 1,
        "voice_model": "eleven_multilingual_v2"
    }
    
    metadata_path = output_dir / "test_metadata.json"
    with open(metadata_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    
    print(f"\nGenerated {success_count}/{len(test_phrases)} audio files")
    print(f"Metadata saved to: {metadata_path}")
    
    return success_count == len(test_phrases)

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)