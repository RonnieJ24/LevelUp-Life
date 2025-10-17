//
//  MockIAPService.swift
//  LevelUp Life
//
//  Mock in-app purchase service for developer mode
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MockIAPService: ObservableObject {
    static let shared = MockIAPService()
    
    @Published var purchasedProducts: Set<String> = []
    @Published var showPurchaseToast: String?
    
    private init() {}
    
    // MARK: - Gem Packs
    
    func purchaseGemPack(_ pack: GemPack) async -> Bool {
        guard GameState.shared.developerMode else {
            // In production, this would call real StoreKit
            return false
        }
        
        // Instant grant in dev mode
        GameState.shared.devAddGems(pack.gems)
        
        // Show success toast
        showPurchaseToast = "Dev: \(pack.gems) gems added!"
        
        // Haptic feedback
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.rewardCollect)
        
        return true
    }
    
    // MARK: - Boosters
    
    func purchaseBooster(_ booster: BoosterItem) async -> Bool {
        guard GameState.shared.developerMode else {
            return false
        }
        
        guard var user = GameState.shared.user else { return false }
        
        // Check if user has enough gems
        if user.currencies.gems >= booster.price {
            user.currencies.gems -= booster.price
            
            // Add booster to inventory
            if let index = GameState.shared.inventory.firstIndex(where: { $0.id == booster.id }) {
                GameState.shared.inventory[index].ownedQty += 1
            } else {
                let newItem = InventoryItem(
                    id: booster.id,
                    type: "booster",
                    subtype: booster.type.rawValue,
                    rarity: booster.rarity,
                    ownedQty: 1
                )
                GameState.shared.inventory.append(newItem)
            }
            
            GameState.shared.user = user
            
            showPurchaseToast = "Dev: \(booster.name) purchased!"
            HapticManager.shared.notification(.success)
            SoundManager.shared.play(.rewardCollect)
            
            return true
        } else {
            showPurchaseToast = "Not enough gems! Need \(booster.price - user.currencies.gems) more."
            HapticManager.shared.notification(.error)
            return false
        }
    }
    
    // MARK: - Cosmetics
    
    func purchaseCosmetic(_ cosmetic: CosmeticItem) async -> Bool {
        guard GameState.shared.developerMode else {
            return false
        }
        
        guard var user = GameState.shared.user else { return false }
        
        if user.currencies.gems >= cosmetic.price {
            user.currencies.gems -= cosmetic.price
            
            // Add cosmetic to inventory
            if let index = GameState.shared.inventory.firstIndex(where: { $0.id == cosmetic.id }) {
                GameState.shared.inventory[index].ownedQty += 1
            } else {
                let newItem = InventoryItem(
                    id: cosmetic.id,
                    type: "cosmetic",
                    subtype: cosmetic.category.rawValue,
                    rarity: cosmetic.rarity,
                    ownedQty: 1
                )
                GameState.shared.inventory.append(newItem)
            }
            
            GameState.shared.user = user
            
            showPurchaseToast = "Dev: \(cosmetic.name) purchased!"
            HapticManager.shared.notification(.success)
            SoundManager.shared.play(.rewardCollect)
            
            return true
        } else {
            showPurchaseToast = "Not enough gems! Need \(cosmetic.price - user.currencies.gems) more."
            HapticManager.shared.notification(.error)
            return false
        }
    }
    
    // MARK: - Pro Subscription
    
    func purchaseProSubscription() async -> Bool {
        guard GameState.shared.developerMode else {
            return false
        }
        
        GameState.shared.devTogglePro()
        showPurchaseToast = "Dev: Pro subscription activated!"
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.rewardCollect)
        
        return true
    }
}

// MARK: - Supporting Models

struct GemPack: Identifiable {
    let id = UUID()
    let gems: Int
    let price: String
    let bonus: Int?
    
    static let packs = [
        GemPack(gems: 100, price: "$1.99", bonus: nil),
        GemPack(gems: 300, price: "$4.99", bonus: nil),
        GemPack(gems: 800, price: "$9.99", bonus: 100),
        GemPack(gems: 2000, price: "$19.99", bonus: 300)
    ]
}

