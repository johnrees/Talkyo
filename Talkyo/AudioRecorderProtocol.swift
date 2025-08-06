//
//  AudioRecorderProtocol.swift
//  Talkyo
//
//  Testing protocol for AudioRecorder
//

import AVFoundation

protocol AudioRecorderProtocol: ObservableObject {
    var isRecording: Bool { get }
    var hasRecording: Bool { get }
    var recordedFileURL: URL? { get }
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)? { get set }
    
    func startRecording()
    func stopRecording() -> [Float]
    func cancelRecording()
    func playRecording()
}

extension AudioRecorder: AudioRecorderProtocol {}