//
//  CloudKitManager.swift
//  LevelUp Life
//
//  CloudKit sync for cross-device data
//

import Foundation
import CloudKit
import Combine

class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    // Record Types
    private let userRecordType = "User"
    private let questRecordType = "Quest"
    private let completionRecordType = "Completion"
    
    private init() {
        container = CKContainer.default()
        publicDatabase = container.publicCloudDatabase
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async throws -> CKAccountStatus {
        return try await container.accountStatus()
    }
    
    // MARK: - Save User
    
    func saveUser(_ user: User) async throws {
        let record = try userToRecord(user)
        _ = try await privateDatabase.save(record)
    }
    
    // MARK: - Fetch User
    
    func fetchUser(userId: String) async throws -> User? {
        let predicate = NSPredicate(format: "id == %@", userId)
        let query = CKQuery(recordType: userRecordType, predicate: predicate)
        
        let result = try await privateDatabase.records(matching: query)
        
        if let (_, record) = result.matchResults.first {
            return try recordToUser(try record.get())
        }
        
        return nil
    }
    
    // MARK: - Save Quest
    
    func saveQuest(_ quest: Quest) async throws {
        let record = try questToRecord(quest)
        _ = try await privateDatabase.save(record)
    }
    
    // MARK: - Fetch Quests
    
    func fetchQuests(userId: String) async throws -> [Quest] {
        let predicate = NSPredicate(format: "userId == %@", userId)
        let query = CKQuery(recordType: questRecordType, predicate: predicate)
        
        let result = try await privateDatabase.records(matching: query)
        
        var quests: [Quest] = []
        for (_, recordResult) in result.matchResults {
            if let record = try? recordResult.get() {
                if let quest = try? recordToQuest(record) {
                    quests.append(quest)
                }
            }
        }
        
        return quests
    }
    
    // MARK: - Sync All Data
    
    func syncAllData(user: User, quests: [Quest]) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        // Save user
        try await saveUser(user)
        
        // Save quests
        for quest in quests {
            try? await saveQuest(quest)
        }
        
        await MainActor.run {
            lastSyncDate = Date()
        }
    }
    
    // MARK: - Record Conversion
    
    private func userToRecord(_ user: User) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: user.id)
        let record = CKRecord(recordType: userRecordType, recordID: recordID)
        
        record["id"] = user.id
        record["displayName"] = user.displayName
        record["level"] = user.level
        record["xp"] = user.xp
        record["gold"] = user.currencies.gold
        record["gems"] = user.currencies.gems
        record["tickets"] = user.currencies.tickets
        record["trustScore"] = user.trustScore
        record["streak"] = user.streak
        record["classId"] = user.classId.rawValue
        
        return record
    }
    
    private func recordToUser(_ record: CKRecord) throws -> User {
        guard let id = record["id"] as? String,
              let displayName = record["displayName"] as? String,
              let level = record["level"] as? Int,
              let xp = record["xp"] as? Int,
              let gold = record["gold"] as? Int,
              let gems = record["gems"] as? Int,
              let tickets = record["tickets"] as? Int,
              let trustScore = record["trustScore"] as? Double,
              let streak = record["streak"] as? Int,
              let classIdString = record["classId"] as? String,
              let classId = LifeClass(rawValue: classIdString) else {
            throw CloudKitError.invalidRecord
        }
        
        return User(
            id: id,
            displayName: displayName,
            classId: classId,
            level: level,
            xp: xp,
            currencies: User.Currencies(gold: gold, gems: gems, tickets: tickets),
            trustScore: trustScore,
            streak: streak
        )
    }
    
    private func questToRecord(_ quest: Quest) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: quest.id)
        let record = CKRecord(recordType: questRecordType, recordID: recordID)
        
        record["id"] = quest.id
        record["userId"] = quest.userId
        record["title"] = quest.title
        record["category"] = quest.category.rawValue
        record["difficulty"] = quest.difficulty.rawValue
        record["status"] = quest.status.rawValue
        record["completionCount"] = quest.completionCount
        
        if let description = quest.description {
            record["description"] = description
        }
        
        return record
    }
    
    private func recordToQuest(_ record: CKRecord) throws -> Quest {
        guard let id = record["id"] as? String,
              let userId = record["userId"] as? String,
              let title = record["title"] as? String,
              let categoryString = record["category"] as? String,
              let category = Category(rawValue: categoryString),
              let difficultyString = record["difficulty"] as? String,
              let difficulty = Difficulty(rawValue: difficultyString),
              let statusString = record["status"] as? String,
              let status = QuestStatus(rawValue: statusString) else {
            throw CloudKitError.invalidRecord
        }
        
        return Quest(
            id: id,
            userId: userId,
            title: title,
            description: record["description"] as? String,
            difficulty: difficulty,
            category: category,
            status: status,
            completionCount: (record["completionCount"] as? Int) ?? 0
        )
    }
    
    enum CloudKitError: Error {
        case invalidRecord
        case accountNotAvailable
        case syncFailed
    }
}

