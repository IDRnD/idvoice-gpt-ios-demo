//
//  HistoryView.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 25.08.2023.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    let talkLogs: [Conversation.Dialog]
    var headerText: String = "dialog-string"

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Spacer()
                    Text(headerText)
                        .font(.body).bold()
                        .foregroundColor(Color(.label))
                    Spacer()

                    
                }
                ScrollView {
                    ForEach(talkLogs) { log in
                        HStack {
                            Spacer()
                            Text(String(localized: String.LocalizationValue(log.question), bundle: userSettings.bundle))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.cornerRadius(15))
                                .padding(.vertical, 4)
                            Image(systemName: "person.circle")
                                .font(.system(size: 30))
                                .foregroundColor(.purple)
                        }
                        HStack {
                            Image("chatgptlogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.green)
                            Text(String(localized: String.LocalizationValue(log.answer), bundle: userSettings.bundle))
                                .foregroundColor(Color(.label))
                                .font(.monospaced(.callout)())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(colorScheme == .dark ? Color.white : Color.gray, lineWidth: 2)
                                        .background(Color.clear))
                                .padding(.vertical, 4)
                            Spacer()
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static let userSettings = UserSettings()
    static let talkLogs: [Conversation.Dialog] = [
        Conversation.Dialog(question: "My first question.", answer: "AI's answer."),
        Conversation.Dialog(question: "My 2nd question.", answer: "AI's answer.")
    ]
    static var previews: some View {
        HistoryView(talkLogs: talkLogs)
            .environmentObject(userSettings)
    }
}
