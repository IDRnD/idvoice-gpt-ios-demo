//
//  IDVoiceGPTApp.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 25.08.2023.
//

import SwiftUI

@main
struct IDVoiceGPTApp: App {
    @StateObject private var userSettings = UserSettings()
    
    init() {
        // Register default values for UserDefaults
        UserDefaults.standard.register(defaults: [
            UserDefaultsKeys.hapticFeedback: true,
            UserDefaultsKeys.isLivenessEnabled: false,
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
        }
    }
}
