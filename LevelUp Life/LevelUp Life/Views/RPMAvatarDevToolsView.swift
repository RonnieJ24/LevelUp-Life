import SwiftUI

/// GLTFKit2 Developer Tools for RPM Avatar QA
struct RPMAvatarDevToolsView: View {
    @StateObject private var avatarService = AvatarService()
    @StateObject private var gameState = GameState.shared
    
    @State private var manualAvatarId = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Creator Tools
                    creatorToolsSection
                    
                    // Manual Avatar Testing
                    manualTestingSection
                    
                    // Settings
                    settingsSection
                    
                    // Cache Management
                    cacheManagementSection
                    
                    // Emotion Testing
                    emotionTestingSection
                    
                    // Status Information
                    statusSection
                }
                .padding()
            }
            .navigationTitle("GLTFKit2 Dev Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
        .alert("Dev Tools", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Sections
    
    private var creatorToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Creator Tools")
                .font(.headline)
                .fontWeight(.bold)
            
            Button("Open Creator") {
                openCreator()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var manualTestingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual Avatar Testing")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                TextField("Avatar ID", text: $manualAvatarId)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button("✅ Known-Good ID (68f063c6e831796787e0ccc1)") {
                    manualAvatarId = "68f063c6e831796787e0ccc1"
                    loadManualAvatar()
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
                Button("🧪 Set Test Avatar in GameState") {
                    gameState.setTestAvatar()
                    showAlert(message: "Test avatar ID set in GameState")
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
                Button("Load Avatar") {
                    loadManualAvatar()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.bold)
            
            Toggle("Verbose Telemetry", isOn: Binding(
                get: { avatarService.verboseTelemetry },
                set: { avatarService.verboseTelemetry = $0 }
            ))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var cacheManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cache Management")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Button("Clear Avatar Cache") {
                    clearCache()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                if let avatarId = gameState.avatarState.avatarId {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Avatar ID: \(avatarId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("GLB URL: https://models.readyplayer.me/\(avatarId).glb")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        if let localPath = gameState.avatarState.localGlbPath {
                            Text("Local Path: \(URL(fileURLWithPath: localPath).lastPathComponent)")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var emotionTestingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emotion Testing")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(AvatarEmotion.allCases, id: \.self) { emotion in
                    Button(action: {
                        triggerEmotion(emotion)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: emotion.systemImageName)
                                .font(.title2)
                            Text(emotion.rawValue.capitalized)
                                .font(.caption)
                        }
                        .foregroundColor(emotion.moodColor)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Information")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(label: "Current Avatar ID", value: avatarService.currentAvatarId ?? "None")
                StatusRow(label: "Loading State", value: avatarService.isLoading ? "Loading..." : "Idle")
                StatusRow(label: "Error State", value: avatarService.errorMessage ?? "None")
                StatusRow(label: "Loader Used", value: "GLTFKit2")
                StatusRow(label: "GLTFKit2 Status", value: "✅ Integrated")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func openCreator() {
        showAlert(message: "Creator will open in main view")
    }
    
    private func loadManualAvatar() {
        Task {
            await avatarService.loadAvatar(avatarId: manualAvatarId)
        }
    }
    
    private func clearCache() {
        avatarService.clearAvatarCache()
        showAlert(message: "Avatar cache cleared")
    }
    
    private func triggerEmotion(_ emotion: AvatarEmotion) {
        gameState.avatarState.emotion = emotion
        
        // Trigger haptic feedback
        switch emotion {
        case .happy, .celebrate, .proud:
            HapticManager.shared.notification(.success)
        case .sad:
            HapticManager.shared.notification(.error)
        case .neutral:
            HapticManager.shared.notification(.success)
        }
        
        showAlert(message: "Triggered \(emotion.rawValue) emotion")
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Supporting Views

struct StatusRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    RPMAvatarDevToolsView()
}