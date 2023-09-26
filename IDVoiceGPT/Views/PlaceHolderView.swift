//
//  PlaceHolderView.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 24.08.2023.
//

import SwiftUI

struct PlaceholderView: View {
    var text: String
    var body: some View {
        ZStack {
            Color(.clear)
            
            VStack {
                Image("idrndlogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180)
                    .foregroundColor(.gray)
                Text(text)
                    .font(.callout)
                    .foregroundColor(Color(.secondaryLabel))
                    .padding()
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .edgesIgnoringSafeArea(.all)
    }
}
