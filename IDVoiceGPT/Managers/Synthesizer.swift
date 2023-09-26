//
//  Synthesizer.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 25.08.2023.
//

import AVFoundation

// A class responsible for text-to-speech synthesis using AVFoundation.
final class Synthesizer {
    // Singleton instance of the synthesizer.
    static let shared = Synthesizer()
    private let synthesizer = AVSpeechSynthesizer()
    
    // The voice used for speech synthesis (English - United States).
    private let voice = AVSpeechSynthesisVoice(language: "en-US") // BCP47 language code
    
    private init() {}

    // Check if the synthesizer is currently speaking.
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    // Start speaking the given text.
    func speak(_ text: String) {
        guard !synthesizer.isSpeaking && !synthesizer.isPaused else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice

        // Set the audio session category to playback to allow mixing with other audio.
        let avSession = AVAudioSession.sharedInstance()
        try? avSession.setCategory(AVAudioSession.Category.playback, options: .mixWithOthers)

        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }
}
