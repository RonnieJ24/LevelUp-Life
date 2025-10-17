//
//  Quest.swift
//  LevelUp Life
//
//  Quest model with types, verification, and scheduling
//

import Foundation

struct Quest: Identifiable, Codable {
    let id: String
    var userId: String
    var title: String
    var description: String?
    var type: QuestType
    var difficulty: Difficulty
    var category: Category
    var verificationType: VerificationType
    var signalsRequired: [VerificationSignal]
    var status: QuestStatus
    var scheduledDate: Date?
    var deadline: Date?
    var cooldownHours: Int
    var lastCompletedAt: Date?
    var completionCount: Int
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         title: String,
         description: String? = nil,
         type: QuestType = .habit,
         difficulty: Difficulty = .standard,
         category: Category = .fitness,
         verificationType: VerificationType = .manual,
         signalsRequired: [VerificationSignal] = [],
         status: QuestStatus = .active,
         scheduledDate: Date? = nil,
         deadline: Date? = nil,
         cooldownHours: Int = 24,
         lastCompletedAt: Date? = nil,
         completionCount: Int = 0,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.type = type
        self.difficulty = difficulty
        self.category = category
        self.verificationType = verificationType
        self.signalsRequired = signalsRequired
        self.status = status
        self.scheduledDate = scheduledDate
        self.deadline = deadline
        self.cooldownHours = cooldownHours
        self.lastCompletedAt = lastCompletedAt
        self.completionCount = completionCount
        self.createdAt = createdAt
    }
    
    var rewardMultiplier: Double {
        switch difficulty {
        case .easy: return 0.7
        case .standard: return 1.0
        case .hard: return 1.5
        }
    }
    
    var baseXP: Int {
        let base = 50
        return Int(Double(base) * rewardMultiplier)
    }
    
    var baseGold: Int {
        let base = 20
        return Int(Double(base) * rewardMultiplier)
    }
    
    func isOnCooldown() -> Bool {
        guard let lastCompleted = lastCompletedAt else { return false }
        let cooldownSeconds = TimeInterval(cooldownHours * 3600)
        return Date().timeIntervalSince(lastCompleted) < cooldownSeconds
    }
    
    func canComplete() -> Bool {
        return status == .active && !isOnCooldown()
    }
}

enum QuestType: String, Codable {
    case habit = "Habit"
    case task = "Task"
    case timedChallenge = "Timed Challenge"
    case event = "Event"
    case teamQuest = "Team Quest"
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case standard = "Standard"
    case hard = "Hard"
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .standard: return "blue"
        case .hard: return "purple"
        }
    }
}

enum Category: String, Codable, CaseIterable {
    case fitness = "Fitness"
    case focus = "Focus"
    case knowledge = "Knowledge"
    case social = "Social"
    case wellbeing = "Wellbeing"
    
    var icon: String {
        switch self {
        case .fitness: return "figure.run"
        case .focus: return "brain.head.profile"
        case .knowledge: return "book.fill"
        case .social: return "person.3.fill"
        case .wellbeing: return "heart.fill"
        }
    }
}

enum QuestStatus: String, Codable {
    case active = "Active"
    case completed = "Completed"
    case failed = "Failed"
    case archived = "Archived"
}

enum VerificationType: String, Codable {
    case manual = "Manual"
    case healthKit = "HealthKit"
    case photo = "Photo"
    case timer = "Timer"
    case location = "Location"
    case hybrid = "Hybrid"
}

enum VerificationSignal: String, Codable {
    case healthWorkout = "Health Workout"
    case healthSteps = "Health Steps"
    case healthSleep = "Health Sleep"
    case healthMindfulness = "Health Mindfulness"
    case lowAppSwitching = "Low App Switching"
    case timerCompletion = "Timer Completion"
    case locationDwell = "Location Dwell"
    case photoProof = "Photo Proof"
}


