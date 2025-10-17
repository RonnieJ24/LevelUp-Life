//
//  SoundManager.swift
//  LevelUp Life
//
//  Sound effects system
//

import AVFoundation
import SwiftUI
import Combine

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    @Published var isSoundEnabled = true
    
    private init() {
        loadUserPreference()
    }
    
    // MARK: - Sound Effects
    
    enum SoundEffect: String {
        case questComplete = "quest_complete"
        case levelUp = "level_up"
        case chestOpen = "chest_open"
        case rewardCollect = "reward_collect"
        case buttonTap = "button_tap"
        case streakMilestone = "streak_milestone"
        case xpGain = "xp_gain"
        case error = "error"
        
        var systemSound: SystemSoundID? {
            switch self {
            case .questComplete: return 1057 // Tink
            case .levelUp: return 1054 // Fanfare
            case .chestOpen: return 1103 // Bloom
            case .rewardCollect: return 1104 // Calypso
            case .buttonTap: return 1104 // Click
            case .streakMilestone: return 1013 // Anticipate
            case .xpGain: return 1052 // Swoosh
            case .error: return 1073 // Alert
            }
        }
    }
    
    func play(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        
        // Use system sounds for now (no custom audio files needed)
        if let soundID = effect.systemSound {
            AudioServicesPlaySystemSound(soundID)
        }
    }
    
    func playWithHaptic(_ effect: SoundEffect, haptic: (() -> Void)? = nil) {
        play(effect)
        haptic?()
    }
    
    // MARK: - Settings
    
    private func loadUserPreference() {
        isSoundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
        UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
    }
}

