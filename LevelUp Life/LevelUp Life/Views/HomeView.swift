//
//  HomeView.swift
//  LevelUp Life
//
//  Main home screen with daily quests and user stats
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = AppViewModel.shared
    @StateObject private var gameState = GameState.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced Hero Card with Cosmetics
                    if let user = viewModel.currentUser {
                        NavigationLink(destination: AvatarView()) {
                            EnhancedHeroCardWithCosmetics(user: user)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                    
                    // Active Boosters
                    if !gameState.activeBoosters.isEmpty {
                        ActiveBoostersSection()
                            .padding(.horizontal)
                    }
                    
                    // Streak Badge
                    if let user = viewModel.currentUser, user.streak > 0 {
                        StreakCard(streak: user.streak)
                            .padding(.horizontal)
                    }
                    
                    // Daily Quest Scroll
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "scroll.fill")
                                .foregroundColor(.orange)
                            Text("Daily Quest Scroll")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(viewModel.completedQuestsToday.count)/\(viewModel.dailyQuests.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.dailyQuests.isEmpty {
                            EmptyQuestsView()
                        } else {
                            ForEach(viewModel.dailyQuests.filter { $0.status == .active }) { quest in
                                QuestCard(quest: quest) {
                                    Task {
                                        await viewModel.completeQuest(quest)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Quick Actions
                    QuickActionsCard()
                        .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("LevelUp Life")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct UserHeaderCard: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 70, height: 70)
                
                Image(systemName: user.classId.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("\(user.classId.rawValue) • Level \(user.level)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // XP Bar
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: user.levelProgress())
                        .tint(.purple)
                    
                    Text("\(user.xp) / \(user.xpForNextLevel()) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Currencies
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(user.currencies.gold)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "diamond.fill")
                        .foregroundColor(.cyan)
                    Text("\(user.currencies.gems)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading) {
                Text("\(streak) Day Streak!")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Keep it up!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("🔥")
                .font(.system(size: 40))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.2), .red.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

struct QuestCard: View {
    let quest: Quest
    let onComplete: () -> Void
    @State private var isCompleting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: quest.category.icon)
                    .foregroundColor(difficultyColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.headline)
                    
                    if let description = quest.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(quest.difficulty.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.2))
                        .foregroundColor(difficultyColor)
                        .cornerRadius(8)
                    
                    HStack(spacing: 4) {
                        Text("+\(quest.baseXP)")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
            }
            
            Button(action: {
                isCompleting = true
                onComplete()
            }) {
                HStack {
                    if isCompleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Quest")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(quest.canComplete() ? Color.purple : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!quest.canComplete() || isCompleting)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
    
    private var difficultyColor: Color {
        switch quest.difficulty {
        case .easy: return .green
        case .standard: return .blue
        case .hard: return .purple
        }
    }
}

struct QuickActionsCard: View {
    @State private var showFocusTimer = false
    @State private var showQuestPicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "timer",
                    title: "Start Focus",
                    color: .blue
                ) {
                    showFocusTimer = true
                }
                
                QuickActionButton(
                    icon: "figure.run",
                    title: "Log Workout",
                    color: .green
                ) {
                    // Quick workout quest from HealthKit
                }
                
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Quest",
                    color: .purple
                ) {
                    showQuestPicker = true
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showFocusTimer) {
            FocusTimerView()
        }
        .sheet(isPresented: $showQuestPicker) {
            EnhancedAddQuestView()
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct EmptyQuestsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "scroll")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Quests Available")
                .font(.headline)
            
            Text("Check back tomorrow for new daily quests!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ActiveBoostersSection: View {
    @StateObject private var gameState = GameState.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Boosters")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(gameState.activeBoosters.filter { $0.isActive }) { booster in
                        ActiveBoosterChip(booster: booster)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct ActiveBoosterChip: View {
    let booster: ActiveBooster
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: boosterIcon)
                .foregroundColor(.orange)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(booster.type.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(timeRemainingString)
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
    }
    
    private var boosterIcon: String {
        switch booster.type {
        case .xpBoost: return "arrow.up.circle.fill"
        case .cooldownSkip: return "clock.arrow.circlepath"
        case .instantComplete: return "checkmark.circle.fill"
        case .streakSaver: return "flame.fill"
        }
    }
    
    private var timeRemainingString: String {
        let remaining = booster.timeRemaining
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    HomeView()
}

