//
//  AppViewModel.swift
//  LevelUp Life
//
//  Main app state management
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppViewModel: ObservableObject {
    static let shared = AppViewModel()
    
    // MARK: - Published State
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isOnboarding = true
    @Published var dailyQuests: [Quest] = []
    @Published var completedQuestsToday: [Quest] = []
    @Published var availableChests: [LootChest] = []
    @Published var currentGuild: Guild?
    @Published var activeSeason: Season?
    @Published var showRewardAnimation = false
    @Published var lastRewards: [Reward] = []
    @Published var showLevelUpModal = false
    @Published var levelUpNewLevel = 0
    @Published var showAchievement: Achievement?
    @Published var totalQuestsCompleted = 0
    @Published var totalChestsOpened = 0
    
    // Services
    private let gameEngine = GameEngine.shared
    private let trustEngine = TrustEngine.shared
    private let healthKitManager = HealthKitManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadUserData()
    }
    
    // MARK: - User Management
    
    func createNewUser(displayName: String, selectedClass: LifeClass) {
        let newUser = User(
            displayName: displayName,
            classId: selectedClass,
            currencies: User.Currencies(gold: 100, gems: 10, tickets: 1)
        )
        
        currentUser = newUser
        isAuthenticated = true
        isOnboarding = false
        
        saveUserData()
        generateDailyQuests()
    }
    
    func loadUserData() {
        // TODO: Load from CloudKit/UserDefaults
        // For now, check if we have a saved user
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isAuthenticated = true
            isOnboarding = false
            checkDailyReset()
        }
    }
    
    func saveUserData() {
        guard let user = currentUser else { return }
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    // MARK: - Quest Management
    
    func generateDailyQuests() {
        guard let user = currentUser else { return }
        
        // Generate 3-5 daily quests based on user class and level
        var quests: [Quest] = []
        
        // Easy quest
        quests.append(Quest(
            userId: user.id,
            title: "Morning Movement",
            description: "Complete any workout for 15 minutes",
            type: .habit,
            difficulty: .easy,
            category: .fitness,
            verificationType: .healthKit,
            signalsRequired: [.healthWorkout]
        ))
        
        // Standard quest
        quests.append(Quest(
            userId: user.id,
            title: "Focus Session",
            description: "Complete a 30-minute focused work session",
            type: .habit,
            difficulty: .standard,
            category: .focus,
            verificationType: .timer,
            signalsRequired: [.timerCompletion, .lowAppSwitching]
        ))
        
        // Another standard quest
        quests.append(Quest(
            userId: user.id,
            title: "Daily Steps",
            description: "Walk 8,000 steps today",
            type: .habit,
            difficulty: .standard,
            category: .fitness,
            verificationType: .healthKit,
            signalsRequired: [.healthSteps]
        ))
        
        // Class-specific quest
        switch user.classId {
        case .athlete:
            quests.append(Quest(
                userId: user.id,
                title: "Strength Challenge",
                description: "Complete a strength training workout",
                type: .habit,
                difficulty: .hard,
                category: .fitness,
                verificationType: .healthKit,
                signalsRequired: [.healthWorkout]
            ))
        case .scholar:
            quests.append(Quest(
                userId: user.id,
                title: "Deep Study",
                description: "Study for 60 minutes without distractions",
                type: .habit,
                difficulty: .hard,
                category: .knowledge,
                verificationType: .timer,
                signalsRequired: [.timerCompletion, .lowAppSwitching]
            ))
        case .creator:
            quests.append(Quest(
                userId: user.id,
                title: "Creative Work",
                description: "Work on a creative project for 45 minutes",
                type: .habit,
                difficulty: .hard,
                category: .focus,
                verificationType: .timer,
                signalsRequired: [.timerCompletion]
            ))
        default:
            quests.append(Quest(
                userId: user.id,
                title: "Evening Reflection",
                description: "Journal or meditate for 10 minutes",
                type: .habit,
                difficulty: .standard,
                category: .wellbeing,
                verificationType: .manual,
                signalsRequired: []
            ))
        }
        
        dailyQuests = quests
        saveDailyQuests()
    }
    
    func completeQuest(_ quest: Quest, verificationPayload: VerificationPayload = VerificationPayload()) async {
        guard var user = currentUser else { return }
        
        // Verify completion
        let verificationResult = trustEngine.verifyCompletion(
            quest: quest,
            payload: verificationPayload,
            currentTrustScore: user.trustScore
        )
        
        // Update trust score
        user.trustScore = trustEngine.updateTrustScore(
            current: user.trustScore,
            delta: verificationResult.trustDelta
        )
        
        // Calculate rewards
        let streakMultiplier = gameEngine.calculateStreakMultiplier(streak: user.streak)
        let rewards = gameEngine.generateQuestCompletionRewards(
            quest: quest,
            trustScore: user.trustScore,
            streakMultiplier: streakMultiplier
        )
        
        // Apply rewards
        for reward in rewards {
            applyReward(reward, to: &user)
        }
        
        // Check level up
        let levelUpResult = gameEngine.checkLevelUp(user: user, newXP: 0)
        if levelUpResult.leveledUp {
            user.level = levelUpResult.newLevel
            for bonus in levelUpResult.bonusRewards {
                applyReward(bonus, to: &user)
            }
            
            // Show level up modal
            levelUpNewLevel = levelUpResult.newLevel
            showLevelUpModal = true
            
            // Check for level achievements
            checkLevelAchievements(level: levelUpResult.newLevel)
        }
        
        // Update quest status
        if let index = dailyQuests.firstIndex(where: { $0.id == quest.id }) {
            dailyQuests[index].status = .completed
            dailyQuests[index].lastCompletedAt = Date()
            dailyQuests[index].completionCount += 1
            completedQuestsToday.append(dailyQuests[index])
        }
        
        // Update user
        user.lastActiveDate = Date()
        currentUser = user
        
        // Show reward animation
        lastRewards = rewards
        showRewardAnimation = true
        
        saveUserData()
        saveDailyQuests()
        
        // Check if daily chest is unlocked
        checkDailyChestUnlock()
    }
    
    private func applyReward(_ reward: Reward, to user: inout User) {
        switch reward.type {
        case .xp:
            user.xp += reward.amount
        case .gold:
            user.currencies.gold += reward.amount
        case .gems:
            user.currencies.gems += reward.amount
        case .tickets:
            user.currencies.tickets += reward.amount
        case .item:
            break // TODO: Add to inventory
        }
    }
    
    // MARK: - Chest Management
    
    func checkDailyChestUnlock() {
        guard let user = currentUser else { return }
        
        let questsCompleted = completedQuestsToday.count
        
        // Unlock chest if 3+ quests completed
        if questsCompleted >= 3 {
            let chest = gameEngine.generateDailyChest(
                questsCompleted: questsCompleted,
                trustScore: user.trustScore
            )
            
            if !availableChests.contains(where: { $0.type == .daily }) {
                availableChests.append(chest)
                saveChests()
            }
        }
    }
    
    func openChest(_ chest: LootChest) {
        guard var user = currentUser else { return }
        guard let index = availableChests.firstIndex(where: { $0.id == chest.id }) else { return }
        
        var openedChest = availableChests[index]
        openedChest.isOpened = true
        
        // Apply rewards
        for reward in openedChest.rewards {
            applyReward(reward, to: &user)
        }
        
        currentUser = user
        lastRewards = openedChest.rewards
        showRewardAnimation = true
        
        // Remove opened chest
        availableChests.remove(at: index)
        
        saveUserData()
        saveChests()
    }
    
    // MARK: - Streak Management
    
    func checkDailyReset() {
        guard var user = currentUser else { return }
        
        let streakStatus = gameEngine.checkStreakStatus(user: user)
        
        switch streakStatus {
        case .active:
            // User already logged in today
            break
        case .needsCompletion:
            // User needs to complete quests to maintain streak
            break
        case .broken:
            // Streak broken, reset
            user.streak = 0
            currentUser = user
            saveUserData()
        }
        
        // Check if it's a new day
        let calendar = Calendar.current
        if !calendar.isDateInToday(user.lastActiveDate) {
            // New day, regenerate quests
            completedQuestsToday.removeAll()
            generateDailyQuests()
        }
    }
    
    func updateStreak() {
        guard var user = currentUser else { return }
        
        // If user completed at least 3 quests today, increment streak
        if completedQuestsToday.count >= 3 {
            let calendar = Calendar.current
            if !calendar.isDateInToday(user.lastActiveDate) {
                let oldStreak = user.streak
                user.streak += 1
                currentUser = user
                saveUserData()
                
                // Check for streak achievements
                checkStreakAchievements(oldStreak: oldStreak, newStreak: user.streak)
            }
        }
    }
    
    // MARK: - Achievements
    
    private func checkStreakAchievements(oldStreak: Int, newStreak: Int) {
        if oldStreak < 5 && newStreak >= 5 {
            showAchievement = .streak5
        } else if oldStreak < 7 && newStreak >= 7 {
            showAchievement = .streak7
        } else if oldStreak < 30 && newStreak >= 30 {
            showAchievement = .streak30
        }
    }
    
    private func checkLevelAchievements(level: Int) {
        if level == 10 {
            showAchievement = .level10
        } else if level == 25 {
            showAchievement = .level25
        }
    }
    
    private func checkQuestAchievements() {
        if totalQuestsCompleted == 10 {
            showAchievement = .questsCompleted10
        } else if totalQuestsCompleted == 50 {
            showAchievement = .questsCompleted50
        } else if totalQuestsCompleted == 100 {
            showAchievement = .questsCompleted100
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveDailyQuests() {
        if let encoded = try? JSONEncoder().encode(dailyQuests) {
            UserDefaults.standard.set(encoded, forKey: "dailyQuests")
        }
        if let encoded = try? JSONEncoder().encode(completedQuestsToday) {
            UserDefaults.standard.set(encoded, forKey: "completedQuestsToday")
        }
    }
    
    private func saveChests() {
        if let encoded = try? JSONEncoder().encode(availableChests) {
            UserDefaults.standard.set(encoded, forKey: "availableChests")
        }
    }
}

