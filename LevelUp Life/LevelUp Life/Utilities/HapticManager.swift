//
//  HapticManager.swift
//  LevelUp Life
//
//  Centralized haptic feedback system
//

import UIKit
import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Haptic Types
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Game-Specific Haptics
    
    func questCompleted() {
        notification(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.medium)
        }
    }
    
    func levelUp() {
        // Triple burst for level up
        notification(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.heavy)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impact(.heavy)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.impact(.rigid)
        }
    }
    
    func chestOpened() {
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.impact(.medium)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.impact(.light)
        }
    }
    
    func rewardEarned() {
        impact(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.impact(.light)
        }
    }
    
    func buttonTap() {
        impact(.light)
    }
    
    func streakIncrement() {
        notification(.success)
        impact(.medium)
    }
    
    func error() {
        notification(.error)
    }
    
    func warning() {
        notification(.warning)
    }
}




