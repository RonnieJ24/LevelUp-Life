//
//  Completion.swift
//  LevelUp Life
//
//  Quest completion with verification payload and rewards
//

import Foundation

struct Completion: Identifiable, Codable {
    let id: String
    var questId: String
    var userId: String
    var timestamp: Date
    var verificationPayload: VerificationPayload
    var confidenceScore: Double
    var trustDelta: Double
    var rewardsGranted: [Reward]
    var wasVerified: Bool
    var requiresProof: Bool
    
    init(id: String = UUID().uuidString,
         questId: String,
         userId: String,
         timestamp: Date = Date(),
         verificationPayload: VerificationPayload = VerificationPayload(),
         confidenceScore: Double = 1.0,
         trustDelta: Double = 0.0,
         rewardsGranted: [Reward] = [],
         wasVerified: Bool = false,
         requiresProof: Bool = false) {
        self.id = id
        self.questId = questId
        self.userId = userId
        self.timestamp = timestamp
        self.verificationPayload = verificationPayload
        self.confidenceScore = confidenceScore
        self.trustDelta = trustDelta
        self.rewardsGranted = rewardsGranted
        self.wasVerified = wasVerified
        self.requiresProof = requiresProof
    }
}

struct VerificationPayload: Codable {
    var photoReference: String?
    var healthSummary: HealthSummary?
    var focusSessionData: FocusSessionData?
    var locationHash: String?
    var manualNotes: String?
    
    nonisolated init(photoReference: String? = nil, healthSummary: HealthSummary? = nil, focusSessionData: FocusSessionData? = nil, locationHash: String? = nil, manualNotes: String? = nil) {
        self.photoReference = photoReference
        self.healthSummary = healthSummary
        self.focusSessionData = focusSessionData
        self.locationHash = locationHash
        self.manualNotes = manualNotes
    }
    
    struct HealthSummary: Codable {
        var workoutType: String?
        var duration: TimeInterval?
        var calories: Double?
        var steps: Int?
        var distance: Double?
    }
    
    struct FocusSessionData: Codable {
        var duration: TimeInterval
        var appSwitches: Int
        var startTime: Date
        var endTime: Date
    }
}


