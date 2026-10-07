import Foundation
import AVFoundation
import Speech

@MainActor
final class VoiceRecorder: NSObject, ObservableObject {
    
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var errorMessage = ""
    
    private var audioEngine: AVAudioEngine?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // MARK: - Start Recording
    
    func startRecording() {
        
        errorMessage = ""
        recognizedText = ""
        
        // 1. Microphone permission
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            
            Task { @MainActor in
                
                guard granted else {
                    self?.errorMessage = "Microphone permission was denied."
                    return
                }
                
                // 2. Speech Recognition permission
                SFSpeechRecognizer.requestAuthorization { status in
                    
                    Task { @MainActor in
                        
                        guard status == .authorized else {
                            self?.errorMessage = "Speech recognition permission was denied."
                            return
                        }
                        
                        self?.beginRecording()
                    }
                }
            }
        }
    }
    
    // MARK: - Begin Recording
    
    private func beginRecording() {
        
        stopRecording()
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            try audioSession.setCategory(
                .record,
                mode: .measurement,
                options: .duckOthers
            )
            
            try audioSession.setActive(
                true,
                options: .notifyOthersOnDeactivation
            )
            
            guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
                errorMessage = "Speech recognizer is not available on this device."
                return
            }
            
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.recognitionRequest = request
            
            let engine = AVAudioEngine()
            self.audioEngine = engine
            
            let inputNode = engine.inputNode
            inputNode.removeTap(onBus: 0)
            
            let recordingFormat = inputNode.inputFormat(forBus: 0)
            
            // Prevent crash on Simulator if microphone input is not connected
            guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
                errorMessage = "Microphone is unavailable or sample rate is 0. Please test on a real device or grant Mac mic permissions to Simulator."
                stopRecording()
                return
            }
            
            self.recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let result = result {
                        self?.recognizedText = result.bestTranscription.formattedString
                    }
                    if let error = error {
                        print("Speech recognition error:", error)
                    }
                }
            }
            
            inputNode.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: recordingFormat
            ) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            engine.prepare()
            try engine.start()
            
            isRecording = true
            
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            stopRecording()
        }
    }
    
    // MARK: - Stop Recording
    
    func stopRecording() {
        
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}
