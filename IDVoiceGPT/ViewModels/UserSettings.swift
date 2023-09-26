//
//  SettingsViewModel.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 25.08.2023.
//

import Foundation

enum LanguageCode: String, CaseIterable {
    case enUS = "en-US"
    case esES = "es-ES"
    case ptPT = "pt-PT"
    case koKR = "ko-KR"
    case zhCN = "zh-CN"
    
    var description: String {
        switch self {
        case .enUS: return "English"
        case .esES: return "Español"
        case .ptPT: return "Português"
        case .koKR: return "한국어 (Korean)"
        case .zhCN: return "简体中文 (Simplified Chinese)"
        }
    }
    
    var resourceName: String {
        switch self {
        case .enUS: return "en"
        case .esES: return "es"
        case .ptPT: return "pt-PT"
        default: return "en"
        }
    }
}

enum UserDefaultsKeys {
    static let hapticFeedback = "hapticFeedback"
    static let selectedLanguageIndex = "selectedLanguageIndex"
    static let languageLocaleCode = "languageLocaleCode"
    static let isLivenessEnabled = "isLivenessEnabled"
    static let apiKey = "apiKey"
}

class UserSettings: ObservableObject {
    let languages = LanguageCode.allCases
    
    // Published properties for SwiftUI updates
    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: UserDefaultsKeys.hapticFeedback)
        }
    }
    
    @Published var selectedLanguageIndex: Int {
        didSet {
            UserDefaults.standard.set(selectedLanguageIndex, forKey: UserDefaultsKeys.selectedLanguageIndex)
            UserDefaults.standard.set(languages[selectedLanguageIndex].rawValue, forKey: UserDefaultsKeys.languageLocaleCode)
        }
    }
    
    @Published var isLivenessEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLivenessEnabled, forKey: UserDefaultsKeys.isLivenessEnabled)
        }
    }
    
    @Published var apiKey: String = "" {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: UserDefaultsKeys.apiKey)
        }
    }
    
    var bundle: Bundle? {
        let resourceName = languages[selectedLanguageIndex].resourceName
        if let path = Bundle.main.path(forResource: resourceName, ofType: "lproj") {
            return Bundle(path: path)
        } else {
            return Bundle.main
        }
    }
        
    func deleteApiKey() {
        apiKey = ""
    }
    
    private func setSystemPrefferedSpeechRecognitionLanguage() {
        guard let prefferedLanguage = Locale.preferredLanguages.first else { return }
        guard let prefix = prefferedLanguage.split(separator: "-").first else { return }
        
        if let matchingCase = LanguageCode.allCases.first(where: { $0.rawValue.hasPrefix(prefix) }) {
            if let index = LanguageCode.allCases.firstIndex(of: matchingCase) {
                selectedLanguageIndex = index
            }
        }
    }
        
    private func getOrSetAPIKey() -> String {
        // Attempt to retrieve the API key from UserDefaults
        if let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKeys.apiKey) {
            return apiKey
        }
        
        // API key doesn't exist, set a default value and save it in UserDefaults
        let defaultApiKey = OpenAIAPIKey.key
        UserDefaults.standard.set(defaultApiKey, forKey: UserDefaultsKeys.apiKey)
        return defaultApiKey
    }
    
    init() {
        hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hapticFeedback)
        selectedLanguageIndex = UserDefaults.standard.integer(forKey: UserDefaultsKeys.selectedLanguageIndex)
        isLivenessEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isLivenessEnabled)
        apiKey = getOrSetAPIKey()
        
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.languageLocaleCode) == nil {
            // Set speech recognition language based on preffered system language
            setSystemPrefferedSpeechRecognitionLanguage()
        }
    }
}
