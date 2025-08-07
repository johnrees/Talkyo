import AVFoundation
import UIKit
import Observation

@Observable
final class AudioRecorder: NSObject {
    private(set) var isRecording = false
    private(set) var hasRecording = false
    private(set) var recordedFileURL: URL?
    private var audioEngine: AVAudioEngine?
    private var audioConverter: AVAudioConverter?
    private var audioPlayer: AVAudioPlayer?
    private var audioBuffer: [Float] = []
    
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    
    private let impactFeedback = UIImpactFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private enum Config {
        static let sampleRate: Double = 16000
        static let bufferSize: AVAudioFrameCount = 2048
    }
    override init() {
        super.init()
        configureAudioSession()
        setupAudioEngine()
        impactFeedback.prepare()
        notificationFeedback.prepare()
    }
    func startRecording() {
        guard !isRecording else { return }
        
        prepareForRecording()
        impactFeedback.impactOccurred(intensity: 0.5)
        
        guard let engine = audioEngine else { return }
        beginRecording(with: engine)
    }
    func stopRecording() -> [Float] {
        guard isRecording else { return [] }
        
        completeRecording()
        notificationFeedback.notificationOccurred(.success)
        
        if !audioBuffer.isEmpty {
            saveRecording()
            hasRecording = true
        }
        
        return audioBuffer
    }
    func playRecording() {
        guard let url = recordedFileURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let session = AVAudioSession.sharedInstance()
            // Pause other audio during playback
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Playback failed: \(error)")
        }
    }
    func cancelRecording() {
        guard isRecording else { return }
        
        completeRecording()
        notificationFeedback.notificationOccurred(.warning)
        
        audioBuffer.removeAll()
        recordedFileURL = nil
        hasRecording = false
    }
    private func configureAudioSession() {
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else { return }
        }
    }
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
    }
    private func prepareForRecording() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        audioBuffer.removeAll()
        
        if let engine = audioEngine, engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            engine.reset()
        }
        
        audioEngine = AVAudioEngine()
    }
    private func beginRecording(with engine: AVAudioEngine) {
        do {
            let session = AVAudioSession.sharedInstance()
            // Set category without duckOthers to pause other audio
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to activate audio session: \(error)")
            return
        }
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        guard let recordingFormat = createRecordingFormat(),
              let converter = createAudioConverter(from: inputFormat, to: recordingFormat) else {
            return
        }
        
        audioConverter = converter
        
        inputNode.installTap(onBus: 0, bufferSize: Config.bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
            self?.onAudioBuffer?(buffer)
        }
        
        do {
            engine.prepare()
            try engine.start()
            isRecording = true
        } catch {
            print("Failed to start recording: \(error)")
            inputNode.removeTap(onBus: 0)
        }
    }
    private func completeRecording() {
        guard let engine = audioEngine else { return }
        
        isRecording = false
        
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioConverter = nil
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let converter = audioConverter,
              let convertedBuffer = createConvertedBuffer(for: buffer) else { return }
        
        var error: NSError?
        let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        guard error == nil, status != .error,
              let channelData = convertedBuffer.floatChannelData else { return }
        
        let samples = Array(UnsafeBufferPointer(
            start: channelData[0],
            count: Int(convertedBuffer.frameLength)
        ))
        
        audioBuffer.append(contentsOf: samples)
    }
    private func saveRecording() {
        guard let format = createRecordingFormat(),
              let buffer = createAudioBuffer(format: format, samples: audioBuffer) else {
            return
        }
        
        let url = generateRecordingURL()
        
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
            recordedFileURL = url
        } catch {
            print("Failed to save recording: \(error)")
        }
    }
    private func createRecordingFormat() -> AVAudioFormat? {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Config.sampleRate,
            channels: 1,
            interleaved: false
        )
    }
    private func createAudioConverter(from inputFormat: AVAudioFormat, to outputFormat: AVAudioFormat) -> AVAudioConverter? {
        AVAudioConverter(from: inputFormat, to: outputFormat)
    }
    private func createConvertedBuffer(for sourceBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = createRecordingFormat() else { return nil }
        
        let frameCapacity = AVAudioFrameCount(
            Double(sourceBuffer.frameLength) * Config.sampleRate / sourceBuffer.format.sampleRate
        )
        
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity)
    }
    private func createAudioBuffer(format: AVAudioFormat, samples: [Float]) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(samples.count)
        ) else { return nil }
        
        buffer.frameLength = buffer.frameCapacity
        
        if let channelData = buffer.floatChannelData {
            channelData[0].update(from: samples, count: samples.count)
        }
        
        return buffer
    }
    private func generateRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("recording.wav")
    }
}

extension AudioRecorder: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session after playback: \(error)")
        }
    }
}