//
//  RewardAnimationView.swift
//  LevelUp Life
//
//  Animated reward display overlay
//

import SwiftUI

struct RewardAnimationView: View {
    let rewards: [Reward]
    let onDismiss: () -> Void
    
    @State private var showRewards = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAnimation()
                }
            
            VStack(spacing: 30) {
                if showRewards {
                    Text("Quest Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 16) {
                        ForEach(rewards) { reward in
                            RewardRow(reward: reward)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(30)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    
                    Button(action: dismissAnimation) {
                        Text("Collect All")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showRewards = true
                }
            }
        }
    }
    
    private func dismissAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.8
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

struct RewardRow: View {
    let reward: Reward
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(rewardColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: rewardIcon)
                    .font(.title2)
                    .foregroundColor(rewardColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if reward.rarity != .common {
                    Text(reward.rarity.rawValue)
                        .font(.caption)
                        .foregroundColor(rarityColor)
                }
            }
            
            Spacer()
            
            Text("+\(reward.amount)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(rewardColor)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var rewardIcon: String {
        switch reward.type {
        case .xp: return "star.fill"
        case .gold: return "dollarsign.circle.fill"
        case .gems: return "diamond.fill"
        case .tickets: return "ticket.fill"
        case .item: return "gift.fill"
        }
    }
    
    private var rewardColor: Color {
        switch reward.type {
        case .xp: return .purple
        case .gold: return .yellow
        case .gems: return .cyan
        case .tickets: return .orange
        case .item: return .pink
        }
    }
    
    private var rarityColor: Color {
        switch reward.rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .mythic: return .orange
        }
    }
}

#Preview {
    RewardAnimationView(rewards: [
        Reward(type: .xp, amount: 50, source: "Test"),
        Reward(type: .gold, amount: 20, source: "Test"),
        Reward(type: .gems, amount: 5, rarity: .rare, source: "Test")
    ]) {}
}

