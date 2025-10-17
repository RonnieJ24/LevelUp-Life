//
//  AchievementModalView.swift
//  LevelUp Life
//
//  Achievement unlocked modal
//

import SwiftUI

struct AchievementModalView: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -200
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(achievement.icon)
                        .font(.system(size: 30))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievement Unlocked!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(achievement.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(achievement.color.opacity(0.5), lineWidth: 2)
                    )
            )
            .shadow(color: achievement.color.opacity(0.3), radius: 20, y: 10)
            .padding(.horizontal)
            
            Spacer()
        }
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        SoundManager.shared.play(.streakMilestone)
        HapticManager.shared.notification(.success)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            offset = 60
            opacity = 1.0
        }
        
        // Auto dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            animateOut()
        }
    }
    
    private func animateOut() {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = -200
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    static let streak5 = Achievement(
        title: "5-Day Streak!",
        description: "Completed quests 5 days in a row",
        icon: "🔥",
        color: .orange
    )
    
    static let streak7 = Achievement(
        title: "Week Warrior",
        description: "7-day streak unlocked",
        icon: "⚡️",
        color: .yellow
    )
    
    static let streak30 = Achievement(
        title: "Monthly Master",
        description: "30-day streak! Incredible dedication",
        icon: "👑",
        color: .purple
    )
    
    static let questsCompleted10 = Achievement(
        title: "Getting Started",
        description: "Completed 10 quests",
        icon: "🎯",
        color: .green
    )
    
    static let questsCompleted50 = Achievement(
        title: "Quest Hunter",
        description: "Completed 50 quests",
        icon: "🏹",
        color: .blue
    )
    
    static let questsCompleted100 = Achievement(
        title: "Century Club",
        description: "Completed 100 quests!",
        icon: "💯",
        color: .purple
    )
    
    static let chestOpened10 = Achievement(
        title: "Treasure Hunter",
        description: "Opened 10 chests",
        icon: "🎁",
        color: .cyan
    )
    
    static let level10 = Achievement(
        title: "Rising Star",
        description: "Reached Level 10",
        icon: "⭐️",
        color: .yellow
    )
    
    static let level25 = Achievement(
        title: "Elite Achiever",
        description: "Reached Level 25",
        icon: "💫",
        color: .purple
    )
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AchievementModalView(achievement: .streak5) {}
    }
}




