import Foundation
import SwiftUI
import Combine

/// Avatar Reactor - handles game events and triggers avatar reactions
class AvatarReactor: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let avatarService = AvatarService()
    
    init() {
        setupEventListeners()
    }
    
    private func setupEventListeners() {
        // Listen for quest completion
        NotificationCenter.default.publisher(for: .questCompleted)
            .sink { [weak self] _ in
                self?.triggerQuestCompletion()
            }
            .store(in: &cancellables)
        
        // Listen for level up
        NotificationCenter.default.publisher(for: .levelUp)
            .sink { [weak self] _ in
                self?.triggerLevelUp()
            }
            .store(in: &cancellables)
        
        // Listen for streak break
        NotificationCenter.default.publisher(for: .streakBroken)
            .sink { [weak self] _ in
                self?.triggerStreakBreak()
            }
            .store(in: &cancellables)
    }
    
    func triggerQuestCompletion() {
        // Update GameState with emotion
        GameState.shared.avatarState.emotion = .happy
        
        // Haptic feedback
        HapticManager.shared.notification(.success)
        
        // Sound effect
        SoundManager.shared.play(.questComplete)
        
        print("✅ Avatar reacted to quest completion")
    }
    
    func triggerLevelUp() {
        // Update GameState with emotion
        GameState.shared.avatarState.emotion = .celebrate
        
        // Haptic feedback
        HapticManager.shared.notification(.success)
        
        // Sound effect
        SoundManager.shared.play(.levelUp)
        
        print("✅ Avatar reacted to level up")
    }
    
    func triggerStreakBreak() {
        // Update GameState with emotion
        GameState.shared.avatarState.emotion = .sad
        
        // Haptic feedback
        HapticManager.shared.notification(.error)
        
        print("✅ Avatar reacted to streak break")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let questCompleted = Notification.Name("questCompleted")
    static let levelUp = Notification.Name("levelUp")
    static let streakBroken = Notification.Name("streakBroken")
}