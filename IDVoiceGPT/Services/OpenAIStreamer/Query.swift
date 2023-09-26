//
//  Query.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 18.09.2023.
//

import Foundation

// Structure to represent a query for chat messages
struct Query: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }
    
    let model = "gpt-3.5-turbo"
    var messages: [Message]
    let stream = true
}
