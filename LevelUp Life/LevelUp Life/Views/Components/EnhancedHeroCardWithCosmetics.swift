//
//  EnhancedHeroCardWithCosmetics.swift
//  LevelUp Life
//
//  Hero card that displays equipped cosmetics
//

import SwiftUI

struct EnhancedHeroCardWithCosmetics: View {
    let user: User
    @StateObject private var gameState = GameState.shared
    
    var body: some View {
        ZStack {
            // Background with cosmetic background
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundGradient)
            
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
                    // Avatar with cosmetics
                    ZStack {
                        // Aura effect
                        if let auraId = gameState.equippedCosmetics.aura {
                            Circle()
                                .stroke(auraColor(for: auraId), lineWidth: 4)
                                .frame(width: 100, height: 100)
                                .overlay {
                                    Circle()
                                        .fill(auraColor(for: auraId).opacity(0.3))
                                        .frame(width: 100, height: 100)
                                }
                                .scaleEffect(1.1)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: auraId)
                        }
                        
                        // Avatar circle
                        Circle()
                            .fill(avatarColor)
                            .frame(width: 80, height: 80)
                            .overlay {
                                if let outfitId = gameState.equippedCosmetics.outfit {
                                    outfitIcon(for: outfitId)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    // Name and class
                    VStack(alignment: .leading, spacing: 4) {
                        if let nameplateId = gameState.equippedCosmetics.nameplate {
                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(nameplateColor(for: nameplateId))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(nameplateColor(for: nameplateId).opacity(0.2))
                                .cornerRadius(6)
                        } else {
                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: classIcon)
                                .foregroundColor(.yellow)
                            
                            Text(user.classId.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Spacer()
                    
                    // Level badge
                    VStack(spacing: 4) {
                        Text("Lv.\(user.level)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(user.xp)/\(user.xpForNextLevel()) XP")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // XP Bar
                EnhancedXPBar(
                    current: user.xp,
                    required: user.xpForNextLevel(),
                    level: user.level
                )
                
                // Currencies
                HStack(spacing: 20) {
                    CosmeticHeroCurrencyBadge(icon: "dollarsign.circle.fill", amount: user.currencies.gold, color: .yellow)
                    CosmeticHeroCurrencyBadge(icon: "diamond.fill", amount: user.currencies.gems, color: .cyan)
                    CosmeticHeroCurrencyBadge(icon: "ticket.fill", amount: user.currencies.tickets, color: .orange)
                }
                
                // Streak
                if user.streak > 0 {
                    CosmeticStreakCard(streak: user.streak)
                }
            }
            .padding()
        }
        .frame(height: 200)
    }
    
    // MARK: - Computed Properties
    
    private var classIcon: String {
        return "person.fill"
    }
    
    private var backgroundGradient: LinearGradient {
        if let backgroundId = gameState.equippedCosmetics.background {
            return backgroundGradient(for: backgroundId)
        }
        
        return LinearGradient(
            colors: [
                Color.purple.opacity(0.3),
                Color.blue.opacity(0.2),
                Color.black.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Cosmetic Helpers
    
    private var avatarColor: Color {
        if let outfitId = gameState.equippedCosmetics.outfit {
            return outfitColor(for: outfitId)
        }
        return Color.blue
    }
    
    private func outfitColor(for id: String) -> Color {
        switch id {
        case "outfit_mystic": return .purple
        case "outfit_warrior": return .red
        case "outfit_mage": return .blue
        case "outfit_rogue": return .green
        default: return .blue
        }
    }
    
    @ViewBuilder
    private func outfitIcon(for id: String) -> some View {
        switch id {
        case "outfit_mystic":
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.white)
        case "outfit_warrior":
            Image(systemName: "shield.fill")
                .font(.title)
                .foregroundColor(.white)
        case "outfit_mage":
            Image(systemName: "wand.and.stars")
                .font(.title)
                .foregroundColor(.white)
        case "outfit_rogue":
            Image(systemName: "eye.fill")
                .font(.title)
                .foregroundColor(.white)
        default:
            Image(systemName: "person.fill")
                .font(.title)
                .foregroundColor(.white)
        }
    }
    
    private func auraColor(for id: String) -> Color {
        switch id {
        case "aura_purple": return .purple
        case "aura_fire": return .orange
        case "aura_ice": return .cyan
        case "aura_lightning": return .yellow
        default: return .blue
        }
    }
    
    private func nameplateColor(for id: String) -> Color {
        switch id {
        case "nameplate_gold": return .yellow
        case "nameplate_silver": return .gray
        case "nameplate_rainbow": return .purple
        default: return .white
        }
    }
    
    private func backgroundGradient(for id: String) -> LinearGradient {
        switch id {
        case "bg_stars":
            return LinearGradient(
                colors: [.black, .purple, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "bg_fire":
            return LinearGradient(
                colors: [.red, .orange, .yellow],
                startPoint: .top,
                endPoint: .bottom
            )
        case "bg_ocean":
            return LinearGradient(
                colors: [.blue, .cyan, .teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.black.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct CosmeticHeroCurrencyBadge: View {
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
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct CosmeticStreakCard: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            Text("Streak: \(streak) days")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    EnhancedHeroCardWithCosmetics(user: User())
}
