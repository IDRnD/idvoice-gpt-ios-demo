//
//  UserPermissionsManager.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 30.08.2023.
//

import Speech

class PermissionManager: ObservableObject {
    // Published property to track speech recognition authorization status
    @Published var speechRecognitionAuthorized = false

    // Published property to track microphone authorization status
    @Published var microphoneAuthorized = false

    // Function to check and request speech recognition permission
    func checkSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                // Update the speechRecognitionAuthorized property based on the authorization status
                self.speechRecognitionAuthorized = authStatus == .authorized
            }
        }
    }

    // Function to check and request microphone permission
    func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                // Microphone permission is already granted
                self.microphoneAuthorized = true
            case .denied, .undetermined:
                // Request microphone permission if it's denied or undetermined
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        // Update the microphoneAuthorized property based on the granted status
                        self.microphoneAuthorized = granted
                    }
                }
            default:
                // Default case for handling unexpected permission states
                self.microphoneAuthorized = false
        }
    }
}
