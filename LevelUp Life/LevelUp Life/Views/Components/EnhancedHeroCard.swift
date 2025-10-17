//
//  EnhancedHeroCard.swift
//  LevelUp Life
//
//  Premium hero card with glow effects
//

import SwiftUI

struct EnhancedHeroCard: View {
    let user: User
    
    var body: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.2),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Glow effect
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.purple, .blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .blur(radius: 2)
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Avatar with class icon
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.purple.opacity(0.4), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 90, height: 90)
                        
                        // Avatar circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.yellow.opacity(0.5), lineWidth: 3)
                            )
                        
                        Image(systemName: user.classId.icon)
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                    
                    // User info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(user.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Image(systemName: user.classId.icon)
                                .font(.caption)
                                .foregroundColor(.cyan)
                            
                            Text(user.classId.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Streak indicator
                        if user.streak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(user.streak) day streak")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    // Currencies
                    VStack(alignment: .trailing, spacing: 8) {
                        HeroCurrencyBadge(icon: "dollarsign.circle.fill", amount: user.currencies.gold, color: .yellow)
                        HeroCurrencyBadge(icon: "diamond.fill", amount: user.currencies.gems, color: .cyan)
                    }
                }
                
                // XP Bar
                EnhancedXPBar(
                    current: user.xp,
                    required: user.xpForNextLevel(),
                    level: user.level
                )
            }
            .padding()
        }
        .shadow(color: .purple.opacity(0.3), radius: 20, y: 10)
    }
}

struct HeroCurrencyBadge: View {
    let icon: String
    let amount: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text("\(amount)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EnhancedHeroCard(user: User(
            displayName: "Hero",
            classId: .athlete,
            level: 12,
            xp: 450,
            currencies: User.Currencies(gold: 1234, gems: 56, tickets: 3),
            streak: 7
        ))
        .padding()
    }
}

