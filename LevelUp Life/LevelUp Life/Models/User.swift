//
//  User.swift
//  LevelUp Life
//
//  Core user model with profile, progression, and currencies
//

import Foundation
import CloudKit

struct User: Identifiable, Codable {
    let id: String
    var appleId: String?
    var displayName: String
    var avatarId: String
    var classId: LifeClass
    var level: Int
    var xp: Int
    var currencies: Currencies
    var trustScore: Double
    var streak: Int
    var lastActiveDate: Date
    var settings: UserSettings
    var permissions: UserPermissions
    var createdAt: Date
    var proActive: Bool
    
    struct Currencies: Codable {
        var gold: Int
        var gems: Int
        var tickets: Int
        
        init(gold: Int = 0, gems: Int = 0, tickets: Int = 0) {
            self.gold = gold
            self.gems = gems
            self.tickets = tickets
        }
    }
    
    struct UserSettings: Codable {
        var notificationTime: Date?
        var enableHaptics: Bool
        var enableSounds: Bool
        var privacyMode: Bool
        var shareOnSocialFeed: Bool
        
        init() {
            self.enableHaptics = true
            self.enableSounds = true
            self.privacyMode = false
            self.shareOnSocialFeed = true
        }
    }
    
    struct UserPermissions: Codable {
        var healthKit: Bool
        var location: Bool
        var motion: Bool
        var notifications: Bool
        var screenTime: Bool
        
        init() {
            self.healthKit = false
            self.location = false
            self.motion = false
            self.notifications = false
            self.screenTime = false
        }
    }
    
    init(id: String = UUID().uuidString,
         appleId: String? = nil,
         displayName: String = "Hero",
         avatarId: String = "default",
         classId: LifeClass = .adventurer,
         level: Int = 1,
         xp: Int = 0,
         currencies: Currencies = Currencies(),
         trustScore: Double = 60.0,
         streak: Int = 0,
         lastActiveDate: Date = Date(),
         settings: UserSettings = UserSettings(),
         permissions: UserPermissions = UserPermissions(),
         createdAt: Date = Date(),
         proActive: Bool = false) {
        self.id = id
        self.appleId = appleId
        self.displayName = displayName
        self.avatarId = avatarId
        self.classId = classId
        self.level = level
        self.xp = xp
        self.currencies = currencies
        self.trustScore = trustScore
        self.streak = streak
        self.lastActiveDate = lastActiveDate
        self.settings = settings
        self.permissions = permissions
        self.createdAt = createdAt
        self.proActive = proActive
    }
    
    // XP required for next level (steepening curve)
    func xpForNextLevel() -> Int {
        return Int(100 * pow(1.15, Double(level - 1)))
    }
    
    // Progress to next level (0.0 to 1.0)
    func levelProgress() -> Double {
        let required = xpForNextLevel()
        return min(1.0, Double(xp) / Double(required))
    }
}

enum LifeClass: String, Codable, CaseIterable {
    case athlete = "Athlete"
    case scholar = "Scholar"
    case creator = "Creator"
    case entrepreneur = "Entrepreneur"
    case adventurer = "Adventurer"
    
    var icon: String {
        switch self {
        case .athlete: return "figure.run"
        case .scholar: return "book.fill"
        case .creator: return "paintbrush.fill"
        case .entrepreneur: return "briefcase.fill"
        case .adventurer: return "safari.fill"
        }
    }
    
    var description: String {
        switch self {
        case .athlete: return "Master physical challenges and build strength"
        case .scholar: return "Pursue knowledge and focus on learning"
        case .creator: return "Express creativity and build projects"
        case .entrepreneur: return "Build businesses and achieve goals"
        case .adventurer: return "Explore new experiences and take on challenges"
        }
    }
}

