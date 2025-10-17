//
//  GameState.swift
//  LevelUp Life
//
//  Centralized game state manager with persistence
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GameState: ObservableObject {
    static let shared = GameState()
    
    // MARK: - Published State
    
    @Published var user: User?
    @Published var quests: [Quest] = []
    @Published var completions: [Completion] = []
    @Published var inventory: [InventoryItem] = []
    @Published var activeBoosters: [ActiveBooster] = []
    @Published var equippedCosmetics: EquippedCosmetics = EquippedCosmetics()
    @Published var currentSeason: SeasonProgress?
    @Published var guild: GuildData?
    @Published var skills: Skills = Skills()
    @Published var avatarState: AvatarState = AvatarState()
    
    // Developer Mode
    @Published var developerMode: Bool = false
    @Published var showDevToast: String?
    
    // UI State
    @Published var showLevelUpModal = false
    @Published var levelUpNewLevel = 0
    @Published var showChestUnlocked = false
    @Published var availableChests: [LootChest] = []
    @Published var showAchievement: Achievement?
    
    private let persistenceKey = "GameStateData"
    
    private init() {
        loadState()
        setupDefaultUser()
        startBoosterTimer()
    }
    
    // MARK: - Core Actions
    
    func completeQuest(_ quest: Quest) {
        guard var currentUser = user else { return }
        
        // Calculate rewards
        let baseXP = quest.baseXP
        let baseGold = quest.baseGold
        
        // Apply boosters
        let xpMultiplier = getActiveXPMultiplier()
        let trustMultiplier = getTrustMultiplier()
        
        let finalXP = Int(Double(baseXP) * xpMultiplier * trustMultiplier)
        let finalGold = Int(Double(baseGold) * trustMultiplier)
        
        // Grant rewards
        currentUser.xp += finalXP
        currentUser.currencies.gold += finalGold
        
        // Check level up
        while currentUser.xp >= currentUser.xpForNextLevel() {
            currentUser.xp -= currentUser.xpForNextLevel()
            currentUser.level += 1
            
            // Level up rewards
            currentUser.currencies.gold += currentUser.level * 10
            if currentUser.level % 5 == 0 {
                currentUser.currencies.gems += 5
            }
            
            levelUpNewLevel = currentUser.level
            showLevelUpModal = true
            
            HapticManager.shared.levelUp()
            SoundManager.shared.play(.levelUp)
        }
        
        // Update quest
        if let index = quests.firstIndex(where: { $0.id == quest.id }) {
            quests[index].status = .completed
            quests[index].lastCompletedAt = Date()
            quests[index].completionCount += 1
        }
        
        // Record completion
        let completion = Completion(
            questId: quest.id,
            userId: currentUser.id,
            verificationPayload: VerificationPayload()
        )
        completions.append(completion)
        
        // Update skills
        updateSkills(for: quest.category, amount: finalXP / 10)
        
        // Update season
        if var season = currentSeason {
            season.currentXP += finalXP
            currentSeason = season
        }
        
        // Update guild
        if var guildData = guild {
            guildData.teamXP += finalXP
            guild = guildData
        }
        
        // Check streak
        updateStreak()
        
        // Check chest unlock
        let completedToday = quests.filter { 
            $0.status == .completed && 
            Calendar.current.isDateInToday($0.lastCompletedAt ?? Date.distantPast)
        }.count
        
        if completedToday >= 3 && availableChests.isEmpty {
            unlockDailyChest()
        }
        
        user = currentUser
        saveState()
        
        // Haptics and sound
        HapticManager.shared.questCompleted()
        SoundManager.shared.play(.questComplete)
        
        // Show toast
        setToast("+\(finalXP) XP, +\(finalGold) Gold")
    }
    
    func unlockDailyChest() {
        let chest = LootChest(
            type: .daily,
            rewards: generateDailyChestRewards()
        )
        availableChests.append(chest)
        showChestUnlocked = true
        
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.chestOpen)
    }
    
    func openChest(_ chest: LootChest) {
        guard var currentUser = user else { return }
        
        // Apply rewards
        for reward in chest.rewards {
            switch reward.type {
            case .xp:
                currentUser.xp += reward.amount
            case .gold:
                currentUser.currencies.gold += reward.amount
            case .gems:
                currentUser.currencies.gems += reward.amount
            case .tickets:
                currentUser.currencies.tickets += reward.amount
            case .item:
                if let itemId = reward.itemId {
                    addItemToInventory(itemId: itemId)
                }
            }
        }
        
        // Remove chest
        availableChests.removeAll { $0.id == chest.id }
        
        user = currentUser
        saveState()
    }
    
    // MARK: - Helper Methods
    
    private func getActiveXPMultiplier() -> Double {
        let xpBoost = activeBoosters.first { $0.type == .xpBoost }
        return xpBoost != nil ? 2.0 : 1.0
    }
    
    private func getTrustMultiplier() -> Double {
        guard let trustScore = user?.trustScore else { return 1.0 }
        return 0.5 + (trustScore / 100.0 * 0.7)
    }
    
    private func updateSkills(for category: Category, amount: Int) {
        switch category {
        case .fitness:
            skills.strength += amount
        case .focus:
            skills.focus += amount
        case .knowledge:
            skills.knowledge += amount
        case .social:
            skills.social += amount
        case .wellbeing:
            skills.wellbeing += amount
        }
    }
    
    private func updateStreak() {
        guard var currentUser = user else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: currentUser.lastActiveDate)
        
        let daysDiff = calendar.dateComponents([.day], from: lastActive, to: today).day ?? 0
        
        if daysDiff == 1 {
            // Increment streak
            currentUser.streak += 1
            HapticManager.shared.streakIncrement()
            
            // Check achievements
            if currentUser.streak == 5 {
                showAchievement = .streak5
            } else if currentUser.streak == 7 {
                showAchievement = .streak7
            } else if currentUser.streak == 30 {
                showAchievement = .streak30
            }
        } else if daysDiff > 1 {
            // Streak broken - check for streak saver
            if hasStreakSaver() {
                // Don't reset, offer to use saver
            } else {
                currentUser.streak = 0
            }
        }
        
        currentUser.lastActiveDate = Date()
        user = currentUser
    }
    
    private func hasStreakSaver() -> Bool {
        return inventory.contains { $0.type == "booster" && $0.subtype == "streaksaver" && $0.ownedQty > 0 }
    }
    
    private func generateDailyChestRewards() -> [Reward] {
        var rewards: [Reward] = []
        
        // Always gold
        rewards.append(Reward(type: .gold, amount: Int.random(in: 50...150), source: "Daily Chest"))
        
        // Sometimes gems
        if Double.random(in: 0...1) < 0.3 {
            rewards.append(Reward(type: .gems, amount: Int.random(in: 1...10), rarity: .rare, source: "Daily Chest"))
        }
        
        // Maybe cosmetic fragment
        if Double.random(in: 0...1) < 0.1 {
            rewards.append(Reward(type: .item, amount: 1, rarity: .epic, source: "Daily Chest", itemId: "cosmetic_fragment"))
        }
        
        return rewards
    }
    
    private func addItemToInventory(itemId: String) {
        if let index = inventory.firstIndex(where: { $0.id == itemId }) {
            inventory[index].ownedQty += 1
        } else {
            let newItem = InventoryItem(id: itemId, type: "cosmetic", subtype: "fragment", rarity: .rare, ownedQty: 1)
            inventory.append(newItem)
        }
    }
    
    // MARK: - Developer Mode Actions
    
    func devAddGems(_ amount: Int) {
        guard var currentUser = user else { return }
        currentUser.currencies.gems += amount
        user = currentUser
        saveState()
        setToast("Dev: +\(amount) gems added")
    }
    
    func devAddGold(_ amount: Int) {
        guard var currentUser = user else { return }
        currentUser.currencies.gold += amount
        user = currentUser
        saveState()
        setToast("Dev: +\(amount) gold added")
    }
    
    func devAddTickets(_ amount: Int) {
        guard var currentUser = user else { return }
        currentUser.currencies.tickets += amount
        user = currentUser
        saveState()
        setToast("Dev: +\(amount) tickets added")
    }
    
    func devLevelUp() {
        guard developerMode, var currentUser = user else { return }
        currentUser.level += 1
        currentUser.xp = 0
        user = currentUser
        levelUpNewLevel = currentUser.level
        showLevelUpModal = true
        saveState()
        HapticManager.shared.levelUp()
        SoundManager.shared.play(.levelUp)
    }
    
    func devTogglePro() {
        guard developerMode, var currentUser = user else { return }
        currentUser.proActive = !currentUser.proActive
        user = currentUser
        saveState()
        showDevToast = currentUser.proActive ? "Dev: Pro ENABLED" : "Dev: Pro DISABLED"
    }
    
    func devUnlockAllCosmetics() {
        guard developerMode else { return }
        // Add all cosmetic items to inventory
        let cosmetics = ["outfit_mystic", "aura_purple", "nameplate_gold", "bg_stars"]
        for cosmetic in cosmetics {
            addItemToInventory(itemId: cosmetic)
        }
        showDevToast = "Dev: All cosmetics unlocked"
    }
    
    func devResetData() {
        guard developerMode else { return }
        UserDefaults.standard.removeObject(forKey: persistenceKey)
        user = nil
        quests = []
        completions = []
        inventory = []
        activeBoosters = []
        skills = Skills()
        setupDefaultUser()
        showDevToast = "Dev: All data reset"
    }
    
    private func setToast(_ message: String) {
        if developerMode {
            showDevToast = message
        }
    }
    
    // MARK: - Persistence
    
    private func saveState() {
        let state = PersistableState(
            user: user,
            quests: quests,
            inventory: inventory,
            equippedCosmetics: equippedCosmetics,
            skills: skills,
            developerMode: developerMode
        )
        
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
        }
    }
    
    private func loadState() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let state = try? JSONDecoder().decode(PersistableState.self, from: data) else {
            return
        }
        
        user = state.user
        quests = state.quests
        inventory = state.inventory
        equippedCosmetics = state.equippedCosmetics
        skills = state.skills
        developerMode = state.developerMode
    }
    
    private func setupDefaultUser() {
        if user == nil {
            user = User(
                displayName: "Hero",
                classId: .adventurer,
                level: 1,
                xp: 0,
                currencies: User.Currencies(gold: 100, gems: 50, tickets: 1),
                trustScore: 60.0,
                streak: 0,
                proActive: false
            )
            
            // Add default quests
            generateDefaultQuests()
        }
    }
    
    private func generateDefaultQuests() {
        guard let userId = user?.id else { return }
        
        let defaultQuests = [
            Quest(userId: userId, title: "Morning Workout", difficulty: .standard, category: .fitness),
            Quest(userId: userId, title: "Focus Session", difficulty: .standard, category: .focus),
            Quest(userId: userId, title: "Daily Reading", difficulty: .easy, category: .knowledge)
        ]
        
        quests = defaultQuests
    }
    
    // MARK: - Booster Management
    
    private func startBoosterTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.cleanupExpiredBoosters()
            }
        }
    }
    
    private func cleanupExpiredBoosters() {
        let now = Date()
        activeBoosters.removeAll { $0.expiresAt <= now }
    }
    
    // MARK: - Testing Methods
    
    func setTestAvatar() {
        avatarState.avatarId = "68f063c6e831796787e0ccc1"
        avatarState.lastUpdated = Date()
        print("🧪 Test: Set test avatar ID: \(avatarState.avatarId ?? "nil")")
    }
}

