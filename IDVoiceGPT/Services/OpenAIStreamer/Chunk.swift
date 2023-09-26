//
//  Chunk.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 18.09.2023.
//

import Foundation

// Structure to represent a chunk of data from the response stream
struct Chunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let role: String?
            let content: String?
        }
        
        let delta: Delta
    }
    let choices: [Choice]
}
