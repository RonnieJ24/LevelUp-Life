//
//  Guild.swift
//  LevelUp Life
//
//  Social guild system for team challenges
//

import Foundation

struct Guild: Identifiable, Codable {
    let id: String
    var name: String
    var description: String?
    var ownerId: String
    var memberIds: [String]
    var weeklyGoal: Int
    var teamXP: Int
    var leaderboardRank: Int?
    var settings: GuildSettings
    var createdAt: Date
    
    struct GuildSettings: Codable {
        var isPublic: Bool
        var maxMembers: Int
        var requiresApproval: Bool
        
        init(isPublic: Bool = false, maxMembers: Int = 20, requiresApproval: Bool = true) {
            self.isPublic = isPublic
            self.maxMembers = maxMembers
            self.requiresApproval = requiresApproval
        }
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String? = nil,
         ownerId: String,
         memberIds: [String] = [],
         weeklyGoal: Int = 1000,
         teamXP: Int = 0,
         leaderboardRank: Int? = nil,
         settings: GuildSettings = GuildSettings(),
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.memberIds = memberIds
        self.weeklyGoal = weeklyGoal
        self.teamXP = teamXP
        self.leaderboardRank = leaderboardRank
        self.settings = settings
        self.createdAt = createdAt
    }
    
    var goalProgress: Double {
        return min(1.0, Double(teamXP) / Double(weeklyGoal))
    }
}

struct GuildChallenge: Identifiable, Codable {
    let id: String
    var guildId: String
    var title: String
    var description: String
    var goal: Int
    var currentProgress: Int
    var rewards: [Reward]
    var startDate: Date
    var endDate: Date
    var status: ChallengeStatus
    
    enum ChallengeStatus: String, Codable {
        case active = "Active"
        case completed = "Completed"
        case failed = "Failed"
    }
}


