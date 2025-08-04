//
//  TranscriptionManager.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import Foundation
import AVFoundation
import CoreML
import Accelerate
import CoreText
import Combine
import AVFAudio

class TranscriptionManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var transcribedText: String = ""
    @Published var transcribedTextWithFurigana: NSAttributedString = NSAttributedString()
    @Published var furiganaText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var transcriptionTime: String = ""
    
    private var audioEngine: AVAudioEngine?
    private var audioSession: AVAudioSession?
    private var inputNode: AVAudioInputNode?
    private var audioBuffer: AVAudioPCMBuffer?
    private var audioData: [Float] = []
    private var audioPlayer: AVAudioPlayer?
    private var recordedAudioURL: URL?
    
    private let sampleRate: Double = 16000
    private let bufferSize: AVAudioFrameCount = 2048  // Optimized for 3-10s recordings
    private var audioConverter: AVAudioConverter?
    private var isRecordingActive = false
    private let whisperModel = WhisperModelHandler()
    @Published var modelStatus: String = "Initializing..."
    @Published var isModelLoaded: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupAudioEngine()
        
        // Bind WhisperModel status to our published properties
        whisperModel.$modelLoadingStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$modelStatus)
        
        whisperModel.$isModelLoaded
            .receive(on: DispatchQueue.main)
            .assign(to: &$isModelLoaded)
    }
    
    func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        // For iOS 17+, use AVAudioApplication
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                if granted {
                    self?.configureAudioSession()
                } else {
                    print("Microphone permission denied")
                }
            }
        } else {
            // Fallback for older iOS versions
            audioSession?.requestRecordPermission { [weak self] granted in
                if granted {
                    self?.configureAudioSession()
                } else {
                    print("Microphone permission denied")
                }
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession?.setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
    }
    
    func startRecording() {
        // Recreate audio engine if needed
        if audioEngine == nil {
            setupAudioEngine()
        }
        
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else {
            print("Failed to initialize audio engine")
            return
        }
        
        // Prevent double recording
        if isRecordingActive {
            print("Recording already in progress")
            return
        }
        
        // Stop any playing audio first
        if audioPlayer?.isPlaying == true {
            stopPlayback()
        }
        
        // Clear previous transcription
        clearTranscription()
        
        audioData.removeAll()
        audioConverter = nil
        
        // Make sure engine is stopped and tap is removed before starting
        if audioEngine.isRunning {
            inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            audioEngine.reset()
        }
        
        // Reconfigure audio session for recording
        configureAudioSession()
        
        // Get the input format (hardware format)
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Create our target format
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: sampleRate,
                                           channels: 1,
                                           interleaved: false)!
        
        // Create converter once, not every buffer
        audioConverter = AVAudioConverter(from: inputFormat, to: recordingFormat)
        
        guard audioConverter != nil else {
            print("Failed to create audio converter")
            return
        }
        
        // Install tap with hardware format to avoid format conversion issues
        do {
            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
                guard let self = self, let converter = self.audioConverter else { return }
            
            // Calculate output frame capacity based on sample rate conversion
            let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * recordingFormat.sampleRate / inputFormat.sampleRate)
            
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat,
                                                         frameCapacity: outputFrameCapacity) else { return }
            
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            
            if error == nil, let channelData = convertedBuffer.floatChannelData {
                let frameLength = Int(convertedBuffer.frameLength)
                let samples = Array(UnsafeBufferPointer(start: channelData.pointee, count: frameLength))
                self.audioData.append(contentsOf: samples)
            }
        }
        } catch {
            print("Failed to install tap: \(error)")
            return
        }
        
        // Start audio engine after installing tap
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecordingActive = true
            print("Audio engine started successfully")
            print("Input format: \(inputFormat)")
            print("Recording format: \(recordingFormat)")
        } catch {
            print("Failed to start audio engine: \(error)")
            inputNode.removeTap(onBus: 0)
            return
        }
        
        print("Recording started")
    }
    
    func stopRecording() {
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else { return }
        
        // Only stop if we're actually recording
        guard isRecordingActive else {
            print("Not currently recording")
            return
        }
        
        isRecordingActive = false
        
        // Remove tap first
        inputNode.removeTap(onBus: 0)
        
        // Stop engine
        audioEngine.stop()
        
        // Reset engine for next recording
        audioEngine.reset()
        
        // Clean up converter
        audioConverter = nil
        
        print("Recording stopped. Total samples: \(audioData.count)")
        print("Recording duration: \(Double(audioData.count) / sampleRate) seconds")
        
        if !audioData.isEmpty {
            saveRecordedAudio()
            transcribeAudio()
        }
    }
    
    private func transcribeAudio() {
        isTranscribing = true
        
        Task {
            let startTime = Date()
            
            // Try to transcribe using the Whisper model
            if let transcription = await whisperModel.transcribe(audioData: audioData) {
                let endTime = Date()
                let transcriptionTimeMs = Int(endTime.timeIntervalSince(startTime) * 1000)
                
                await MainActor.run {
                    self.transcribedText = transcription
                    self.transcribedTextWithFurigana = self.generateFurigana(for: transcription)
                    self.furiganaText = self.generateSimpleFurigana(for: transcription)
                    self.transcriptionTime = "\(transcriptionTimeMs)ms"
                    self.isTranscribing = false
                }
            } else {
                // Fallback message if model is not loaded
                await MainActor.run {
                    self.transcribedText = "Model Status: \(self.modelStatus)\n録音されたオーディオ: \(self.audioData.count) サンプル\nPlease wait for model to download..."
                    self.transcribedTextWithFurigana = NSAttributedString(string: self.transcribedText)
                    self.furiganaText = ""
                    self.isTranscribing = false
                }
            }
        }
    }
    
    private func generateFurigana(for text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Create a tokenizer for Japanese text
        let tokenizer = CFStringTokenizerCreate(nil, text as CFString, CFRangeMake(0, text.count), kCFStringTokenizerUnitWordBoundary, Locale(identifier: "ja_JP") as CFLocale)
        
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        
        while tokenType != [] {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let startIndex = text.index(text.startIndex, offsetBy: range.location)
            let endIndex = text.index(startIndex, offsetBy: range.length)
            let substring = String(text[startIndex..<endIndex])
            
            // Get the Latin transcription (romaji)
            if let latin = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String {
                // Convert romaji to hiragana for furigana
                let furigana = convertToHiragana(latin)
                
                // Create attributed string with furigana
                let rubyAttribute: [NSAttributedString.Key: Any] = [
                    kCTRubyAnnotationAttributeName as NSAttributedString.Key: CTRubyAnnotationCreateWithAttributes(
                        .auto,
                        .auto,
                        .before,
                        furigana as CFString,
                        [kCTRubyAnnotationSizeFactorAttributeName: 0.5] as CFDictionary
                    )
                ]
                
                let part = NSAttributedString(string: substring, attributes: rubyAttribute)
                attributedString.append(part)
            } else {
                // If no transcription available, just add the text
                attributedString.append(NSAttributedString(string: substring))
            }
            
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        
        return attributedString
    }
    
    private func convertToHiragana(_ romaji: String) -> String {
        // Use the built-in transliterator to convert Latin to Hiragana
        let mutableString = NSMutableString(string: romaji)
        CFStringTransform(mutableString, nil, kCFStringTransformLatinHiragana, false)
        return mutableString as String
    }
    
    private func generateSimpleFurigana(for text: String) -> String {
        // Only show furigana if the text contains kanji or katakana
        var hasKanjiOrKatakana = false
        for char in text {
            if isKanji(char) || isKatakana(char) {
                hasKanjiOrKatakana = true
                break
            }
        }
        
        // If no kanji or katakana, don't show furigana
        if !hasKanjiOrKatakana {
            return ""
        }
        
        // Convert the entire text to hiragana for reading
        let mutableString = NSMutableString(string: text)
        
        // For katakana, we can directly convert to hiragana
        CFStringTransform(mutableString, nil, kCFStringTransformHiraganaKatakana, true)
        
        // For kanji, use Japanese tokenizer for proper readings
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            text as CFString,
            CFRangeMake(0, text.count),
            kCFStringTokenizerUnitWord,
            Locale(identifier: "ja_JP") as CFLocale
        )
        
        var furiganaResult = ""
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        
        while tokenType != [] {
            if let latin = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String {
                // Convert Latin (romaji) to hiragana
                let hiragana = NSMutableString(string: latin)
                CFStringTransform(hiragana, nil, kCFStringTransformLatinHiragana, false)
                furiganaResult += hiragana as String
            }
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        
        // If we got a result from tokenizer, use it
        let tempString = furiganaResult.isEmpty ? mutableString : NSMutableString(string: furiganaResult)
        
        // If the result is the same as input (all hiragana), don't show furigana
        let result = tempString as String
        if result == text {
            return ""
        }
        
        return result
    }
    
    private func isKanji(_ char: Character) -> Bool {
        let scalar = char.unicodeScalars.first!
        return (0x4E00...0x9FFF).contains(Int(scalar.value))
    }
    
    private func isKatakana(_ char: Character) -> Bool {
        let scalar = char.unicodeScalars.first!
        return (0x30A0...0x30FF).contains(Int(scalar.value))
    }
    
    private func clearTranscription() {
        transcribedText = ""
        transcribedTextWithFurigana = NSAttributedString()
        furiganaText = ""
        transcriptionTime = ""
    }
    
    private func saveRecordedAudio() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordedAudioURL = documentsPath.appendingPathComponent("lastRecording.wav")
        
        guard let recordedAudioURL = recordedAudioURL else { return }
        
        print("Saving \(audioData.count) samples to: \(recordedAudioURL.path)")
        
        // Delete existing file if present
        try? FileManager.default.removeItem(at: recordedAudioURL)
        
        // Create WAV file from float samples
        let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                       sampleRate: sampleRate,
                                       channels: 1,
                                       interleaved: false)!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat,
                                           frameCapacity: AVAudioFrameCount(audioData.count)) else {
            print("Failed to create audio buffer")
            return
        }
        
        buffer.frameLength = buffer.frameCapacity
        
        if let channelData = buffer.floatChannelData {
            channelData[0].update(from: audioData, count: audioData.count)
        }
        
        do {
            let file = try AVAudioFile(forWriting: recordedAudioURL,
                                     settings: audioFormat.settings)
            try file.write(from: buffer)
            
            // Verify file was written
            let attributes = try FileManager.default.attributesOfItem(atPath: recordedAudioURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("Audio saved successfully. File size: \(fileSize) bytes")
            print("Duration: \(Double(audioData.count) / sampleRate) seconds")
        } catch {
            print("Failed to save audio: \(error)")
        }
    }
    
    func playRecordedAudio() {
        guard let recordedAudioURL = recordedAudioURL,
              FileManager.default.fileExists(atPath: recordedAudioURL.path) else {
            print("No recorded audio to play")
            return
        }
        
        do {
            // Configure audio session for playback but keep it compatible with recording
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            // Get file info for debugging
            let attributes = try FileManager.default.attributesOfItem(atPath: recordedAudioURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("Playing audio file: \(recordedAudioURL.path)")
            print("File size: \(fileSize) bytes")
            
            audioPlayer = try AVAudioPlayer(contentsOf: recordedAudioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 1.0
            
            let success = audioPlayer?.play() ?? false
            print("Play started: \(success), duration: \(audioPlayer?.duration ?? 0) seconds")
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Audio playback finished")
        audioPlayer = nil
        
        // Ensure audio session is ready for recording again
        configureAudioSession()
    }
}