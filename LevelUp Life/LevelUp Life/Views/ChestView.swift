//
//  ChestView.swift
//  LevelUp Life
//
//  Chest opening and rewards
//

import SwiftUI

struct ChestView: View {
    @StateObject private var viewModel = AppViewModel.shared
    @State private var selectedChest: LootChest?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.availableChests.isEmpty {
                    EmptyChestsView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(viewModel.availableChests) { chest in
                                ChestCard(chest: chest) {
                                    selectedChest = chest
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Treasure Chests")
            .fullScreenCover(item: $selectedChest) { chest in
                EnhancedChestOpeningView(chest: chest) {
                    viewModel.openChest(chest)
                    selectedChest = nil
                }
            }
        }
    }
}

struct EmptyChestsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Chests Available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Complete 3+ daily quests to unlock your daily chest!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct ChestCard: View {
    let chest: LootChest
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: gradientColors[0].opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "gift.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("\(chest.type.rawValue) Chest")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Tap to open")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("Contains \(chest.rewards.count) rewards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var gradientColors: [Color] {
        switch chest.type {
        case .common, .daily:
            return [.gray, .gray.opacity(0.7)]
        case .rare:
            return [.blue, .cyan]
        case .epic:
            return [.purple, .pink]
        case .mythic:
            return [.orange, .red]
        case .seasonal:
            return [.green, .teal]
        }
    }
}

struct ChestOpeningView: View {
    let chest: LootChest
    let onOpen: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isOpening = false
    @State private var showRewards = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                if !showRewards {
                    VStack(spacing: 24) {
                        Text("\(chest.type.rawValue) Chest")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 150, height: 150)
                                .shadow(color: gradientColors[0].opacity(0.7), radius: 30, x: 0, y: 15)
                                .scaleEffect(isOpening ? 1.2 : 1.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6).repeatForever(autoreverses: true), value: isOpening)
                            
                            Image(systemName: "gift.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: openChest) {
                            Text("Open Chest")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: 200)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: gradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                        }
                        .disabled(isOpening)
                    }
                } else {
                    RewardsRevealView(rewards: chest.rewards) {
                        onOpen()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openChest() {
        isOpening = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring()) {
                showRewards = true
            }
        }
    }
    
    private var gradientColors: [Color] {
        switch chest.type {
        case .common, .daily:
            return [.gray, .gray.opacity(0.7)]
        case .rare:
            return [.blue, .cyan]
        case .epic:
            return [.purple, .pink]
        case .mythic:
            return [.orange, .red]
        case .seasonal:
            return [.green, .teal]
        }
    }
}

struct RewardsRevealView: View {
    let rewards: [Reward]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Rewards!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(rewards) { reward in
                        RewardItemView(reward: reward)
                    }
                }
            }
            .frame(maxHeight: 400)
            
            Button(action: onDismiss) {
                Text("Collect All")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(15)
            }
        }
        .padding()
    }
}

struct RewardItemView: View {
    let reward: Reward
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: rewardIcon)
                .font(.title2)
                .foregroundColor(rewardColor)
                .frame(width: 40)
            
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
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ChestView()
}

