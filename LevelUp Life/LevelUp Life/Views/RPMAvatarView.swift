import SwiftUI
import Combine

/// GLTFKit2-based RPM Avatar Screen
struct RPMAvatarView: View {
    @StateObject private var avatarService = AvatarService()
    @StateObject private var gameState = GameState.shared
    
    @State private var showCreator = false
    @State private var showDevTools = false
    @State private var avatarURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main Content Area
                if let errorMessage = avatarService.errorMessage {
                    // Error State - No Fallback Avatar
                    ScrollView {
                        VStack {
                            Spacer(minLength: 100)
                            ErrorCard(
                                error: NSError(domain: "AvatarService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]),
                                debugTicket: nil,
                                onRetry: {
                                    if let avatarId = avatarService.currentAvatarId {
                                        Task {
                                            await avatarService.loadAvatar(avatarId: avatarId)
                                        }
                                    }
                                },
                                onOpenCreator: {
                                    showCreator = true
                                }
                            )
                            Spacer(minLength: 100)
                        }
                    }
                } else if let url = avatarURL {
                    // Success State - GLTFKit2 Avatar
                    GLTFKit2AvatarViewWrapper(avatarURL: $avatarURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                } else if avatarService.isLoading {
                    // Loading State
                    VStack(spacing: 20) {
                        Spacer()
                        ProgressView("Loading Avatar...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Downloading your Ready Player Me model...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
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
                            openCreator()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
                
                // Action Controls (when avatar is loaded)
                if avatarURL != nil {
                    actionControls
                }
                
                // Emotion Controls (when avatar is loaded)
                if avatarURL != nil {
                    emotionControls
                }
            }
            .navigationTitle("Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if gameState.developerMode {
                        Button("Dev Tools") {
                            showDevTools = true
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Customize") {
                        openCreator()
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
            RPMAvatarDevToolsView()
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
                openCreator()
            }
            .buttonStyle(.bordered)
            
            Button("Retry Load") {
                retryLoad()
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
            print("🔍 RPM: No avatar ID - showing create CTA")
            return
        }
        
        print("🔍 RPM: Loading avatar with ID: \(avatarId)")
        
        Task {
            await avatarService.loadAvatar(avatarId: avatarId)
        }
    }
    
    private func retryLoad() {
        if let avatarId = gameState.avatarState.avatarId {
            Task {
                await avatarService.loadAvatar(avatarId: avatarId)
            }
        }
    }
    
    private func openCreator() {
        showCreator = true
    }
    
    private func handleAvatarExported(avatarId: String) {
        print("🎉 RPM: Avatar exported with ID: \(avatarId)")
        
        // Save avatar ID
        gameState.avatarState.avatarId = avatarId
        gameState.avatarState.lastUpdated = Date()
        
        // Start download
        loadCurrentAvatar()
    }
    
    private func triggerEmotion(_ emotion: AvatarEmotion) {
        // Update GameState with emotion
        GameState.shared.avatarState.emotion = emotion
        
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
    RPMAvatarView()
}