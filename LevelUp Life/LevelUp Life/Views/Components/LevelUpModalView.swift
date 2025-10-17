//
//  LevelUpModalView.swift
//  LevelUp Life
//
//  Epic level-up celebration modal
//

import SwiftUI

struct LevelUpModalView: View {
    let newLevel: Int
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -15
    @State private var opacity: Double = 0
    @State private var showConfetti = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Level badge
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.5 : 1.0)
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                        .overlay(
                            Circle()
                                .stroke(Color.yellow, lineWidth: 4)
                        )
                        .shadow(color: .purple.opacity(0.7), radius: 30)
                    
                    VStack(spacing: 4) {
                        Text("\(newLevel)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("LEVEL")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                
                // Text
                VStack(spacing: 12) {
                    Text("🎉 LEVEL UP! 🎉")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    Text("You've reached Level \(newLevel)!")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Keep crushing your quests!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(opacity)
                
                Spacer()
                
                // Continue button
                Button(action: dismissWithAnimation) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: .purple.opacity(0.5), radius: 10)
                }
                .opacity(opacity)
                
                Spacer()
            }
            .padding()
            
            // Confetti
            if showConfetti {
                ConfettiOverlayView()
            }
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        // Sound and haptic
        SoundManager.shared.play(.levelUp)
        HapticManager.shared.levelUp()
        
        // Show confetti immediately
        showConfetti = true
        
        // Animate badge
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            scale = 1.0
            rotation = 0
        }
        
        // Fade in text
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            opacity = 1.0
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    private func dismissWithAnimation() {
        HapticManager.shared.buttonTap()
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.8
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

struct ConfettiOverlayView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var color: Color
        var rotation: Double
        var size: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    Circle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .position(x: piece.x, y: piece.y)
                        .rotationEffect(.degrees(piece.rotation))
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue, .green, .red]
        
        for _ in 0..<100 {
            let piece = ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -100...size.height),
                color: colors.randomElement() ?? .yellow,
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 6...12)
            )
            confettiPieces.append(piece)
        }
        
        // Animate falling
        withAnimation(.linear(duration: 3)) {
            for index in confettiPieces.indices {
                confettiPieces[index].x += CGFloat.random(in: -50...50)
                confettiPieces[index].y = size.height + 100
                confettiPieces[index].rotation += 720
            }
        }
    }
}

#Preview {
    LevelUpModalView(newLevel: 5) {}
}

