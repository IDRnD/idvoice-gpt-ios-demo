//
//  Conversation.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 25.08.2023.
//

import Foundation
import Combine

@MainActor
final class Conversation: ObservableObject {
    // Possible states of the conversation
    enum State { case idle, listening, asking }
    
    // Represents a dialog with a unique identifier
    struct Dialog: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }
    
    // Initial prompt and answer strings
    let initPrompt = "listening-string"
    let initAnswer = "thinking-string"
    
    // Published properties to trigger UI updates
    @Published var prompt = ""
    @Published var question = ""
    @Published var answer = ""
    @Published var talkLogs = [Dialog]()
    @Published var chat = [ChatMessage]()
    @Published var state: State = .idle
    
    // Index and list for not-live voice prompts
    private var currentnotLivePhraseIndex = 0
    private let notLivePhrases = [
        "not-live-voice-prompt-1",
        "not-live-voice-prompt-2",
        "not-live-voice-prompt-3"
    ]
    
    // Index and list for unmatched voice prompts
    private var currentnotMatchedPhraseIndex = 0
    private let notMatchedPhrases = [
        "unmatched-voice-prompt-1",
        "unmatched-voice-prompt-2",
        "unmatched-voice-prompt-3",
        "unmatched-voice-prompt-4",
        "unmatched-voice-prompt-5",
        "unmatched-voice-prompt-6",
    ]
    
    // Set of Combine cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Initialize the Conversation class
    init() {
        initSubscriptions()
    }
    
    // Set up subscriptions to ChatManager responses
    private func initSubscriptions() {
        ChatManager.shared.$response
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.answer = text
            }
            .store(in: &cancellables)
    }
    
    // Start listening for user input
    func startListening() {
        Synthesizer.shared.stopSpeaking()
        state = .listening
        prompt = initPrompt
        SpeechProcessor.shared.startRecording(progressHandler: { text in
            self.prompt = text
        })
    }
    
    // Stop listening for user input
    func stopListening() {
        state = .idle
        SpeechProcessor.shared.stopRecording()
    }
    
    // Stop generating an answer
    func stopGeneratingAnswer() {
        ChatManager.shared.stopGeneratingAnswer()
    }
    
    // Ask a question based on the user's input
    func ask() async {
        guard prompt != initPrompt else { return }
        state = .asking
        question = prompt
        
        answer = initAnswer
        prompt = initPrompt
        
        let userQuestion = ChatMessage(role: .user, content: question)
        
        do {
            try SpeechProcessor.shared.processVoiceRecording()
            
            chat.append(userQuestion)
            await ChatManager.shared.sendChatWithStreaming(chat)
            
            let assistantAnswer = ChatMessage(role: .assistant, content: answer)
            chat.append(assistantAnswer)
            
        } catch let error as IDVoiceError {
            // Display not-live and unmatched messages
            switch error {
            case .invalidData:
                answer = "⚠️ Invalid audio data."
            case .notLive:
                answer = notLivePhrases[currentnotLivePhraseIndex]
                currentnotLivePhraseIndex = (currentnotLivePhraseIndex + 1) % notLivePhrases.count
            case .notMatching:
                answer = notMatchedPhrases[currentnotMatchedPhraseIndex]
                currentnotMatchedPhraseIndex = (currentnotMatchedPhraseIndex + 1) % notMatchedPhrases.count
            }
        } catch {
            answer = "⚠️ VoiceSDK error: \(error.localizedDescription)"
        }
        
        talkLogs.append(Dialog(question: question, answer: answer))
        state = .idle
    }
    
    // Speak the generated answer
    func speak() {
        guard answer != initAnswer else { return }
        
        if Synthesizer.shared.isSpeaking {
            Synthesizer.shared.stopSpeaking()
        } else {
            Synthesizer.shared.speak(answer)
        }
    }
    
    // Reset the conversation state
    func reset() {
        prompt = ""
        question = ""
        answer = ""
        talkLogs = [Dialog]()
        chat = [ChatMessage]()
        state = .idle
    }
}

