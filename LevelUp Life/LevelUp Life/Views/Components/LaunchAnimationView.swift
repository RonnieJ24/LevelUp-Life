//
//  LaunchAnimationView.swift
//  LevelUp Life
//
//  App launch animation
//

import SwiftUI

struct LaunchAnimationView: View {
    @Binding var isShowingLaunch: Bool
    
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var rotationDegrees: Double = -180
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.black, .purple.opacity(0.3), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo icon
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                    
                    // Icon
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .purple, radius: 20)
                }
                .scaleEffect(logoScale)
                .rotationEffect(.degrees(rotationDegrees))
                .opacity(logoOpacity)
                
                // App name
                Text("LevelUp Life")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(textOpacity)
                
                // Tagline
                Text("Turn Your Life Into an RPG")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            animateLaunch()
        }
    }
    
    private func animateLaunch() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
            rotationDegrees = 0
        }
        
        // Text fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                logoOpacity = 0
                textOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isShowingLaunch = false
            }
        }
    }
}

#Preview {
    LaunchAnimationView(isShowingLaunch: .constant(true))
}




