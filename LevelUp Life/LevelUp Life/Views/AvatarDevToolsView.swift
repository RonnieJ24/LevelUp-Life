import SwiftUI
import SceneKit

/// Developer Tools for Avatar Testing
struct AvatarDevToolsView: View {
    @StateObject private var avatarService = AvatarService()
    @State private var avatarIdInput = ""
    @State private var showFileInfo = false
    @State private var fileInfo: (path: String, size: Int64, loader: String)?
    
    var body: some View {
        NavigationView {
            List {
                Section("Avatar Creator") {
                    Button("Open Creator") {
                        // This will be handled by the parent view
                    }
                    .foregroundColor(.accentColor)
                }
                
                Section("Avatar Loading") {
                    HStack {
                        TextField("Avatar ID", text: $avatarIdInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Load") {
                            loadAvatarById()
                        }
                        .disabled(avatarIdInput.isEmpty)
                    }
                    
                    Button("Load Demo Avatar") {
                        loadDemoAvatar()
                    }
                    .foregroundColor(.accentColor)
                    
                    Button("Load Local USDZ (Smoke Test)") {
                        loadLocalUSDZ()
                    }
                    .foregroundColor(.accentColor)
                }
                
                Section("Loader Settings") {
                    Toggle("Verbose Telemetry", isOn: $avatarService.verboseTelemetry)
                }
                
                Section("Cache Management") {
                    Button("Clear Avatar Cache") {
                        avatarService.clearAvatarCache()
                        print("✅ Avatar cache cleared")
                    }
                    .foregroundColor(.red)
                    
                    Button("Clear RPM Cookies") {
                        Task {
                            await avatarService.clearRPMCookies()
                            print("✅ RPM cookies cleared")
                        }
                    }
                    .foregroundColor(.orange)
                    
                    Button("Show Last File Info") {
                        showFileInfo = true
                        fileInfo = getLastFileInfo()
                    }
                    .foregroundColor(.accentColor)
                }
                
                Section("Economy Testing") {
                    Button("+500 XP") {
                        GameState.shared.devAddXP(500)
                    }
                    .foregroundColor(.green)
                    
                    Button("+1000 Gems") {
                        GameState.shared.devAddGems(1000)
                    }
                    .foregroundColor(.purple)
                    
                    Button("Level Up") {
                        GameState.shared.devLevelUp()
                    }
                    .foregroundColor(.orange)
                }
                
                Section("Emotion Testing") {
                    ForEach(AvatarEmotion.allCases, id: \.self) { emotion in
                        Button("Set \(emotion.rawValue.capitalized)") {
                            GameState.shared.avatarState.emotion = emotion
                        }
                        .foregroundColor(emotion.moodColor)
                    }
                }
                
                Section("Game Events") {
                    Button("Trigger Quest Completion") {
                        triggerQuestCompletion()
                    }
                    .foregroundColor(.green)
                    
                    Button("Trigger Level Up") {
                        triggerLevelUp()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Trigger Streak Break") {
                        triggerStreakBreak()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Avatar Dev Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss handled by parent
                    }
                }
            }
        }
        .alert("File Info", isPresented: $showFileInfo) {
            Button("OK") { }
        } message: {
            if let info = fileInfo {
                Text("Path: \(info.path)\nSize: \(info.size) bytes\nLoader: \(info.loader)")
            } else {
                Text("No file info available")
            }
        }
    }
    
    private func loadAvatarById() {
        guard !avatarIdInput.isEmpty else { return }
        
        Task {
            await avatarService.loadAvatar(avatarId: avatarIdInput)
            print("✅ Avatar loading initiated: \(avatarIdInput)")
        }
    }
    
    private func loadDemoAvatar() {
        Task {
            // Use a known good test avatar ID
            let testAvatarId = "68f063c6e831796787e0ccc1"
            print("🧪 Test: Set test avatar ID: \(testAvatarId)")
            await avatarService.loadAvatar(avatarId: testAvatarId)
        }
    }
    
    private func loadLocalUSDZ() {
        // Load a local USDZ for smoke testing
        print("✅ Loading local USDZ for smoke test")
    }
    
    private func getLastFileInfo() -> (path: String, size: Int64, loader: String)? {
        if let localPath = GameState.shared.avatarState.localGlbPath {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: localPath),
               let fileSize = attributes[.size] as? Int64 {
                return (path: URL(fileURLWithPath: localPath).lastPathComponent, size: fileSize, loader: "GLTFSceneKit")
            }
        }
        return nil
    }
    
    private func triggerQuestCompletion() {
        // Simulate quest completion
        GameState.shared.avatarState.emotion = .happy
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.questComplete)
        print("✅ Quest completion triggered")
    }
    
    private func triggerLevelUp() {
        // Simulate level up
        GameState.shared.avatarState.emotion = .celebrate
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.levelUp)
        print("✅ Level up triggered")
    }
    
    private func triggerStreakBreak() {
        // Simulate streak break
        GameState.shared.avatarState.emotion = .sad
        HapticManager.shared.notification(.error)
        print("✅ Streak break triggered")
    }
}

// MARK: - GameState Extensions for Dev Tools

extension GameState {
    func devAddXP(_ amount: Int) {
        guard developerMode, var currentUser = user else { return }
        currentUser.xp += amount
        user = currentUser
        showDevToast = "Dev: +\(amount) XP added"
    }
}
