//
//  AvatarView.swift
//  LevelUp Life
//
//  Avatar customization with cosmetics
//

import SwiftUI

struct AvatarView: View {
    @StateObject private var gameState = GameState.shared
    @State private var selectedCategory: CosmeticCategory = .outfit
    @State private var showEquipToast: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Current avatar preview
                AvatarPreview()
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                
                // Category tabs
                Picker("Category", selection: $selectedCategory) {
                    ForEach(CosmeticCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Cosmetics grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredCosmetics) { cosmetic in
                            AvatarCosmeticCard(cosmetic: cosmetic, onEquip: {
                                equipCosmetic(cosmetic)
                            }, onBuy: { cosmetic in
                                buyCosmetic(cosmetic)
                            })
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
            .overlay(alignment: .top) {
                if let toast = showEquipToast {
                    EquipToast(message: toast) {
                        showEquipToast = nil
                    }
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    private var filteredCosmetics: [CosmeticItem] {
        CosmeticItem.cosmetics.filter { $0.category == selectedCategory }
    }
    
    private func equipCosmetic(_ cosmetic: CosmeticItem) {
        // Check if user owns this cosmetic
        let ownedItem = gameState.inventory.first { $0.id == cosmetic.id }
        guard ownedItem?.ownedQty ?? 0 > 0 else {
            showEquipToast = "You don't own this cosmetic!"
            HapticManager.shared.notification(.error)
            return
        }
        
        // Equip the cosmetic
        switch cosmetic.category {
        case .outfit:
            gameState.equippedCosmetics.outfit = cosmetic.id
        case .aura:
            gameState.equippedCosmetics.aura = cosmetic.id
        case .nameplate:
            gameState.equippedCosmetics.nameplate = cosmetic.id
        case .background:
            gameState.equippedCosmetics.background = cosmetic.id
        }
        
        showEquipToast = "\(cosmetic.name) equipped!"
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.rewardCollect)
    }
    
    private func buyCosmetic(_ cosmetic: CosmeticItem) {
        guard let user = gameState.user else { return }
        
        if user.currencies.gems >= cosmetic.price {
            // Deduct gems
            var updatedUser = user
            updatedUser.currencies.gems -= cosmetic.price
            gameState.user = updatedUser
            
            // Add cosmetic to inventory
            if let index = gameState.inventory.firstIndex(where: { $0.id == cosmetic.id }) {
                gameState.inventory[index].ownedQty += 1
            } else {
                let newItem = InventoryItem(
                    id: cosmetic.id,
                    type: "cosmetic",
                    subtype: cosmetic.category.rawValue,
                    rarity: cosmetic.rarity,
                    ownedQty: 1
                )
                gameState.inventory.append(newItem)
            }
            
            showEquipToast = "\(cosmetic.name) purchased!"
            HapticManager.shared.notification(.success)
            SoundManager.shared.play(.rewardCollect)
        } else {
            showEquipToast = "Not enough gems! Need \(cosmetic.price - user.currencies.gems) more."
            HapticManager.shared.notification(.error)
        }
    }
}

struct AvatarPreview: View {
    @StateObject private var gameState = GameState.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Avatar Preview")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack {
                // Background
                if let backgroundId = gameState.equippedCosmetics.background {
                    BackgroundPreview(id: backgroundId)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                }
                
                VStack(spacing: 12) {
                    // Avatar with aura
                    ZStack {
                        // Aura effect
                        if let auraId = gameState.equippedCosmetics.aura {
                            AuraPreview(id: auraId)
                        }
                        
                        // Avatar circle
                        Circle()
                            .fill(avatarColor)
                            .frame(width: 80, height: 80)
                            .overlay {
                                if let outfitId = gameState.equippedCosmetics.outfit {
                                    OutfitPreview(id: outfitId)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                    }
                    
                    // Name with nameplate
                    if let nameplateId = gameState.equippedCosmetics.nameplate {
                        NameplatePreview(id: nameplateId, name: gameState.user?.displayName ?? "Hero")
                    } else {
                        Text(gameState.user?.displayName ?? "Hero")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(height: 200)
            .cornerRadius(20)
        }
    }
    
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
}

struct AvatarCosmeticCard: View {
    let cosmetic: CosmeticItem
    let onEquip: () -> Void
    let onBuy: (CosmeticItem) -> Void
    
    @StateObject private var gameState = GameState.shared
    
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
            // Cosmetic preview
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(rarityColor.opacity(0.2))
                    .frame(height: 100)
                
                if cosmetic.category == .outfit {
                    OutfitPreview(id: cosmetic.id)
                } else if cosmetic.category == .aura {
                    AuraPreview(id: cosmetic.id)
                } else if cosmetic.category == .nameplate {
                    NameplatePreview(id: cosmetic.id, name: "Preview")
                } else if cosmetic.category == .background {
                    BackgroundPreview(id: cosmetic.id)
                } else {
                    Image(systemName: cosmetic.icon)
                        .font(.title)
                        .foregroundColor(rarityColor)
                }
            }
            
            // Info
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
                
                // Rarity badge
                Text(cosmetic.rarity.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(rarityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(rarityColor.opacity(0.2))
                    .cornerRadius(4)
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
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rarityColor, lineWidth: isEquipped ? 2 : 0)
        )
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

struct OutfitPreview: View {
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

struct AuraPreview: View {
    let id: String
    
    var body: some View {
        Circle()
            .stroke(auraColor, lineWidth: 4)
            .frame(width: 90, height: 90)
            .overlay {
                Circle()
                    .fill(auraColor.opacity(0.3))
                    .frame(width: 90, height: 90)
            }
            .scaleEffect(1.1)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: id)
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

struct NameplatePreview: View {
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

struct BackgroundPreview: View {
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

struct EquipToast: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .shadow(radius: 10)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        onDismiss()
                    }
                }
            }
    }
}

#Preview {
    AvatarView()
}
