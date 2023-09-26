//
//  SettingsView.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 25.08.2023.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: UserSettings
    @State private var isShowingDeleteAlert = false
   
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("app-string", bundle: settings.bundle)) {
                    HStack {
                        Image(systemName: "water.waves")
                        Toggle(String(localized: "haptic-string", bundle: settings.bundle), isOn: $settings.hapticFeedbackEnabled)
                    }
                }
                
                Section(header: Text("speech-string", bundle: settings.bundle)) {
                    HStack {
                        Image(systemName: "waveform")
                        Picker(String(localized: "language-string", bundle: settings.bundle), selection: $settings.selectedLanguageIndex) {
                            ForEach(0..<settings.languages.count, id: \.self) { index in
                                Text(settings.languages.map { $0.description }[index]).tag(index)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                        Toggle(String(localized: "check-liveness-string", bundle: settings.bundle), isOn: $settings.isLivenessEnabled)
                        
                    }
                }
                Section(header: Text("api-key-string", bundle: settings.bundle)) {
                    HStack {
                        Image(systemName: "key")
                        SecureField(String(localized: "enter-api-string", bundle: settings.bundle), text: $settings.apiKey)
                            .foregroundColor(Color(.secondaryLabel))
                            .textContentType(.none)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        if !settings.apiKey.isEmpty {
                            Button(action: {
                                isShowingDeleteAlert = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(String(localized: "settings-string", bundle: settings.bundle))
            .alert(isPresented: $isShowingDeleteAlert) {
                Alert(
                    title: Text("delete-api-string", bundle: settings.bundle),
                    message: Text("delete-api-message-string", bundle: settings.bundle),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text("delete-string", bundle: settings.bundle)) {
                        settings.deleteApiKey()
                    }
                )
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: UserSettings())
    }
}
