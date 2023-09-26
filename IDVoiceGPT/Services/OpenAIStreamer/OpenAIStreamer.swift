//
//  ChatGPTStreamer.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 25.08.2023.
//

import Foundation

class OpenAIStreamer: ObservableObject {
    // Published property to store the response message
    @Published var responseMessage: String = ""
    
    // Private property to hold the streaming task
    private var stream: URLSession.AsyncBytes?
    
    private var urlString = "https://api.openai.com/v1/chat/completions"
    
    // Method to send chat messages to the OpenAI API
    func sendChat(_ chat: [ChatMessage]) async throws {
        // Clear the response message
        self.responseMessage = ""
        
        // Convert ChatMessage objects to Query.Message objects
        let messages = chat.map { ChatMessage -> Query.Message in
            return Query.Message(role: ChatMessage.role.rawValue, content: ChatMessage.content)
        }
        
        // Create a query with the chat messages
        let query = Query(messages: messages)
        
        let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKeys.apiKey) ?? ""
        
        do {
            // Create an HTTP request
            let request = try makeRequest(content: query, apiKey: apiKey)
            
            // Perform an asynchronous network request and get a response stream
            let (stream, response) = try await URLSession.shared.bytes(for: request)
            
            // Check for HTTP response status code
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if statusCode == 401 {
                    self.responseMessage = "Please provide a valid OpenAI API key."
                    return
                }
            }
            
            // Store the response stream
            self.stream = stream
            
            // Iterate over lines in the stream and parse messages
            for try await line in stream.lines {
                guard let message = parse(line) else { continue }
                responseMessage += message
            }
        } catch {
            // Handle errors and set the response message
            throw error
        }
    }
    
    // Cancel the streaming task
    func cancelStreamingTask() {
        stream?.task.cancel()
    }
    
    // Ccreate an HTTP request
    func makeRequest(content: Query, apiKey: String) throws -> URLRequest {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(content)
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        return request
    }
    
    // Parse a line from the response stream
    func parse(_ line: String) -> String? {
        let components = line.split(separator: ":",
                                    maxSplits: 1,
                                    omittingEmptySubsequences: true)
        
        guard components.count == 2, components[0] == "data" else { return nil }
        let message = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        if message == "[DONE]" {
            return ""
        } else {
            // Attempt to decode a Chunk and retrieve content
            let chunk = try? JSONDecoder().decode(Chunk.self, from: message.data(using: .utf8)!)
            return chunk?.choices.first?.delta.content
        }
    }
}
