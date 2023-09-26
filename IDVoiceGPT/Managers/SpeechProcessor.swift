//
//  SpeechProcessor.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 25.08.2023.
//

import Speech
import VoiceSdk

// Custom error enum for voice processing
enum IDVoiceError: Error {
    case invalidData // Error for invalid voice data
    case notLive // Error for voice not being live
    case notMatching // Error for voice templates not matching
}

final class SpeechProcessor: NSObject {
    static let shared = SpeechProcessor()
    private(set) var isEnable = false
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var sampleRate: Int = 0
    private var recordedData: Data?
    
    // VoiceSDK properties
    private var voiceTemplateFactory: VoiceTemplateFactory?
    private var voiceTemplateMatcher: VoiceTemplateMatcher?
    private var livenessEngine: LivenessEngine?
    private var enrolledVoiceTemplate: VoiceTemplate?
    
    private var error: Error?
    
    private override init() {
        super.init()
        setVoiceSDKLicense()
        initVoiceSDKEngines()
    }
    
    private func setVoiceSDKLicense() {
        do {
            _ = try VoiceSDKLicenseManager().setLicense()
        } catch {
            self.error = error
        }
    }
    
    private func initVoiceSDKEngines() {
        do {
            // Initialize voice processing engines
            if let path = Bundle.main.resourcePath {
                voiceTemplateFactory = try VoiceTemplateFactory(path: path + "/verify/mic-v1/")
                voiceTemplateMatcher = try VoiceTemplateMatcher(path: path + "/verify/mic-v1/")
                livenessEngine = try LivenessEngine(path: path + "/liveness/")
            }
        } catch {
            self.error = error
        }
    }
    
    // Request authorization to use speech recognition
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                switch status {
                case .authorized: self.isEnable = true
                case .denied, .restricted, .notDetermined: self.isEnable = false
                default: self.isEnable = false
                }
            }
        }
    }
    
    // Start recording voice with a progress handler
    func startRecording(progressHandler: @escaping (String) -> Void = {_ in }) {
        if audioEngine.isRunning { return }
        // Reset recorded data
        recordedData = Data()
        try? record(progressHandler: progressHandler)
    }
    
    // Process the recorded voice data
    func processVoiceRecording() throws {
        // Stop recording
        stopRecording()
        
        // Check for engine initialization error
        if let error = self.error { throw error }
        
        // Make sure that data is present
        guard let data = recordedData else { throw IDVoiceError.invalidData }
        
        do {
            // Create voice template
            let voiceTemplate = try voiceTemplateFactory?.createVoiceTemplate(data, sampleRate: sampleRate)
            
            // Check if it's the initial recording
            if enrolledVoiceTemplate == nil {
                // Check if the recording is live
                try checkVoiceLiveness(data: data, sampleRate: sampleRate)
                // Save it as an enrollment template
                enrolledVoiceTemplate = voiceTemplate
            } else {
                // For every next recording, check liveness and match against enrollment template
                try checkVoiceLiveness(data: data, sampleRate: sampleRate)
                try matchVoiceTemplates(enrolledVoiceTemplate!, voiceTemplate!)
            }
        } catch {
            throw error
        }
    }
    
    // Stop recording voice
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
    }
    
    // Check voice liveness using the liveness engine
    private func checkVoiceLiveness(data: Data, sampleRate: Int) throws {
        let livenessThreshold: Float = 0.5
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.isLivenessEnabled) {
            do {
                let probability = try livenessEngine?.checkLiveness(data, sampleRate: sampleRate).getValue().probability ?? 0
                if probability < livenessThreshold {
                    throw IDVoiceError.notLive
                }
            } catch {
                throw error
            }
        }
    }
    
    // Match two voice templates
    private func matchVoiceTemplates(_ template1: VoiceTemplate, _ template2: VoiceTemplate) throws {
        let matchingThreshold: Float = 0.5
        do {
            if let probability = try voiceTemplateMatcher?.matchVoiceTemplates(template1, template2: template2).probability {
                if probability < matchingThreshold {
                    throw IDVoiceError.notMatching
                }
            }
        } catch {
            throw error
        }
        return
    }
    
    // Reset the voice processing state
    func reset() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        enrolledVoiceTemplate = nil
    }
    
    // Record voice data
    private func record(progressHandler: @escaping (String) -> Void) throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord,
                                     mode: .default,
                                     options: .mixWithOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest") }
        recognitionRequest.shouldReportPartialResults = true
        
        let localeIdentifier = UserDefaults.standard.string(forKey: UserDefaultsKeys.languageLocaleCode) ?? "en-US"
        
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) else { fatalError("Unable to create a SFSpeechRecognizer")  }
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result {
                progressHandler(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Configure the microphone input.
        sampleRate = Int(inputNode.inputFormat(forBus: 0).sampleRate)
        
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                            sampleRate: Double(sampleRate),
                                            channels: 1,
                                            interleaved: false)!
        
        let bufferClosure: AVAudioNodeTapBlock = { buffer, time in
            // Retrieve audio buffer and append it to saved data
            let channels = UnsafeBufferPointer(start: buffer.int16ChannelData, count: 1)
            let bufferData = NSData(
                bytes: channels[0],
                length: Int(buffer.frameCapacity * buffer.format.streamDescription.pointee.mBytesPerFrame)) as Data
            self.recordedData?.append(bufferData)
            self.recognitionRequest?.append(buffer)
        }
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat, block: bufferClosure)
        
        audioEngine.prepare()
        try audioEngine.start()
    }
}

extension SpeechProcessor: SFSpeechRecognizerDelegate {
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        isEnable = available
    }
}
