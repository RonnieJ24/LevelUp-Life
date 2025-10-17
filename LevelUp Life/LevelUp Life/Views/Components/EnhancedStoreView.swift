//
//  EnhancedStoreView.swift
//  LevelUp Life
//
//  Enhanced store with working dev-mode purchases
//

import SwiftUI

struct EnhancedStoreView: View {
    @StateObject private var viewModel = AppViewModel.shared
    @StateObject private var mockIAP = MockIAPService.shared
    @State private var selectedTab: StoreCategory = .boosters
    
    enum StoreCategory: String, CaseIterable {
        case boosters = "Boosters"
        case cosmetics = "Cosmetics"
        case gems = "Gems"
        case pro = "Pro"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Currency display at top
                if let user = viewModel.currentUser {
                    HStack(spacing: 20) {
                        StoreCurrencyDisplay(icon: "dollarsign.circle.fill", amount: user.currencies.gold, color: .yellow)
                        StoreCurrencyDisplay(icon: "diamond.fill", amount: user.currencies.gems, color: .cyan)
                        StoreCurrencyDisplay(icon: "ticket.fill", amount: user.currencies.tickets, color: .orange)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                }
                
                // Category tabs
                Picker("Category", selection: $selectedTab) {
                    ForEach(StoreCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedTab {
                        case .boosters:
                            BoostersSection()
                        case .cosmetics:
                            CosmeticsSection()
                        case .gems:
                            GemsSection()
                        case .pro:
                            ProSection()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
            .overlay(alignment: .top) {
                if let toast = mockIAP.showPurchaseToast {
                    PurchaseToast(message: toast) {
                        mockIAP.showPurchaseToast = nil
                    }
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func BoostersSection() -> some View {
        VStack(spacing: 16) {
            ForEach(BoosterItem.boosters) { booster in
                BoosterCard(booster: booster) {
                    Task {
                        await mockIAP.purchaseBooster(booster)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func CosmeticsSection() -> some View {
        VStack(spacing: 16) {
            ForEach(CosmeticItem.cosmetics) { cosmetic in
                CosmeticCard(cosmetic: cosmetic) {
                    Task {
                        await mockIAP.purchaseCosmetic(cosmetic)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func GemsSection() -> some View {
        VStack(spacing: 16) {
            ForEach(GemPack.packs) { pack in
                GemPackCard(pack: pack) {
                    Task {
                        await mockIAP.purchaseGemPack(pack)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func ProSection() -> some View {
        VStack(spacing: 20) {
            ProSubscriptionCard {
                Task {
                    await mockIAP.purchaseProSubscription()
                }
            }
            
            VStack(spacing: 16) {
                Text("Pro Benefits")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    StoreProBenefitRow(icon: "gift.fill", text: "Weekly Pro Gift Chest")
                    StoreProBenefitRow(icon: "chart.bar.fill", text: "Advanced Analytics")
                    StoreProBenefitRow(icon: "paintbrush.fill", text: "Pro Theme & Colors")
                    StoreProBenefitRow(icon: "plus.circle.fill", text: "Extra Daily Chest")
                }
            }
        }
    }
}

// MARK: - Card Components

struct BoosterCard: View {
    let booster: BoosterItem
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booster.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(booster.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(booster.price)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                    
                    Text("gems")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: {
                HapticManager.shared.buttonTap()
                onPurchase()
            }) {
                Text("Purchase")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cyan)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct CosmeticCard: View {
    let cosmetic: CosmeticItem
    let onPurchase: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: cosmetic.icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.purple)
                .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(cosmetic.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(cosmetic.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Price & Purchase
            VStack(spacing: 8) {
                Text("\(cosmetic.price)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                
                Button(action: {
                    HapticManager.shared.buttonTap()
                    onPurchase()
                }) {
                    Text("Buy")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.cyan)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct GemPackCard: View {
    let pack: GemPack
    let onPurchase: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Gem icon
            Image(systemName: "diamond.fill")
                .font(.title)
                .foregroundColor(.cyan)
                .frame(width: 50, height: 50)
                .background(Color.cyan.opacity(0.2))
                .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(pack.gems) Gems")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let bonus = pack.bonus {
                    Text("+ \(bonus) Bonus!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Price & Purchase
            VStack(spacing: 8) {
                Text(pack.price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Button(action: {
                    HapticManager.shared.buttonTap()
                    onPurchase()
                }) {
                    Text("Purchase")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ProSubscriptionCard: View {
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("LevelUp Pro")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Unlock premium features")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$9.99")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text("month")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: {
                HapticManager.shared.buttonTap()
                onPurchase()
            }) {
                Text("Start Pro Trial")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.yellow)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StoreProBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct StoreCurrencyDisplay: View {
    let icon: String
    let amount: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text("\(amount)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct PurchaseToast: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
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
    EnhancedStoreView()
}
