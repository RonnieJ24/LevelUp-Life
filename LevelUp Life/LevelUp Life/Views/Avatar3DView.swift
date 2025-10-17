import SwiftUI
import Combine

/// GLTFKit2-based 3D Avatar Viewer - Avatar Workshop v1.1
struct Avatar3DView: View {
    @StateObject private var avatarService = AvatarService()
    @StateObject private var gameState = GameState.shared
    @State private var showCreator = false
    @State private var showDevTools = false
    @State private var avatarURL: URL?
    
    // Avatar Workshop settings
    @State private var lightingPreset: String = "studio"
    @State private var backgroundPreset: String = "black"
    @State private var scaleMultiplier: Float = 1.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 3D Scene View
                if let url = avatarURL {
                    GLTFKit2AvatarViewWrapper(
                        avatarURL: url,
                        lightingPreset: $lightingPreset,
                        backgroundPreset: $backgroundPreset,
                        scaleMultiplier: $scaleMultiplier
                    )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                } else if avatarService.isLoading {
                    // Loading or empty state - NO FALLBACK AVATAR
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            ProgressView("Loading Ready Player Me Avatar...")
                                .progressViewStyle(CircularProgressViewStyle())
                            
                            Text("Downloading your custom avatar...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    // No Avatar State
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 12) {
                            Text("No Avatar")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Create your Ready Player Me avatar to get started")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Create Avatar") {
                            showCreator = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
                
                // Action Controls
                actionControls
                
                // Emotion Controls
                emotionControls
            }
            .navigationTitle("Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dev Tools") {
                        showDevTools = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Customize") {
                        showCreator = true
                    }
                }
            }
        }
        .sheet(isPresented: $showCreator) {
            AvatarCreatorView(isPresented: $showCreator) { avatarId in
                handleAvatarExported(avatarId: avatarId)
            }
        }
        .sheet(isPresented: $showDevTools) {
            AvatarDevToolsView()
        }
        .onAppear {
            loadCurrentAvatar()
        }
        .onChange(of: gameState.avatarState.localGlbPath) { newPath in
            if let path = newPath {
                avatarURL = URL(fileURLWithPath: path)
            } else {
                avatarURL = nil
            }
        }
    }
    
    // MARK: - Action Controls
    
    private var actionControls: some View {
        HStack(spacing: 16) {
            Button("Customize Avatar") {
                showCreator = true
            }
            .buttonStyle(.bordered)
            
            Button("Retry Load") {
                loadCurrentAvatar()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Emotion Controls
    
    private var emotionControls: some View {
        HStack(spacing: 20) {
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
                }
                .foregroundColor(emotion.moodColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Avatar Loading Pipeline
    
    private func loadCurrentAvatar() {
        guard let avatarId = gameState.avatarState.avatarId else {
            print("🔍 RPM Debug: No avatar ID found in GameState")
            return
        }
        
        print("🔍 RPM Debug: Starting to load avatar with ID: \(avatarId)")
        
        Task {
            await avatarService.loadAvatar(avatarId: avatarId)
        }
    }
    
    private func handleAvatarExported(avatarId: String) {
        print("🎉 RPM Debug: Avatar exported with ID: \(avatarId)")
        
        // Save avatar ID to GameState
        gameState.avatarState.avatarId = avatarId
        gameState.avatarState.lastUpdated = Date()
        
        print("🔍 RPM Debug: Avatar ID saved to GameState")
        
        // Download and load the avatar
        loadCurrentAvatar()
    }
    
    private func triggerEmotion(_ emotion: AvatarEmotion) {
        // Update GameState with emotion
        gameState.avatarState.emotion = emotion
        
        // Trigger haptic feedback
        switch emotion {
        case .happy:
            HapticManager.shared.notification(.success)
        case .celebrate:
            HapticManager.shared.notification(.success)
        case .proud:
            HapticManager.shared.notification(.success)
        case .sad:
            HapticManager.shared.notification(.error)
        case .neutral:
            HapticManager.shared.notification(.success)
        }
    }
}

#Preview {
    Avatar3DView()
}