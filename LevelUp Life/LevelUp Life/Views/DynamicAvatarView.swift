//
//  DynamicAvatarView.swift
//  LevelUp Life
//
//  Next-gen avatar system with 3D-like rendering and animations
//

import SwiftUI

struct DynamicAvatarView: View {
    @StateObject private var gameState = GameState.shared
    @State private var selectedCategory: CosmeticCategory = .outfit
    @State private var showEquipToast: String?
    @State private var showLevelUpAnimation = false
    @State private var showEquipAnimation = false
    @State private var selectedCosmetic: CosmeticItem?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Dynamic Avatar Canvas
                DynamicAvatarCanvas(
                    showLevelUpAnimation: $showLevelUpAnimation,
                    showEquipAnimation: $showEquipAnimation,
                    selectedCosmetic: $selectedCosmetic
                )
                .frame(height: 300)
                .background(
                    DynamicBackgroundView()
                )
                
                // Category tabs with enhanced styling
                Picker("Category", selection: $selectedCategory) {
                    ForEach(CosmeticCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(.systemBackground))
                
                // Enhanced cosmetics grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredCosmetics) { cosmetic in
                            EnhancedCosmeticCard(cosmetic: cosmetic) {
                                equipCosmetic(cosmetic)
                            } onBuy: { cosmetic in
                                buyCosmetic(cosmetic)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
            .overlay(alignment: .top) {
                if let toast = showEquipToast {
                    FloatingToast(message: toast) {
                        showEquipToast = nil
                    }
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    private var filteredCosmetics: [CosmeticItem] {
        CosmeticItem.cosmetics.filter { $0.category == selectedCategory }
    }
    
    private func equipCosmetic(_ cosmetic: CosmeticItem) {
        // Check if user owns this cosmetic
        let ownedItem = gameState.inventory.first { $0.id == cosmetic.id }
        guard ownedItem?.ownedQty ?? 0 > 0 else {
            showEquipToast = "You don't own this cosmetic!"
            HapticManager.shared.notification(.error)
            return
        }
        
        // Trigger equip animation
        selectedCosmetic = cosmetic
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showEquipAnimation = true
        }
        
        // Equip the cosmetic
        switch cosmetic.category {
        case .outfit:
            gameState.equippedCosmetics.outfit = cosmetic.id
        case .aura:
            gameState.equippedCosmetics.aura = cosmetic.id
        case .nameplate:
            gameState.equippedCosmetics.nameplate = cosmetic.id
        case .background:
            gameState.equippedCosmetics.background = cosmetic.id
        }
        
        // Reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showEquipAnimation = false
                selectedCosmetic = nil
            }
        }
        
        showEquipToast = "\(cosmetic.name) equipped!"
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.rewardCollect)
    }
    
    private func buyCosmetic(_ cosmetic: CosmeticItem) {
        guard let user = gameState.user else { return }
        
        if user.currencies.gems >= cosmetic.price {
            // Deduct gems
            var updatedUser = user
            updatedUser.currencies.gems -= cosmetic.price
            gameState.user = updatedUser
            
            // Add cosmetic to inventory
            if let index = gameState.inventory.firstIndex(where: { $0.id == cosmetic.id }) {
                gameState.inventory[index].ownedQty += 1
            } else {
                let newItem = InventoryItem(
                    id: cosmetic.id,
                    type: "cosmetic",
                    subtype: cosmetic.category.rawValue,
                    rarity: cosmetic.rarity,
                    ownedQty: 1
                )
                gameState.inventory.append(newItem)
            }
            
            showEquipToast = "💎 \(cosmetic.name) purchased!"
            HapticManager.shared.notification(.success)
            SoundManager.shared.play(.rewardCollect)
        } else {
            showEquipToast = "Not enough gems! Need \(cosmetic.price - user.currencies.gems) more."
            HapticManager.shared.notification(.error)
        }
    }
}

struct DynamicAvatarCanvas: View {
    @Binding var showLevelUpAnimation: Bool
    @Binding var showEquipAnimation: Bool
    @Binding var selectedCosmetic: CosmeticItem?
    
