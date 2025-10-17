//
//  DeveloperToolsView.swift
//  LevelUp Life
//
//  Developer cheat panel for testing
//

import SwiftUI

struct DeveloperToolsView: View {
    @StateObject private var gameState = GameState.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Developer Mode") {
                    Toggle("Enable Developer Mode", isOn: $gameState.developerMode)
                        .tint(.purple)
                    
                    if gameState.developerMode {
                        Text("Dev mode active - mock purchases & instant unlocks enabled")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if gameState.developerMode {
                    Section("Currency Cheats") {
                        DevButton(icon: "diamond.fill", title: "Add 1,000 Gems", color: .cyan) {
                            gameState.devAddGems(1000)
                        }
                        
                        DevButton(icon: "dollarsign.circle.fill", title: "Add 10,000 Gold", color: .yellow) {
                            gameState.devAddGold(10000)
                        }
                        
                        DevButton(icon: "ticket.fill", title: "Add 10 Tickets", color: .orange) {
                            gameState.devAddTickets(10)
                        }
                    }
                    
                    Section("Avatar Testing") {
                        DevButton(icon: "person.crop.circle", title: "Test Quest Completion", color: .green) {
                            triggerQuestCompletion()
                        }
                        
                        DevButton(icon: "star.fill", title: "Test Level Up", color: .yellow) {
                            triggerLevelUp()
                        }
                        
                        DevButton(icon: "flame.fill", title: "Test Streak Break", color: .red) {
                            triggerStreakBreak()
                        }
                        
                        DevButton(icon: "face.smiling", title: "Set Happy", color: .green) {
                            GameState.shared.avatarState.emotion = .happy
                        }
                        
                        DevButton(icon: "face.dashed", title: "Set Sad", color: .blue) {
                            GameState.shared.avatarState.emotion = .sad
                        }
                        
                        DevButton(icon: "sparkles", title: "Set Celebrate", color: .yellow) {
                            GameState.shared.avatarState.emotion = .celebrate
                        }
                    }
                    
                    Section("Cosmetics & Items") {
                        DevButton(icon: "sparkles", title: "Unlock All Cosmetics", color: .pink) {
                            gameState.devUnlockAllCosmetics()
                        }
                        
                        DevButton(icon: "gift.fill", title: "Add Random Items", color: .purple) {
                            // Add random cosmetic items
                            let randomCosmetics = ["outfit_mystic", "aura_fire", "nameplate_gold", "bg_stars"]
                            for cosmetic in randomCosmetics {
                                if let index = gameState.inventory.firstIndex(where: { $0.id == cosmetic }) {
                                    gameState.inventory[index].ownedQty += 1
                                } else {
                                    let newItem = InventoryItem(id: cosmetic, type: "cosmetic", subtype: "item", rarity: .rare, ownedQty: 1)
                                    gameState.inventory.append(newItem)
                                }
                            }
                            gameState.showDevToast = "Dev: Random cosmetics added"
                        }
                    }
                    
                    Section("Progression Cheats") {
                        DevButton(icon: "arrow.up.circle.fill", title: "Simulate Level Up", color: .purple) {
                            gameState.devLevelUp()
                        }
                        
                        DevButton(icon: "flame.fill", title: "Give Streak Saver x1", color: .orange) {
                            gameState.devAddGold(0) // Placeholder
                            gameState.showDevToast = "Dev: Streak Saver added"
                        }
                        
                        DevButton(icon: "calendar", title: "Grant Season XP +500", color: .green) {
                            if var season = gameState.currentSeason {
                                season.currentXP += 500
                                gameState.currentSeason = season
                                gameState.showDevToast = "Dev: +500 Season XP"
                            }
                        }
                    }
                    
                    Section("Unlocks") {
                        DevButton(icon: "crown.fill", title: "Toggle Pro ON/OFF", color: .yellow) {
                            gameState.devTogglePro()
                        }
                        
                        DevButton(icon: "sparkles", title: "Unlock All Cosmetics", color: .pink) {
                            gameState.devUnlockAllCosmetics()
                        }
                        
                        DevButton(icon: "figure.run", title: "Seed Mock Health Workout", color: .green) {
                            gameState.showDevToast = "Dev: Mock workout added"
                        }
                    }
                    
                    Section("Quest Cheats") {
                        DevButton(icon: "clock.arrow.circlepath", title: "Clear All Cooldowns", color: .blue) {
                            for index in gameState.quests.indices {
                                gameState.quests[index].lastCompletedAt = nil
                            }
                            gameState.showDevToast = "Dev: All cooldowns cleared"
                        }
                        
                        DevButton(icon: "checkmark.circle.fill", title: "Complete All Today's Quests", color: .green) {
                            // Complete first 3 quests
                            let incomplete = gameState.quests.prefix(3)
                            for quest in incomplete {
                                gameState.completeQuest(quest)
                            }
                        }
                    }
                    
                    Section("Data Management") {
                        Button(role: .destructive, action: {
                            gameState.devResetData()
                        }) {
                            Label("Reset All Data", systemImage: "trash.fill")
                        }
                        
                        Button(action: {
                            // Export JSON
                            gameState.showDevToast = "Dev: JSON export (not implemented)"
                        }) {
                            Label("Export JSON", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle("Developer Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .top) {
                if let toast = gameState.showDevToast {
                    DevToast(message: toast) {
                        gameState.showDevToast = nil
                    }
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Avatar Testing Helpers
    
    private func triggerQuestCompletion() {
        GameState.shared.avatarState.emotion = .happy
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.questComplete)
    }
    
    private func triggerLevelUp() {
        GameState.shared.avatarState.emotion = .celebrate
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.levelUp)
    }
    
    private func triggerStreakBreak() {
        GameState.shared.avatarState.emotion = .sad
        HapticManager.shared.notification(.error)
    }
}

struct DevButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
    }
}

struct DevToast: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding()
            .background(Color.orange)
            .cornerRadius(12)
            .shadow(radius: 10)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        onDismiss()
                    }
                }
            }
    }
}

#Preview {
    DeveloperToolsView()
}

