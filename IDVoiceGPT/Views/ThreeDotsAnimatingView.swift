//
//  ThreeDotsAnimatingView.swift
//  IDVoiceGPT
//
//  Created by Renald Shchetinin on 24.08.2023.
//

import SwiftUI

struct ThreeDotsAnimationView: View {
    @State private var dot1Visible = false
    @State private var dot2Visible = false
    @State private var dot3Visible = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(dot1Visible ? .gray : .clear)
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(dot2Visible ? .gray : .clear)
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(dot3Visible ? .gray : .clear)
        }
        .onAppear() {
            animateDots()
        }
    }
    
    private func animateDots() {
        let animationDuration = 0.5
        
        // Animate first dot
        withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
            dot1Visible.toggle()
        }
        
        // Animate second dot with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration / 3) {
            withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                dot2Visible.toggle()
            }
        }
        
        // Animate third dot with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration / 3 * 2) {
            withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                dot3Visible.toggle()
            }
        }
    }
}

