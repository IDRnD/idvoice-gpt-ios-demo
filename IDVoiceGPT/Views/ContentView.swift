//
//  ContentView.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 2023/08/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var conversation = Conversation()
    @StateObject private var permissionManager = PermissionManager()
    
    @State private var showPermissionsAlert = false
    @State private var shouldShowChat = false
    @State private var showHistory = false
    @State private var showSettings = false
    
    private var permissionsGranted: Bool {
        permissionManager.microphoneAuthorized
        && permissionManager.speechRecognitionAuthorized
    }
    private var canSpeak: Bool {
        conversation.state == .idle
        && !conversation.answer.isEmpty
    }
    
    private var canStartConversation: Bool {
        conversation.state == .idle
    }
    
    private var canStopConversation: Bool {
        conversation.state == .listening
    }
    
    private var canAsk: Bool {
        conversation.state != .asking
    }
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: { showSettings.toggle() }, label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    })
                    Spacer()
                    Spacer()
                    Text("talk-to-GPT-string", bundle: userSettings.bundle)
                        .font(.monospaced(.callout)().bold())
                        .foregroundColor(Color(.label))
                    Spacer()
                    Button(action: {
                        withAnimation() {
                            resetChat()
                        }
                    }, label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    })
                    .buttonStyle(.plain)
                    .disabled(!canStartConversation || !shouldShowChat)
                    Spacer()
                    Button(action: { showHistory.toggle() }, label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    })
                } // Header view
                
                ZStack {
                    ScrollView(showsIndicators: false) {
                        Spacer()
                        // Human' question
                        HStack {
                            Spacer()
                            if conversation.question.isEmpty {
                                ThreeDotsAnimationView()
                                    .frame(width: 60, height: 40)
                            } else {
                                Text(conversation.question)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue.cornerRadius(15))
                                    .padding(.vertical, 4)
                            }
                            
                            VStack{
                                Image(systemName: "person.circle")
                                    .font(.system(size: 30, weight: .light))
                                    .foregroundColor(.indigo)
                                Spacer()
                            }
                            
                        }
                        
                        // Answer from AI
                        HStack {
                            //Button to speak or to stop speaking
                            Button(action: speak) {
                                VStack {
                                    Image("chatgptlogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 35)
                                    Spacer()
                                }.foregroundColor(canSpeak ? .green : .gray)
                            }
                            .disabled(!canSpeak)
                            
                            if conversation.answer.isEmpty {
                                ThreeDotsAnimationView()
                                    .frame(width: 60, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(colorScheme == .dark ? Color.white : Color.gray, lineWidth: 2)
                                            .background(Color.clear)
                                    )
                                    .padding(.vertical, 4)
                                Spacer()
                            } else {
                                Text(String(localized: String.LocalizationValue(conversation.answer), bundle: userSettings.bundle))
                                    .font(.monospaced(.callout)())
                                    .foregroundColor(Color(.label))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(colorScheme == .dark ? Color.white : Color.gray, lineWidth: 2)
                                            .background(Color.clear)
                                    )
                                    .padding(.vertical, 4)
                                    .onChange(of: conversation.answer) { _ in
                                        DispatchQueue.main.async {
                                            if userSettings.hapticFeedbackEnabled {
                                                hapticFeedback.impactOccurred()
                                            }
                                        }
                                    }
                                Spacer()
                            }
                        }
                    }
                    .onAppear {
                        UIRefreshControl.appearance().attributedTitle = NSAttributedString(string: String(localized: "pull-to-reset-string", bundle: userSettings.bundle))
                    }
                    .refreshable {
                        withAnimation {
                            resetChat()
                        }
                    }
                    
                    if !shouldShowChat {
                        PlaceholderView(text: String(localized: "placeholder-begin-string", bundle: userSettings.bundle))
                    }
                    
                    VStack {
                        Spacer()
                        // Prompt area
                        if conversation.state != .listening {
                            // Button to start a conversation (Voice recognition will start.)
                            Button(action: conversation.state == .asking ? stopGeneratingAnswer : startListening) {
                                HStack {
                                    Image(systemName: conversation.state == .asking ? "stop.circle" : "mic.circle")
                                        .font(.system(size: 50, weight: .light))
                                        .imageScale(.large)
                                        .background(.ultraThinMaterial)
                                        .foregroundStyle(conversation.state == .asking ? .linearGradient(colors: [.gray], startPoint: .topLeading, endPoint: .bottomTrailing) : .linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .clipShape(Circle())
                                }
                            }
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 0)
                            //.disabled(!canStartConversation)
                        } else {
                            HStack {
                                VStack {
                                    Spacer()
                                    // Button to stop the conversation (Voice recognition will stop.)
                                    Button(action: stopListening) {
                                        Image(systemName: "stop.circle")
                                            .font(.system(size: 32))
                                            .frame(width: 50, height: 50)
                                            .background(.ultraThinMaterial)
                                            .foregroundColor(Color.gray)
                                            .clipShape(Circle())
                                    }
                                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 0)
                                    .disabled(!canStopConversation)
                                }
                                
                                VStack {
                                    Spacer()
                                    // A prompt recognized from human's voice
                                    Text(String(localized: String.LocalizationValue(conversation.prompt), bundle: userSettings.bundle))
                                        .foregroundColor(Color(.label))
                                        .padding()
                                        .background(.ultraThinMaterial).cornerRadius(15)
                                        .padding(.horizontal, 8)
                                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 0)
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Spacer()
                                    // Button to ask ChatGPT about the prompt
                                    Button(action: ask) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 32))
                                            .frame(width: 50, height: 50)
                                            .background(.ultraThinMaterial)
                                            .foregroundColor(canAsk ? Color.purple : Color.gray)
                                            .clipShape(Circle())
                                        
                                    }
                                    .buttonStyle(.plain)
                                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 0)
                                    .disabled(!canAsk || conversation.prompt == "listening-string" || conversation.prompt == "")
                                }
                            }
                        }
                        
                    }
                    Spacer()
                }
            }
            .padding()
            .onAppear {
                // Request an authorization for voice recognition
                SpeechProcessor.shared.requestAuthorization()
                permissionManager.checkSpeechRecognitionPermission()
                permissionManager.checkMicrophonePermission()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    SpeechProcessor.shared.requestAuthorization()
                }
            }
            // VStack
        } // ZStack
        .sheet(isPresented: $showHistory) {
            HistoryView(talkLogs: conversation.talkLogs, headerText: String(localized: "dialog-string", bundle: userSettings.bundle))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: userSettings)
        }
        .alert(isPresented: $showPermissionsAlert) {
            Alert(
                title: Text("permissions-needed-string", bundle: userSettings.bundle),
                message: Text("permissions-alert-message-string", bundle: userSettings.bundle),
                primaryButton: .default(Text("settings-string"), action: openSettings),
                secondaryButton: .cancel()
            )
        }
        .preferredColorScheme(.dark)
        .background(Color(.secondarySystemBackground))
    }
    
    // Speak the answer from ChatGPT or stop speaking when speaking
    private func speak() {
        conversation.speak()
    }
    
    // Ask ChatGPT about the prompt(question)
    private func ask() {
        shouldShowChat = true
        Task {
            await conversation.ask()
        }
    }
    
    // Start listening (will start voice recognition)
    private func startListening() {
        if permissionsGranted {
            conversation.startListening()
        } else {
            showPermissionsAlert = true
        }
    }
    
    // Stop listening (will stop voice recognition)
    private func stopListening() {
        conversation.stopListening()
    }
    
    private func stopGeneratingAnswer() {
        conversation.stopGeneratingAnswer()
    }
    
    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }
    
    private func resetChat() {
        guard conversation.state != .asking else { return }
        conversation.reset()
        SpeechProcessor.shared.reset()
        shouldShowChat = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static let userSettings = UserSettings()
    static var previews: some View {
        ContentView()
            .environmentObject(userSettings)
    }
}
