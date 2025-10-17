//
//  TrustEngine.swift
//  LevelUp Life
//
//  Trust score calculation and verification logic
//

import Foundation
import HealthKit

class TrustEngine {
    static let shared = TrustEngine()
    
    private let confidenceThreshold = 0.6
    private let baseRandomCheckRate = 0.1
    private let lowTrustCheckRate = 0.4
    
    private init() {}
    
    // MARK: - Verification
    
    func verifyCompletion(quest: Quest, payload: VerificationPayload, currentTrustScore: Double) -> VerificationResult {
        var confidence = 0.0
        var signalsVerified: [VerificationSignal] = []
        
        // Calculate confidence based on signals
        for signal in quest.signalsRequired {
            let signalConfidence = evaluateSignal(signal, payload: payload)
            if signalConfidence > 0 {
                signalsVerified.append(signal)
                confidence += signalConfidence
            }
        }
        
        // Normalize confidence
        if !quest.signalsRequired.isEmpty {
            confidence = confidence / Double(quest.signalsRequired.count)
        } else if quest.verificationType == .manual {
            confidence = 0.5 // Manual entries have medium confidence
        }
        
        // Determine if spot check is needed
        let needsProof = shouldRequireProof(confidence: confidence, trustScore: currentTrustScore)
        
        // Calculate trust delta
        let trustDelta: Double
        if confidence >= confidenceThreshold {
            trustDelta = 0.5 // Small increase for verified completions
        } else if confidence >= 0.3 {
            trustDelta = 0.0 // Neutral
        } else {
            trustDelta = -1.0 // Decrease for suspicious completions
        }
        
        return VerificationResult(
            confidence: confidence,
            trustDelta: trustDelta,
            needsProof: needsProof,
            signalsVerified: signalsVerified
        )
    }
    
    private func evaluateSignal(_ signal: VerificationSignal, payload: VerificationPayload) -> Double {
        switch signal {
        case .healthWorkout:
            if let health = payload.healthSummary,
               let duration = health.duration,
               duration > 0 {
                return 0.9 // High confidence from HealthKit
            }
            return 0.0
            
        case .healthSteps:
            if let health = payload.healthSummary,
               let steps = health.steps,
               steps > 0 {
                return 0.9
            }
            return 0.0
            
        case .healthSleep:
            if let health = payload.healthSummary,
               let duration = health.duration,
               duration >= 3600 { // At least 1 hour
                return 0.9
            }
            return 0.0
            
        case .timerCompletion:
            if let focusData = payload.focusSessionData,
               focusData.duration > 0 {
                return 0.8
            }
            return 0.0
            
        case .lowAppSwitching:
            if let focusData = payload.focusSessionData,
               focusData.appSwitches < 5 {
                return 0.7
            }
            return 0.0
            
        case .locationDwell:
            if payload.locationHash != nil {
                return 0.6
            }
            return 0.0
            
        case .photoProof:
            if payload.photoReference != nil {
                return 0.5 // Photos have medium confidence (can be gamed)
            }
            return 0.0
            
        default:
            return 0.0
        }
    }
    
    private func shouldRequireProof(confidence: Double, trustScore: Double) -> Bool {
        if confidence >= confidenceThreshold {
            return false
        }
        
        let checkRate: Double
        if trustScore < 40 {
            checkRate = lowTrustCheckRate
        } else {
            checkRate = baseRandomCheckRate
        }
        
        return Double.random(in: 0...1) < checkRate
    }
    
    // MARK: - Trust Score Management
    
    func updateTrustScore(current: Double, delta: Double) -> Double {
        let newScore = current + delta
        return max(0, min(100, newScore))
    }
    
    func applyWeeklyDecay(trustScore: Double, completionsThisWeek: Int) -> Double {
        if completionsThisWeek == 0 {
            return max(0, trustScore - 5.0)
        }
        return trustScore
    }
    
    struct VerificationResult {
        let confidence: Double
        let trustDelta: Double
        let needsProof: Bool
        let signalsVerified: [VerificationSignal]
    }
}


