//
//  EnhancedChestOpeningView.swift
//  LevelUp Life
//
//  Premium chest opening with particles and rarity
//

import SwiftUI

struct EnhancedChestOpeningView: View {
    let chest: LootChest
    let onOpen: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isOpening = false
    @State private var showRewards = false
    @State private var chestScale: CGFloat = 1.0
    @State private var showParticles = false
    
    var body: some View {
        ZStack {
            // Dramatic background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            if !showRewards {
                // Chest preview
                VStack(spacing: 40) {
                    Text(chest.type.rawValue.uppercased() + " CHEST")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(rarityColor)
                    
                    ZStack {
                        // Pulsing glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [rarityColor.opacity(0.6), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 240)
                            .scaleEffect(chestScale)
                        
                        // Chest icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 160, height: 160)
                                .shadow(color: rarityColor.opacity(0.7), radius: 30)
                            
                            Image(systemName: "gift.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(chestScale)
                    }
                    
                    if !isOpening {
                        Button(action: openChest) {
                            HStack {
                                Image(systemName: "hand.tap.fill")
                                Text("Open Chest")
                            }
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 220)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: rarityColor.opacity(0.5), radius: 15)
                        }
                    } else {
                        Text("Opening...")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            } else {
                // Rewards reveal
                EnhancedRewardsRevealView(
                    rewards: chest.rewards,
                    rarity: chest.type
                ) {
                    onOpen()
                    dismiss()
                }
            }
            
            // Particle effects
            if showParticles {
                ParticleEffectView(color: rarityColor)
            }
        }
    }
    
    private func openChest() {
        isOpening = true
        showParticles = true
        
        // Play sounds and haptics
        SoundManager.shared.play(.chestOpen)
        HapticManager.shared.chestOpened()
        
        // Animate chest
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).repeatCount(3)) {
            chestScale = 1.1
        }
        
        // Show rewards after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring()) {
                showRewards = true
            }
        }
    }
    
    private var rarityColor: Color {
        switch chest.type {
        case .common, .daily: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .mythic: return .orange
        case .seasonal: return .green
        }
    }
    
    private var gradientColors: [Color] {
        switch chest.type {
        case .common, .daily: return [.gray, .gray.opacity(0.6)]
        case .rare: return [.blue, .cyan]
        case .epic: return [.purple, .pink]
        case .mythic: return [.orange, .yellow]
        case .seasonal: return [.green, .teal]
        }
    }
}

struct EnhancedRewardsRevealView: View {
    let rewards: [Reward]
    let rarity: ChestType
    let onDismiss: () -> Void
    
    @State private var revealedRewards: [Reward] = []
    
    var body: some View {
        VStack(spacing: 30) {
            Text("REWARDS EARNED!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(revealedRewards) { reward in
                        RewardCardView(reward: reward)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
            .frame(maxHeight: 400)
            
            Button(action: {
                SoundManager.shared.play(.rewardCollect)
                HapticManager.shared.buttonTap()
                onDismiss()
            }) {
                Text("Collect All")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 220)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(15)
            }
        }
        .padding()
        .onAppear {
            revealRewardsSequentially()
        }
    }
    
    private func revealRewardsSequentially() {
        for (index, reward) in rewards.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                withAnimation(.spring()) {
                    revealedRewards.append(reward)
                }
                SoundManager.shared.play(.xpGain)
                HapticManager.shared.impact(.medium)
            }
        }
    }
}

struct RewardCardView: View {
    let reward: Reward
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with rarity glow
            ZStack {
                Circle()
                    .fill(rewardColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(rarityColor, lineWidth: 2)
                    )
                
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
                        .fontWeight(.semibold)
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(rarityColor.opacity(0.5), lineWidth: 1)
                )
        )
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

struct ParticleEffectView: View {
    let color: Color
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                        .blur(radius: 1)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generateParticles(in size: CGSize) {
        for _ in 0..<30 {
            let centerX = size.width / 2
            let centerY = size.height / 2
            particles.append(Particle(
                x: centerX,
                y: centerY,
                opacity: 1.0
            ))
        }
        
        // Animate outward
        for (index, _) in particles.enumerated() {
            let angle = Double(index) * (360.0 / 30.0) * .pi / 180.0
            let distance: CGFloat = 150
            
            withAnimation(.easeOut(duration: 1.5)) {
                particles[index].x += cos(angle) * distance
                particles[index].y += sin(angle) * distance
                particles[index].opacity = 0
            }
        }
    }
}

#Preview {
    EnhancedChestOpeningView(
        chest: LootChest(
            type: .epic,
            rewards: [
                Reward(type: .xp, amount: 100, rarity: .epic, source: "Chest"),
                Reward(type: .gold, amount: 250, rarity: .rare, source: "Chest"),
                Reward(type: .gems, amount: 10, rarity: .epic, source: "Chest")
            ]
        )
    ) {}
}

