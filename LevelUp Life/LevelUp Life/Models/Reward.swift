//
//  Reward.swift
//  LevelUp Life
//
//  Reward system with XP, currencies, items, and loot
//

import Foundation

struct Reward: Identifiable, Codable {
    let id: String
    var type: RewardType
    var amount: Int
    var rarity: Rarity
    var source: String
    var itemId: String?
    
    init(id: String = UUID().uuidString,
         type: RewardType,
         amount: Int,
         rarity: Rarity = .common,
         source: String,
         itemId: String? = nil) {
        self.id = id
        self.type = type
        self.amount = amount
        self.rarity = rarity
        self.source = source
        self.itemId = itemId
    }
}

enum RewardType: String, Codable {
    case xp = "XP"
    case gold = "Gold"
    case gems = "Gems"
    case tickets = "Tickets"
    case item = "Item"
}

enum Rarity: String, Codable, CaseIterable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case mythic = "Mythic"
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .mythic: return "orange"
        }
    }
    
    var glowIntensity: Double {
        switch self {
        case .common: return 0.0
        case .rare: return 0.3
        case .epic: return 0.6
        case .mythic: return 1.0
        }
    }
}

struct LootChest: Identifiable, Codable {
    let id: String
    var type: ChestType
    var isOpened: Bool
    var rewards: [Reward]
    var unlockedAt: Date
    
    init(id: String = UUID().uuidString,
         type: ChestType = .common,
         isOpened: Bool = false,
         rewards: [Reward] = [],
         unlockedAt: Date = Date()) {
        self.id = id
        self.type = type
        self.isOpened = isOpened
        self.rewards = rewards
        self.unlockedAt = unlockedAt
    }
}

enum ChestType: String, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case mythic = "Mythic"
    case daily = "Daily"
    case seasonal = "Seasonal"
    
    var icon: String {
        return "gift.fill"
    }
}


