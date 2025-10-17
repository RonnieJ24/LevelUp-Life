//
//  EnhancedCosmeticCard.swift
//  LevelUp Life
//
//  Enhanced cosmetic card with rarity glow and animations
//

import SwiftUI

struct EnhancedCosmeticCard: View {
    let cosmetic: CosmeticItem
    let onEquip: () -> Void
    let onBuy: (CosmeticItem) -> Void
    
    @StateObject private var gameState = GameState.shared
    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -200
    
    private var isOwned: Bool {
        gameState.inventory.contains { $0.id == cosmetic.id && $0.ownedQty > 0 }
    }
    
    private var isEquipped: Bool {
        switch cosmetic.category {
        case .outfit:
            return gameState.equippedCosmetics.outfit == cosmetic.id
        case .aura:
            return gameState.equippedCosmetics.aura == cosmetic.id
        case .nameplate:
            return gameState.equippedCosmetics.nameplate == cosmetic.id
        case .background:
            return gameState.equippedCosmetics.background == cosmetic.id
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Cosmetic preview with rarity glow
            ZStack {
                // Background with rarity color
                RoundedRectangle(cornerRadius: 12)
                    .fill(rarityColor.opacity(0.2))
                    .frame(height: 100)
                
                // Shimmer effect for rare items
                if cosmetic.rarity != .common {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 100)
                        .offset(x: shimmerOffset)
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                shimmerOffset = 200
                            }
                        }
                }
                
                // Cosmetic preview
                if cosmetic.category == .outfit {
                    DynamicOutfitPreview(id: cosmetic.id)
                } else if cosmetic.category == .aura {
                    DynamicAuraPreview(id: cosmetic.id)
                } else if cosmetic.category == .nameplate {
                    DynamicNameplatePreview(id: cosmetic.id, name: "Preview")
                } else if cosmetic.category == .background {
                    DynamicBackgroundPreview(id: cosmetic.id)
                } else {
                    Image(systemName: cosmetic.icon)
                        .font(.title)
                        .foregroundColor(rarityColor)
                }
                
                // Rarity glow overlay
                RoundedRectangle(cornerRadius: 12)
                    .stroke(rarityColor, lineWidth: isEquipped ? 3 : 1)
                    .frame(height: 100)
                    .shadow(color: rarityColor.opacity(0.5), radius: isEquipped ? 10 : 5)
            }
            
            // Info section
            VStack(spacing: 4) {
                Text(cosmetic.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(cosmetic.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Rarity badge with glow
                Text(cosmetic.rarity.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(rarityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(rarityColor.opacity(0.2))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(rarityColor.opacity(0.5), lineWidth: 1)
                    )
            }
            
            // Action buttons
            if isOwned {
                Button(action: {
                    HapticManager.shared.buttonTap()
                    onEquip()
                }) {
                    Text(isEquipped ? "Equipped" : "Equip")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isEquipped ? Color.green : Color.blue)
                        .cornerRadius(8)
                        .shadow(color: (isEquipped ? Color.green : Color.blue).opacity(0.3), radius: 4)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .onLongPressGesture(minimumDuration: 0) { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                } perform: {
                    // Long press action if needed
                }
            } else {
                VStack(spacing: 4) {
                    Text("\(cosmetic.price) gems")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                    
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        onBuy(cosmetic)
                    }) {
                        Text("Buy")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.cyan)
                            .cornerRadius(8)
                            .shadow(color: Color.cyan.opacity(0.3), radius: 4)
                    }
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .onLongPressGesture(minimumDuration: 0) { pressing in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = pressing
                        }
                    } perform: {
                        // Long press action if needed
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rarityColor.opacity(0.3), lineWidth: isEquipped ? 2 : 0)
        )
        .scaleEffect(isEquipped ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEquipped)
    }
    
    private var rarityColor: Color {
        switch cosmetic.rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .mythic: return .orange
        }
    }
}

// MARK: - Preview Components

struct DynamicOutfitPreview: View {
    let id: String
    
    var body: some View {
        Circle()
            .fill(outfitColor)
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: outfitIcon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .shadow(color: outfitColor.opacity(0.5), radius: 5)
    }
    
    private var outfitColor: Color {
        switch id {
        case "outfit_mystic": return .purple
        case "outfit_warrior": return .red
        case "outfit_mage": return .blue
        case "outfit_rogue": return .green
        default: return .blue
        }
    }
    
    private var outfitIcon: String {
        switch id {
        case "outfit_mystic": return "sparkles"
        case "outfit_warrior": return "shield.fill"
        case "outfit_mage": return "wand.and.stars"
        case "outfit_rogue": return "eye.fill"
        default: return "person.fill"
        }
    }
}

struct DynamicAuraPreview: View {
    let id: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(auraColor, lineWidth: 4)
                .frame(width: 80, height: 80)
                .overlay {
                    Circle()
                        .fill(auraColor.opacity(0.3))
                        .frame(width: 80, height: 80)
                }
                .scaleEffect(1.1)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: id)
            
            // Particle effects
            if id == "aura_fire" {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 3, height: 3)
                        .offset(
                            x: cos(Double(i) * .pi / 2) * 25,
                            y: sin(Double(i) * .pi / 2) * 25
                        )
                        .opacity(0.8)
                }
            } else if id == "aura_ice" {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 2, height: 2)
                        .offset(
                            x: cos(Double(i) * .pi / 3) * 30,
                            y: sin(Double(i) * .pi / 3) * 30
                        )
                        .opacity(0.8)
                }
            }
        }
    }
    
    private var auraColor: Color {
        switch id {
        case "aura_purple": return .purple
        case "aura_fire": return .orange
        case "aura_ice": return .cyan
        case "aura_lightning": return .yellow
        default: return .blue
        }
    }
}

struct DynamicNameplatePreview: View {
    let id: String
    let name: String
    
    var body: some View {
        Text(name)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(nameplateColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(nameplateColor.opacity(0.2))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(nameplateColor.opacity(0.5), lineWidth: 1)
            )
    }
    
    private var nameplateColor: Color {
        switch id {
        case "nameplate_gold": return .yellow
        case "nameplate_silver": return .gray
        case "nameplate_rainbow": return .purple
        default: return .primary
        }
    }
}

struct DynamicBackgroundPreview: View {
    let id: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(backgroundGradient)
            .frame(height: 200)
            .overlay {
                if id == "bg_stars" {
                    // Animated stars
                    ForEach(0..<20, id: \.self) { _ in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 2, height: 2)
                            .position(
                                x: CGFloat.random(in: 0...300),
                                y: CGFloat.random(in: 0...200)
                            )
                    }
                } else if id == "bg_fire" {
                    // Fire effect
                    ForEach(0..<10, id: \.self) { _ in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 3, height: 3)
                            .position(
                                x: CGFloat.random(in: 0...300),
                                y: CGFloat.random(in: 0...200)
                            )
                    }
                }
            }
    }
    
    private var backgroundGradient: LinearGradient {
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
                colors: [.gray.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

#Preview {
    EnhancedCosmeticCard(
        cosmetic: CosmeticItem(
            id: "outfit_mystic",
            name: "Mystic Outfit",
            description: "Purple robes with glowing trim",
            price: 200,
            category: .outfit,
            rarity: .epic,
            icon: "sparkles"
        ),
        onEquip: {},
        onBuy: { _ in }
    )
    .padding()
}
