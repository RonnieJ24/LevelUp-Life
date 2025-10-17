import SwiftUI
import Combine

/// GLTFKit2-based 3D Avatar Viewer with robust error handling and status display
struct Avatar3DView: View {
    @StateObject private var avatarService = AvatarService()
    @StateObject private var gameState = GameState.shared
    @State private var showCreator = false
    @State private var showDevTools = false
    @State private var avatarURL: URL?
    @State private var showErrorCard = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 3D Scene View
                if let url = avatarURL {
                    GLTFKit2AvatarViewWrapper(avatarURL: $avatarURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                } else if avatarService.isLoading {
                    // Loading state with spinner
                    loadingView
                } else if showErrorCard || avatarService.errorMessage != nil {
                    // Error state with retry options
                    errorView
                } else {
                    // No Avatar State
                    noAvatarView
                }
                
                // Status Strip (Developer)
                if gameState.developerMode {
                    statusStrip
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
                showErrorCard = false
            } else {
                avatarURL = nil
            }
        }
        .onChange(of: avatarService.errorMessage) { errorMessage in
            showErrorCard = errorMessage != nil
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
                
                Text("Loading Ready Player Me Avatar...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Downloading your custom avatar...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text("Avatar Load Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let errorMessage = avatarService.errorMessage {
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            
            VStack(spacing: 12) {
                Button("Retry Load") {
                    loadCurrentAvatar()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Create New Avatar") {
                    showCreator = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - No Avatar View
    
    private var noAvatarView: some View {
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
    
    // MARK: - Status Strip
    
    private var statusStrip: some View {
        HStack {
            Text(avatarService.gltfKit2Status.displayText)
                .font(.caption)
                .foregroundColor(avatarService.gltfKit2Status.color)
            
            Spacer()
            
            if let avatarId = gameState.avatarState.avatarId {
                Text("ID: \(String(avatarId.prefix(8)))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
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