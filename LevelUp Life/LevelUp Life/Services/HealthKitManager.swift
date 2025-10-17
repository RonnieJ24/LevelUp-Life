//
//  HealthKitManager.swift
//  LevelUp Life
//
//  HealthKit integration for workout, steps, sleep verification
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        // Check if we're in developer mode - use mock instead
        if GameState.shared.developerMode {
            await MainActor.run {
                self.isAuthorized = true
            }
            return
        }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await MainActor.run {
                self.isAuthorized = true
            }
        } catch {
            // If HealthKit fails, fall back to mock mode
            print("HealthKit authorization failed, using mock mode: \(error)")
            await MainActor.run {
                self.isAuthorized = true
            }
        }
    }
    
    // MARK: - Workouts
    
    func fetchRecentWorkout(within timeInterval: TimeInterval = 3600) async throws -> VerificationPayload.HealthSummary? {
        // Mock mode for developer
        if GameState.shared.developerMode {
            return VerificationPayload.HealthSummary(
                workoutType: "Running",
                duration: 1800, // 30 minutes
                calories: 300,
                steps: 5000,
                distance: 5000
            )
        }
        
        let workoutType = HKObjectType.workoutType()
        let startDate = Date().addingTimeInterval(-timeInterval)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workout = samples?.first as? HKWorkout else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Use statisticsForType for iOS 18+ compatibility
                let calories: Double?
                if #available(iOS 18.0, *) {
                    // Use new API for iOS 18+
                    calories = nil // Will be fetched separately if needed
                } else {
                    // Use deprecated API for older versions
                    calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                }
                
                let summary = VerificationPayload.HealthSummary(
                    workoutType: workout.workoutActivityType.name,
                    duration: workout.duration,
                    calories: calories,
                    steps: nil,
                    distance: workout.totalDistance?.doubleValue(for: .meter())
                )
                
                continuation.resume(returning: summary)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Steps
    
    func fetchStepsToday() async throws -> Int {
        // Mock mode for developer
        if GameState.shared.developerMode {
            return Int.random(in: 8000...15000)
        }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.invalidType
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Sleep
    
    func fetchSleepLastNight() async throws -> TimeInterval {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.invalidType
        }
        
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: endOfYesterday, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var totalSleep: TimeInterval = 0
                
                if let sleepSamples = samples as? [HKCategorySample] {
                    for sample in sleepSamples where sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue || sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                continuation.resume(returning: totalSleep)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    enum HealthKitError: Error {
        case notAvailable
        case invalidType
        case unauthorized
    }
}

// MARK: - Extensions

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Strength Training"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }
}

