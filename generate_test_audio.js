#!/usr/bin/env node

const https = require('https');
const fs = require('fs');
const path = require('path');

async function generateAudioWithElevenLabs(text, voiceId, apiKey, outputPath) {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            text: text,
            model_id: "eleven_multilingual_v2",
            voice_settings: {
                stability: 0.5,
                similarity_boost: 0.75,
                style: 0.0,
                use_speaker_boost: true
            }
        });

        const options = {
            hostname: 'api.elevenlabs.io',
            port: 443,
            path: `/v1/text-to-speech/${voiceId}`,
            method: 'POST',
            headers: {
                'Accept': 'audio/wav',
                'Content-Type': 'application/json',
                'xi-api-key': apiKey,
                'Content-Length': Buffer.byteLength(data)
            }
        };

        const req = https.request(options, (res) => {
            if (res.statusCode !== 200) {
                reject(new Error(`HTTP ${res.statusCode}: ${res.statusMessage}`));
                return;
            }

            const fileStream = fs.createWriteStream(outputPath);
            res.pipe(fileStream);

            fileStream.on('finish', () => {
                fileStream.close();
                console.log(`Generated audio: ${outputPath}`);
                resolve(true);
            });

            fileStream.on('error', (err) => {
                fs.unlink(outputPath, () => {});
                reject(err);
            });
        });

        req.on('error', (err) => {
            reject(err);
        });

        req.write(data);
        req.end();
    });
}

async function main() {
    // Get API key from environment
    const apiKey = process.env.ELEVENLABS_API_KEY;
    if (!apiKey) {
        console.error('Error: ELEVENLABS_API_KEY environment variable not set');
        process.exit(1);
    }

    // Create output directory
    const outputDir = path.join(process.cwd(), 'TalkyoTests', 'TestAudio');
    fs.mkdirSync(outputDir, { recursive: true });

    // Japanese voice ID - using Rachel (multilingual)
    const voiceId = '21m00Tcm4TlvDq8ikWAM';

    // Test phrases for Japanese greetings
    const testPhrases = [
        {
            text: 'こんにちは',
            filename: 'konnichiwa.wav',
            expected: 'こんにちは'
        },
        {
            text: 'ありがとうございます',
            filename: 'arigatou.wav',
            expected: 'ありがとうございます'
        },
        {
            text: 'さようなら',
            filename: 'sayounara.wav',
            expected: 'さようなら'
        },
        {
            text: '今日は良い天気ですね',
            filename: 'weather.wav',
            expected: '今日は良い天気ですね'
        },
        {
            text: '図書館で本を読んでいます',
            filename: 'library.wav',
            expected: '図書館で本を読んでいます'
        }
    ];

    let successCount = 0;

    // Generate audio files sequentially
    for (const phrase of testPhrases) {
        const outputPath = path.join(outputDir, phrase.filename);
        try {
            await generateAudioWithElevenLabs(phrase.text, voiceId, apiKey, outputPath);
            successCount++;
        } catch (error) {
            console.error(`Failed to generate audio for '${phrase.text}': ${error.message}`);
        }
    }

    // Create metadata file for tests
    const metadata = {
        test_audio_files: testPhrases.map(phrase => ({
            filename: phrase.filename,
            text: phrase.text,
            expected_transcription: phrase.expected
        })),
        audio_format: 'wav',
        sample_rate: 22050,
        channels: 1,
        voice_model: 'eleven_multilingual_v2'
    };

    const metadataPath = path.join(outputDir, 'test_metadata.json');
    fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2), 'utf8');

    console.log(`\nGenerated ${successCount}/${testPhrases.length} audio files`);
    console.log(`Metadata saved to: ${metadataPath}`);

    process.exit(successCount === testPhrases.length ? 0 : 1);
}

main().catch(error => {
    console.error('Error:', error);
    process.exit(1);
});