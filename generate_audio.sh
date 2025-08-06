#!/bin/bash

# Check if API key is set
if [ -z "$ELEVENLABS_API_KEY" ]; then
    echo "Error: ELEVENLABS_API_KEY environment variable not set"
    exit 1
fi

# Create output directory
mkdir -p TalkyoTests/TestAudio

# Voice ID for multilingual voice (Rachel)
VOICE_ID="21m00Tcm4TlvDq8ikWAM"

# Function to generate audio
generate_audio() {
    local text="$1"
    local filename="$2"
    local output_path="TalkyoTests/TestAudio/$filename"
    
    echo "Generating: $filename for text: $text"
    
    curl -X POST \
        "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
        -H "Accept: audio/wav" \
        -H "Content-Type: application/json" \
        -H "xi-api-key: $ELEVENLABS_API_KEY" \
        -d "{
            \"text\": \"$text\",
            \"model_id\": \"eleven_multilingual_v2\",
            \"voice_settings\": {
                \"stability\": 0.5,
                \"similarity_boost\": 0.75,
                \"style\": 0.0,
                \"use_speaker_boost\": true
            }
        }" \
        --output "$output_path" \
        --silent \
        --show-error
    
    if [ $? -eq 0 ]; then
        echo "✓ Generated: $output_path"
        return 0
    else
        echo "✗ Failed: $output_path"
        return 1
    fi
}

# Generate test audio files
echo "Starting audio generation..."

generate_audio "こんにちは" "konnichiwa.wav"
generate_audio "ありがとうございます" "arigatou.wav" 
generate_audio "さようなら" "sayounara.wav"
generate_audio "今日は良い天気ですね" "weather.wav"
generate_audio "図書館で本を読んでいます" "library.wav"

# Create metadata file
cat > TalkyoTests/TestAudio/test_metadata.json << 'EOF'
{
  "test_audio_files": [
    {
      "filename": "konnichiwa.wav",
      "text": "こんにちは",
      "expected_transcription": "こんにちは"
    },
    {
      "filename": "arigatou.wav",
      "text": "ありがとうございます",
      "expected_transcription": "ありがとうございます"
    },
    {
      "filename": "sayounara.wav",
      "text": "さようなら",
      "expected_transcription": "さようなら"
    },
    {
      "filename": "weather.wav",
      "text": "今日は良い天気ですね",
      "expected_transcription": "今日は良い天気ですね"
    },
    {
      "filename": "library.wav",
      "text": "図書館で本を読んでいます",
      "expected_transcription": "図書館で本を読んでいます"
    }
  ],
  "audio_format": "wav",
  "sample_rate": 22050,
  "channels": 1,
  "voice_model": "eleven_multilingual_v2"
}
EOF

echo "✓ Created metadata file: TalkyoTests/TestAudio/test_metadata.json"

# List generated files
echo -e "\nGenerated files:"
ls -la TalkyoTests/TestAudio/

echo -e "\nAudio generation complete!"