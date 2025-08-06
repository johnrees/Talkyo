#!/bin/bash
echo "Testing API key availability..."
if [ -n "$ELEVENLABS_API_KEY" ]; then
    echo "API key is available (length: ${#ELEVENLABS_API_KEY})"
else
    echo "API key is NOT available"
fi