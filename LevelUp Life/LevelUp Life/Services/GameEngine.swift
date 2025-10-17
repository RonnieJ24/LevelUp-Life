//
//  GameEngine.swift
//  LevelUp Life
//
//  Core game logic: XP calculation, level ups, reward generation
//

import Foundation

class GameEngine {
    static let shared = GameEngine()
    
    private init() {}
    
    // MARK: - XP & Leveling
    
    func calculateXPReward(for quest: Quest, trustScore: Double, streakMultiplier: Double = 1.0) -> Int {
        let baseXP = quest.baseXP
        let trustMultiplier = calculateTrustMultiplier(trustScore: trustScore)
        let totalXP = Double(baseXP) * trustMultiplier * streakMultiplier
        return max(1, Int(totalXP))
    }
    
    func calculateGoldReward(for quest: Quest, trustScore: Double) -> Int {
        let baseGold = quest.baseGold
        let trustMultiplier = calculateTrustMultiplier(trustScore: trustScore)
        let totalGold = Double(baseGold) * trustMultiplier
        return max(1, Int(totalGold))
    }
    
    func checkLevelUp(user: User, newXP: Int) -> (leveledUp: Bool, newLevel: Int, bonusRewards: [Reward]) {
        var currentXP = user.xp + newXP
        var currentLevel = user.level
        var bonusRewards: [Reward] = []
        var leveledUp = false
        
        while currentXP >= xpRequiredForLevel(currentLevel) {
            currentXP -= xpRequiredForLevel(currentLevel)
            currentLevel += 1
            leveledUp = true
            
            // Level up bonus
            let goldBonus = currentLevel * 10
            bonusRewards.append(Reward(type: .gold, amount: goldBonus, source: "Level \(currentLevel) Bonus"))
            
            // Every 5 levels, grant gems
            if currentLevel % 5 == 0 {
                bonusRewards.append(Reward(type: .gems, amount: 5, rarity: .rare, source: "Level \(currentLevel) Milestone"))
            }
        }
        
        return (leveledUp, currentLevel, bonusRewards)
    }
    
    func xpRequiredForLevel(_ level: Int) -> Int {
        return Int(100 * pow(1.15, Double(level - 1)))
    }
    
    private func calculateTrustMultiplier(trustScore: Double) -> Double {
        // Trust score 0-100 maps to multiplier 0.5-1.2
        let normalized = max(0, min(100, trustScore)) / 100.0
        return 0.5 + (normalized * 0.7)
    }
    
    // MARK: - Loot Generation
    
    func generateDailyChest(questsCompleted: Int, trustScore: Double) -> LootChest {
        let chestType: ChestType
        let rewardCount: Int
        
        if questsCompleted >= 5 {
            chestType = .epic
            rewardCount = 4
        } else if questsCompleted >= 3 {
            chestType = .rare
            rewardCount = 3
        } else {
            chestType = .common
            rewardCount = 2
        }
        
        var rewards: [Reward] = []
        
        // Always include gold and XP
        rewards.append(Reward(type: .gold, amount: Int.random(in: 50...150), source: "Daily Chest"))
        rewards.append(Reward(type: .xp, amount: Int.random(in: 30...100), source: "Daily Chest"))
        
        // Random additional rewards based on rarity
        for _ in 2..<rewardCount {
            if Double.random(in: 0...1) < 0.3 {
                rewards.append(Reward(type: .gems, amount: Int.random(in: 1...5), rarity: .rare, source: "Daily Chest"))
            } else {
                rewards.append(Reward(type: .gold, amount: Int.random(in: 20...80), source: "Daily Chest"))
            }
        }
        
        // Mythic chance (2% on epic chests)
        if chestType == .epic && Double.random(in: 0...1) < 0.02 {
            rewards.append(Reward(type: .gems, amount: 50, rarity: .mythic, source: "Daily Chest - Mythic Drop!"))
        }
        
        return LootChest(type: chestType, rewards: rewards)
    }
    
    func generateQuestCompletionRewards(quest: Quest, trustScore: Double, streakMultiplier: Double) -> [Reward] {
        var rewards: [Reward] = []
        
        let xp = calculateXPReward(for: quest, trustScore: trustScore, streakMultiplier: streakMultiplier)
        let gold = calculateGoldReward(for: quest, trustScore: trustScore)
        
        rewards.append(Reward(type: .xp, amount: xp, source: "Quest: \(quest.title)"))
        rewards.append(Reward(type: .gold, amount: gold, source: "Quest: \(quest.title)"))
        
        // Bonus gem chance on hard quests
        if quest.difficulty == .hard && Double.random(in: 0...1) < 0.15 {
            rewards.append(Reward(type: .gems, amount: Int.random(in: 1...3), rarity: .rare, source: "Hard Quest Bonus"))
        }
        
        return rewards
    }
    
    // MARK: - Streak Calculations
    
    func calculateStreakMultiplier(streak: Int) -> Double {
        if streak >= 30 {
            return 2.0
        } else if streak >= 14 {
            return 1.5
        } else if streak >= 7 {
            return 1.25
        } else if streak >= 3 {
            return 1.1
        }
        return 1.0
    }
    
    func checkStreakStatus(user: User, currentDate: Date = Date()) -> StreakStatus {
        let calendar = Calendar.current
        let lastActiveDay = calendar.startOfDay(for: user.lastActiveDate)
        let today = calendar.startOfDay(for: currentDate)
        
        let daysDifference = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
        
        if daysDifference == 0 {
            return .active
        } else if daysDifference == 1 {
            return .needsCompletion
        } else {
            return .broken
        }
    }
    
    enum StreakStatus {
        case active
        case needsCompletion
        case broken
    }
}