// MARK: - Supporting Models

struct PersistableState: Codable {
    let user: User?
    let quests: [Quest]
    let inventory: [InventoryItem]
    let equippedCosmetics: EquippedCosmetics
    let skills: Skills
    let developerMode: Bool
}

struct InventoryItem: Identifiable, Codable {
    let id: String
    let type: String // "cosmetic" or "booster"
    let subtype: String
    let rarity: Rarity
    var ownedQty: Int
}

struct EquippedCosmetics: Codable {
    var outfit: String?
    var aura: String?
    var nameplate: String?
    var background: String?
}

struct Skills: Codable {
    var strength: Int
    var focus: Int
    var knowledge: Int
    var social: Int
    var wellbeing: Int
    
    init(strength: Int = 0, focus: Int = 0, knowledge: Int = 0, social: Int = 0, wellbeing: Int = 0) {
        self.strength = strength
        self.focus = focus
        self.knowledge = knowledge
        self.social = social
        self.wellbeing = wellbeing
    }
}

struct ActiveBooster: Identifiable, Codable {
    let id = UUID()
    let type: BoosterType
    let expiresAt: Date
    
    var isActive: Bool {
        Date() < expiresAt
    }
    
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
}

enum BoosterType: String, Codable {
    case xpBoost = "XP Boost x2"
    case cooldownSkip = "Cooldown Skip"
    case instantComplete = "Instant Complete"
    case streakSaver = "Streak Saver"
}

struct SeasonProgress: Codable {
    let seasonId: String
    let theme: String
    var currentXP: Int
    var claimedTiers: [Int]
    let startDate: Date
    let endDate: Date
}

struct GuildData: Codable {
    let id: String
    let name: String
    var members: [String]
    var teamXP: Int
    let weeklyGoal: Int
}

