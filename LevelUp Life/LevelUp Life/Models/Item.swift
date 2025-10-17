//
//  Item.swift
//  LevelUp Life
//
//  Cosmetics, boosters, and purchasable items
//

import Foundation

struct Item: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var type: ItemType
    var rarity: Rarity
    var category: ItemCategory
    var metadata: ItemMetadata
    var price: ItemPrice
    var isOwned: Bool
    var isEquipped: Bool
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         type: ItemType,
         rarity: Rarity,
         category: ItemCategory,
         metadata: ItemMetadata,
         price: ItemPrice,
         isOwned: Bool = false,
         isEquipped: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.rarity = rarity
        self.category = category
        self.metadata = metadata
        self.price = price
        self.isOwned = isOwned
        self.isEquipped = isEquipped
    }
}

enum ItemType: String, Codable {
    case cosmetic = "Cosmetic"
    case booster = "Booster"
    case utility = "Utility"
}

enum ItemCategory: String, Codable {
    case avatar = "Avatar"
    case aura = "Aura"
    case background = "Background"
    case emote = "Emote"
    case xpBoost = "XP Boost"
    case streakSaver = "Streak Saver"
    case instantComplete = "Instant Complete"
}

struct ItemMetadata: Codable {
    var theme: String?
    var effect: BoosterEffect?
    var duration: TimeInterval?
    var visualAsset: String?
    
    struct BoosterEffect: Codable {
        var type: String
        var multiplier: Double?
        var charges: Int?
    }
}

struct ItemPrice: Codable {
    var gold: Int?
    var gems: Int?
    var tickets: Int?
    var realMoneyUSD: Double?
    
    init(gold: Int? = nil, gems: Int? = nil, tickets: Int? = nil, realMoneyUSD: Double? = nil) {
        self.gold = gold
        self.gems = gems
        self.tickets = tickets
        self.realMoneyUSD = realMoneyUSD
    }
}