    @StateObject private var gameState = GameState.shared
    @State private var breathingOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background particles
            ParticleFieldView()
            
            // Avatar container
            ZStack {
                // Aura effect
                if let auraId = gameState.equippedCosmetics.aura {
                    DynamicAuraView(id: auraId, intensity: glowIntensity)
                }
                
                // Main avatar body
                DynamicAvatarBody()
                    .scaleEffect(showEquipAnimation ? 1.1 : 1.0)
                    .offset(y: breathingOffset)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: breathingOffset)
                
                // Equip animation overlay
                if showEquipAnimation, let cosmetic = selectedCosmetic {
                    EquipAnimationOverlay(cosmetic: cosmetic)
                }
                
                // Level up celebration
                if showLevelUpAnimation {
                    LevelUpCelebrationView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startIdleAnimations()
        }
        .onChange(of: gameState.user?.level) { _, newLevel in
            if newLevel != nil {
                triggerLevelUpAnimation()
            }
        }
    }
    
    private func startIdleAnimations() {
        // Breathing animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            breathingOffset = -2
        }
        
        // Glow pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 0.8
        }
        
        // Particle movement
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            particleOffset = 360
        }
    }
    
    private func triggerLevelUpAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            showLevelUpAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showLevelUpAnimation = false
            }
        }
    }
}

struct DynamicAvatarBody: View {
    @StateObject private var gameState = GameState.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Head
            ZStack {
                Circle()
                    .fill(headColor)
                    .frame(width: 60, height: 60)
                    .overlay {
                        // Facial features
                        VStack(spacing: 4) {
                            // Eyes
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 6, height: 6)
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 6, height: 6)
                            }
                            
                            // Mouth
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 12, height: 3)
                        }
                    }
                
                // Outfit overlay
                if let outfitId = gameState.equippedCosmetics.outfit {
                    OutfitOverlayView(id: outfitId)
                }
            }
            
            // Body
            RoundedRectangle(cornerRadius: 20)
                .fill(bodyColor)
                .frame(width: 80, height: 100)
                .overlay {
                    // Body details
                    VStack {
                        // Chest area
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 20)
                        
                        Spacer()
                        
                        // Legs
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 12, height: 30)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 12, height: 30)
                        }
                    }
                    .padding(.vertical, 8)
                }
        }
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var headColor: Color {
        if let outfitId = gameState.equippedCosmetics.outfit {
            return outfitColor(for: outfitId)
        }
        return Color.blue
    }
    
    private var bodyColor: Color {
        if let outfitId = gameState.equippedCosmetics.outfit {
            return outfitColor(for: outfitId).opacity(0.8)
        }
        return Color.blue.opacity(0.8)
    }
    
    private func outfitColor(for id: String) -> Color {
        switch id {
        case "outfit_mystic": return .purple
        case "outfit_warrior": return .red
        case "outfit_mage": return .blue
        case "outfit_rogue": return .green
        default: return .blue
        }
    }
}

struct DynamicAuraView: View {
    let id: String
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .stroke(auraColor.opacity(intensity), lineWidth: 6)
                .frame(width: 200, height: 200)
                .blur(radius: 8)
            
            // Inner ring
            Circle()
                .stroke(auraColor.opacity(intensity * 0.7), lineWidth: 3)
                .frame(width: 150, height: 150)
            
            // Particle effects
            if id == "aura_fire" {
                FireParticleView()
            } else if id == "aura_ice" {
                IceParticleView()
            } else if id == "aura_lightning" {
                LightningParticleView()
            }
        }
        .scaleEffect(1.0 + intensity * 0.1)
    }
    
    private var auraColor: Color {
        switch id {
        case "aura_purple": return .purple
        case "aura_fire": return .orange
        case "aura_ice": return .cyan
        case "aura_lightning": return .yellow
        default: return .blue
        }
    }
}

struct ParticleFieldView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .animation(.linear(duration: particle.duration).repeatForever(autoreverses: false), value: particle.position)
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...400),
                    y: CGFloat.random(in: 0...300)
                ),
                color: [Color.blue, Color.purple, Color.cyan].randomElement() ?? .blue,
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.3...0.8),
                duration: Double.random(in: 3...8)
            )
        }
    }
}

