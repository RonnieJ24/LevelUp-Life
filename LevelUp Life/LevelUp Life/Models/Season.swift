//
//  Season.swift
//  LevelUp Life
//
//  Seasonal events and passes
//

import Foundation

struct Season: Identifiable, Codable {
    let id: String
    var theme: String
    var name: String
    var description: String
    var startAt: Date
    var endAt: Date
    var passConfig: SeasonPassConfig
    var isActive: Bool
    
    struct SeasonPassConfig: Codable {
        var tiers: [SeasonTier]
        var priceUSD: Double
        
        struct SeasonTier: Codable {
            var level: Int
            var xpRequired: Int
            var freeRewards: [Reward]
            var premiumRewards: [Reward]
        }
    }
    
    init(id: String = UUID().uuidString,
         theme: String,
         name: String,
         description: String,
         startAt: Date,
         endAt: Date,
         passConfig: SeasonPassConfig,
         isActive: Bool = false) {
        self.id = id
        self.theme = theme
        self.name = name
        self.description = description
        self.startAt = startAt
        self.endAt = endAt
        self.passConfig = passConfig
        self.isActive = isActive
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endAt)
        return max(0, components.day ?? 0)
    }
}

struct UserSeasonProgress: Identifiable, Codable {
    let id: String
    var userId: String
    var seasonId: String
    var currentTier: Int
    var seasonXP: Int
    var hasPremiumPass: Bool
    var claimedRewards: [String]
    
    init(id: String = UUID().uuidString,
         userId: String,
         seasonId: String,
         currentTier: Int = 0,
         seasonXP: Int = 0,
         hasPremiumPass: Bool = false,
         claimedRewards: [String] = []) {
        self.id = id
        self.userId = userId
        self.seasonId = seasonId
        self.currentTier = currentTier
        self.seasonXP = seasonXP
        self.hasPremiumPass = hasPremiumPass
        self.claimedRewards = claimedRewards
    }
}


