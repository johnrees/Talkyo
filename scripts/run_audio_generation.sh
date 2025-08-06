#!/bin/bash

# Script to generate test audio files for Talkyo e2e tests
# Requires ELEVENLABS_API_KEY environment variable

set -e

echo "🎵 Talkyo Test Audio Generator"
echo "=============================="

# Check for API key
if [ -z "$ELEVENLABS_API_KEY" ]; then
    echo "❌ Error: ELEVENLABS_API_KEY environment variable is required"
    echo "   Please set your ElevenLabs API key:"
    echo "   export ELEVENLABS_API_KEY=\"your_api_key_here\""
    exit 1
fi

echo "✅ API key found (${#ELEVENLABS_API_KEY} characters)"

# Create output directory
OUTPUT_DIR="../TalkyoTests/TestAudio"
mkdir -p "$OUTPUT_DIR"

# Voice ID for multilingual voice (Rachel)
VOICE_ID="21m00Tcm4TlvDq8ikWAM"

echo "📁 Output directory: $OUTPUT_DIR"
echo "🎤 Using voice ID: $VOICE_ID"
echo ""

# Function to generate audio with progress indication
generate_audio() {
    local text="$1"
    local filename="$2"
    local output_path="$OUTPUT_DIR/$filename"
    
    echo -n "🎯 Generating $filename... "
    
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
    
    if [ $? -eq 0 ] && [ -f "$output_path" ] && [ -s "$output_path" ]; then
        local file_size=$(stat -f%z "$output_path" 2>/dev/null || stat -c%s "$output_path" 2>/dev/null || echo "unknown")
        echo "✅ Success! (${file_size} bytes)"
        return 0
    else
        echo "❌ Failed!"
        return 1
    fi
}

# Generate test audio files
echo "🚀 Starting audio generation..."
echo ""

success_count=0
total_count=5

generate_audio "こんにちは" "konnichiwa.wav" && ((success_count++))
generate_audio "ありがとうございます" "arigatou.wav" && ((success_count++))
generate_audio "さようなら" "sayounara.wav" && ((success_count++))
generate_audio "今日は良い天気ですね" "weather.wav" && ((success_count++))
generate_audio "図書館で本を読んでいます" "library.wav" && ((success_count++))

echo ""

# Create metadata file
echo "📋 Creating metadata file..."

cat > "$OUTPUT_DIR/test_metadata.json" << 'EOF'
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
  "voice_model": "eleven_multilingual_v2",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"
}
EOF

echo "✅ Metadata created: $OUTPUT_DIR/test_metadata.json"

# Summary
echo ""
echo "📊 Generation Summary:"
echo "====================="
echo "✅ Successful: $success_count/$total_count files"
echo "📁 Location: $OUTPUT_DIR"

if [ $success_count -eq $total_count ]; then
    echo ""
    echo "🎉 All audio files generated successfully!"
    echo "   You can now run the e2e tests in Xcode."
    echo ""
    echo "📝 Next Steps:"
    echo "   1. Add test targets to your Xcode project"
    echo "   2. Add test files to appropriate targets"
    echo "   3. Run tests with CMD+U (unit) or UI test suite"
    exit 0
else
    echo ""
    echo "⚠️  Some files failed to generate. Check your API key and network connection."
    exit 1
fi