//
//  EnhancedXPBar.swift
//  LevelUp Life
//
//  Smooth animated XP bar with particles
//

import SwiftUI

struct EnhancedXPBar: View {
    let current: Int
    let required: Int
    let level: Int
    
    @State private var animatedProgress: Double = 0
    @State private var showParticles = false
    @State private var particleOffset: CGFloat = 0
    
    private var progress: Double {
        min(1.0, Double(current) / Double(required))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Level and XP text
            HStack {
                Text("Level \(level)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("\(current) / \(required) XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                    
                    // Animated fill
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress)
                        .overlay(
                            // Shimmer effect
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.3), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 50)
                                .offset(x: particleOffset)
                        )
                        .mask(RoundedRectangle(cornerRadius: 10))
                    
                    // Glow effect
                    if animatedProgress > 0 {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.5), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * animatedProgress)
                            .blur(radius: 10)
                    }
                }
            }
            .frame(height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .onAppear {
            animateProgress()
        }
        .onChange(of: current) { _ in
            animateProgress()
        }
    }
    
    private func animateProgress() {
        // Animate to new progress
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animatedProgress = progress
        }
        
        // Shimmer effect
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            particleOffset = UIScreen.main.bounds.width
        }
        
        // Haptic feedback if gaining XP
        if animatedProgress > 0 {
            HapticManager.shared.rewardEarned()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        EnhancedXPBar(current: 450, required: 1000, level: 5)
            .padding()
        
        EnhancedXPBar(current: 950, required: 1000, level: 12)
            .padding()
    }
    .background(Color.black)
}