struct EquipAnimationOverlay: View {
    let cosmetic: CosmeticItem
    
    var body: some View {
        ZStack {
            // Burst effect
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(cosmetic.rarity.dynamicColor)
                    .frame(width: 4, height: 4)
                    .offset(
                        x: cos(Double(i) * .pi / 6) * 50,
                        y: sin(Double(i) * .pi / 6) * 50
                    )
                    .opacity(0.8)
            }
            
            // Center glow
            Circle()
                .fill(cosmetic.rarity.dynamicColor.opacity(0.3))
                .frame(width: 100, height: 100)
                .blur(radius: 10)
        }
        .scaleEffect(1.5)
        .opacity(0.8)
    }
}

struct LevelUpCelebrationView: View {
    var body: some View {
        ZStack {
            // Confetti burst
            ForEach(0..<20, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill([Color.yellow, Color.orange, Color.pink, Color.cyan].randomElement() ?? .yellow)
                    .frame(width: 6, height: 12)
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .offset(
                        x: cos(Double(i) * .pi / 10) * 80,
                        y: sin(Double(i) * .pi / 10) * 80
                    )
            }
            
            // Level up text
            Text("LEVEL UP!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .shadow(color: .orange, radius: 5)
        }
        .scaleEffect(1.2)
    }
}

struct FireParticleView: View {
    @State private var particles: [CGPoint] = []
    
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(Color.orange)
                    .frame(width: 3, height: 3)
                    .position(particles[safe: i] ?? CGPoint(x: 0, y: 0))
                    .opacity(0.7)
            }
        }
        .onAppear {
            generateFireParticles()
        }
    }
    
    private func generateFireParticles() {
        particles = (0..<8).map { _ in
            CGPoint(
                x: CGFloat.random(in: -50...50),
                y: CGFloat.random(in: -50...50)
            )
        }
    }
}

struct IceParticleView: View {
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 2, height: 2)
                    .offset(
                        x: cos(Double(i) * .pi / 3) * 30,
                        y: sin(Double(i) * .pi / 3) * 30
                    )
                    .opacity(0.8)
            }
        }
    }
}

struct LightningParticleView: View {
    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 2, height: 20)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .opacity(0.9)
            }
        }
    }
}

struct OutfitOverlayView: View {
    let id: String
    
    var body: some View {
        ZStack {
            // Helmet/hat
            if id == "outfit_warrior" {
                Circle()
                    .stroke(Color.red, lineWidth: 3)
                    .frame(width: 65, height: 65)
            } else if id == "outfit_mage" {
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 70, height: 70)
            }
            
            // Accessories
            if id == "outfit_mystic" {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 2, height: 2)
                        .offset(
                            x: cos(Double(i) * .pi / 3) * 35,
                            y: sin(Double(i) * .pi / 3) * 35
                        )
                }
            }
        }
    }
}

struct DynamicBackgroundView: View {
    @StateObject private var gameState = GameState.shared
    
    var body: some View {
        ZStack {
            if let backgroundId = gameState.equippedCosmetics.background {
                backgroundGradient(for: backgroundId)
            } else {
                defaultGradient
            }
            
            // Ambient lighting
            RadialGradient(
                colors: [Color.white.opacity(0.1), Color.clear],
                center: .center,
                startRadius: 50,
                endRadius: 200
            )
        }
    }
    
    private var defaultGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.3),
                Color.blue.opacity(0.2),
                Color.black.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func backgroundGradient(for id: String) -> LinearGradient {
        switch id {
        case "bg_stars":
            return LinearGradient(
                colors: [.black, .purple, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "bg_fire":
            return LinearGradient(
                colors: [.red, .orange, .yellow],
                startPoint: .top,
                endPoint: .bottom
            )
        case "bg_ocean":
            return LinearGradient(
                colors: [.blue, .cyan, .teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return defaultGradient
        }
    }
}

struct FloatingToast: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
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

// MARK: - Supporting Models

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    let opacity: Double
    let duration: Double
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Rarity {
    var dynamicColor: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .mythic: return .orange
        }
    }
}

#Preview {
    DynamicAvatarView()
}
