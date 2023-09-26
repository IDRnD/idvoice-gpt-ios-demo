//
//  ChatManager.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 25.08.2023.
//

import Foundation
import Combine

final class ChatManager {
    // Singleton instance of ChatManager
    static let shared = ChatManager()

    // OpenAI API streamer
    private let openAIStreamer = OpenAIStreamer()
    
    // Set to manage Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // Published property to hold the AI response
    @Published var response = ""

    // Private initializer for the singleton pattern
    private init() {
        // Subscribe to updates from the OpenAIStreamer
        openAIStreamer.$responseMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.response = text
            }
            .store(in: &cancellables)
    }
        
    // Send a chat with streaming to OpenAI
    func sendChatWithStreaming(_ chat: [ChatMessage]) async {
        // Reset the response
        self.response = ""
        // Send the chat to OpenAI using streaming
        try? await openAIStreamer.sendChat(chat)
    }
    
    // Stop generating an answer using streaming
    func stopGeneratingAnswer() {
        // Store the partial response
        let partialResponse = self.response
        // Cancel the streaming task
        openAIStreamer.cancelStreamingTask()
        DispatchQueue.main.async {
            // Update the response with a partial message
            self.response = "\(partialResponse)..."
        }
    }
}