struct BoosterItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let type: BoosterType
    let rarity: Rarity
    let duration: TimeInterval?
    
    static let boosters = [
        BoosterItem(id: "xp_boost", name: "XP Boost x2", description: "Double XP for 60 minutes", price: 50, type: .xpBoost, rarity: .common, duration: 3600),
        BoosterItem(id: "cooldown_skip", name: "Cooldown Skip", description: "Complete any quest on cooldown", price: 30, type: .cooldownSkip, rarity: .common, duration: nil),
        BoosterItem(id: "instant_complete", name: "Instant Complete", description: "Instantly complete any quest", price: 100, type: .instantComplete, rarity: .rare, duration: nil),
        BoosterItem(id: "streak_saver", name: "Streak Saver", description: "Preserve your streak when you miss a day", price: 75, type: .streakSaver, rarity: .rare, duration: nil)
    ]
}

struct CosmeticItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let category: CosmeticCategory
    let rarity: Rarity
    let icon: String
    
    static let cosmetics = [
        // Outfits
        CosmeticItem(id: "outfit_mystic", name: "Mystic Outfit", description: "Purple robes with glowing trim", price: 200, category: .outfit, rarity: .epic, icon: "sparkles"),
        CosmeticItem(id: "outfit_warrior", name: "Warrior Armor", description: "Battle-worn armor with spikes", price: 180, category: .outfit, rarity: .rare, icon: "shield.fill"),
        CosmeticItem(id: "outfit_mage", name: "Mage Robes", description: "Flowing blue robes of power", price: 160, category: .outfit, rarity: .rare, icon: "wand.and.stars"),
        CosmeticItem(id: "outfit_rogue", name: "Rogue Cloak", description: "Shadowy green cloak", price: 140, category: .outfit, rarity: .common, icon: "eye.fill"),
        
        // Auras
        CosmeticItem(id: "aura_purple", name: "Purple Aura", description: "Mystical purple glow around avatar", price: 150, category: .aura, rarity: .rare, icon: "circle.fill"),
        CosmeticItem(id: "aura_fire", name: "Fire Aura", description: "Flickering flames around avatar", price: 120, category: .aura, rarity: .rare, icon: "flame.fill"),
        CosmeticItem(id: "aura_ice", name: "Ice Aura", description: "Crystalline ice particles", price: 130, category: .aura, rarity: .rare, icon: "snowflake"),
        CosmeticItem(id: "aura_lightning", name: "Lightning Aura", description: "Electric sparks dancing around", price: 140, category: .aura, rarity: .epic, icon: "bolt.fill"),
        
        // Nameplates
        CosmeticItem(id: "nameplate_gold", name: "Gold Nameplate", description: "Shimmering gold name display", price: 100, category: .nameplate, rarity: .rare, icon: "textformat"),
        CosmeticItem(id: "nameplate_silver", name: "Silver Nameplate", description: "Elegant silver text", price: 80, category: .nameplate, rarity: .common, icon: "textformat"),
        CosmeticItem(id: "nameplate_rainbow", name: "Rainbow Nameplate", description: "Color-shifting rainbow text", price: 200, category: .nameplate, rarity: .epic, icon: "textformat"),
        
        // Backgrounds
        CosmeticItem(id: "bg_stars", name: "Starry Background", description: "Animated starfield background", price: 300, category: .background, rarity: .mythic, icon: "star.fill"),
        CosmeticItem(id: "bg_fire", name: "Fire Background", description: "Flickering flames backdrop", price: 250, category: .background, rarity: .epic, icon: "flame.fill"),
        CosmeticItem(id: "bg_ocean", name: "Ocean Background", description: "Deep blue ocean waves", price: 200, category: .background, rarity: .rare, icon: "wave.3.right")
    ]
}

enum CosmeticCategory: String, CaseIterable {
    case outfit = "Outfits"
    case aura = "Auras"
    case nameplate = "Nameplates"
    case background = "Backgrounds"
}

