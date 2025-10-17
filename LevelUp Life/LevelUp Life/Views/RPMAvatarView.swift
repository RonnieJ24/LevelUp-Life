import SwiftUI
import Combine

/// GLTFKit2-based RPM Avatar Screen - Avatar Workshop v1.1
struct RPMAvatarView: View {
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
                    // Success State - GLTFKit2 Avatar with Workshop Controls
                    ZStack {
                        GLTFKit2AvatarViewWrapper(
                            avatarURL: url,
                            lightingPreset: $lightingPreset,
                            backgroundPreset: $backgroundPreset,
                            scaleMultiplier: $scaleMultiplier
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        
                        // Avatar Workshop Controls
                        VStack {
                            Spacer()
                            AvatarWorkshopControls(
                                lightingPreset: $lightingPreset,
                                backgroundPreset: $backgroundPreset,
                                scaleMultiplier: $scaleMultiplier,
                                showDevTools: $showDevTools,
                                onPresetChange: { preset in
                                    gameState.avatarState.lightingPreset = preset
                                },
                                onBackgroundChange: { background in
                                    gameState.avatarState.backgroundPreset = background
                                },
                                onScaleChange: { scale in
                                    gameState.avatarState.scaleMultiplier = scale
                                },
                                onDevToolsToggle: {
                                    showDevTools = true
                                }
                            )
                        }
                    }
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
                        
                        Button(action: {
                            showCreator = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Avatar")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            RPMAvatarDevToolsView()
                .environmentObject(avatarService)
        }
        .onAppear {
            loadCurrentAvatar()
            loadWorkshopSettings()
        }
        .onChange(of: gameState.avatarState.localGlbPath) { newPath in
            if let path = newPath {
                avatarURL = URL(fileURLWithPath: path)
            } else {
                avatarURL = nil
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentAvatar() {
        if let localPath = gameState.avatarState.localGlbPath {
            avatarURL = URL(fileURLWithPath: localPath)
        } else if let avatarId = gameState.avatarState.avatarId {
            Task {
                await avatarService.loadAvatar(avatarId: avatarId)
            }
        }
    }
    
    private func loadWorkshopSettings() {
        lightingPreset = gameState.avatarState.lightingPreset
        backgroundPreset = gameState.avatarState.backgroundPreset
        scaleMultiplier = gameState.avatarState.scaleMultiplier
    }
    
    private func handleAvatarExported(avatarId: String) {
        print("🎯 Avatar Workshop: Avatar exported with ID: \(avatarId)")
        Task {
            await avatarService.loadAvatar(avatarId: avatarId)
        }
    }
}