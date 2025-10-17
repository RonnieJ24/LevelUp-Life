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
            .navigationTitle("Avatar Workshop v1.1")
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
    
    // MARK: - Creator Tools Section
    
    private var creatorToolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Creator Tools")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Button("Open Ready Player Me Creator") {
                    showAlert(message: "Creator would open here")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Test Export Flow") {
                    showAlert(message: "Export flow test triggered")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Manual Testing Section
    
    private var manualTestingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manual Avatar Testing")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                HStack {
                    TextField("Avatar ID", text: $manualAvatarId)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Load") {
                        loadManualAvatar()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
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
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Toggle("Verbose Telemetry", isOn: $avatarService.verboseTelemetry)
                    .toggleStyle(SwitchToggleStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Cache Management Section
    
    private var cacheManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cache Management")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Button("Clear Avatar Cache") {
                    avatarService.clearAvatarCache()
                    showAlert(message: "Avatar cache cleared")
                }
                .buttonStyle(.bordered)
                
                if let cacheInfo = avatarService.getLastCachedAvatarInfo() {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Cached:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Path: \(cacheInfo.path)")
                            .font(.caption)
                        Text("Size: \(cacheInfo.size) bytes")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Emotion Testing Section
    
    private var emotionTestingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emotion Testing")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(AvatarEmotion.allCases, id: \.self) { emotion in
                    Button(action: {
                        gameState.avatarState.emotion = emotion
                        showAlert(message: "Set emotion to \(emotion.rawValue)")
                    }) {
                        VStack {
                            Image(systemName: emotion.systemImageName)
                                .font(.title2)
                                .foregroundColor(emotion.moodColor)
                            Text(emotion.rawValue.capitalized)
                                .font(.caption)
                        }
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
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status Information")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(label: "Current Avatar ID", value: avatarService.currentAvatarId ?? "None")
                StatusRow(label: "Loading State", value: avatarService.isLoading ? "Loading..." : "Idle")
                StatusRow(label: "Error State", value: avatarService.errorMessage ?? "None")
                StatusRow(label: "Loader Used", value: "GLTFKit2")
                StatusRow(label: "Avatar Workshop", value: "v1.1 Active")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func loadManualAvatar() {
        guard !manualAvatarId.isEmpty else {
            showAlert(message: "Please enter an avatar ID")
            return
        }
        
        Task {
            await avatarService.loadAvatar(avatarId: manualAvatarId)
        }
        showAlert(message: "Loading avatar: \(manualAvatarId)")
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Status Row Helper

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