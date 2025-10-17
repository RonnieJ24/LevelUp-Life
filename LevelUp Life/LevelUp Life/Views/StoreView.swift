//
//  StoreView.swift
//  LevelUp Life
//
//  In-app purchase store
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var viewModel = AppViewModel.shared
    @State private var selectedTab: StoreTab = .gems
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Currency Display
                if let user = viewModel.currentUser {
                    HStack(spacing: 20) {
                        CurrencyBadge(icon: "dollarsign.circle.fill", color: .yellow, amount: user.currencies.gold)
                        CurrencyBadge(icon: "diamond.fill", color: .cyan, amount: user.currencies.gems)
                        CurrencyBadge(icon: "ticket.fill", color: .orange, amount: user.currencies.tickets)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                }
                
                // Tab Picker
                Picker("Store", selection: $selectedTab) {
                    ForEach(StoreTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedTab {
                        case .gems:
                            GemsStoreSection()
                        case .boosters:
                            BoostersStoreSection()
                        case .cosmetics:
                            CosmeticsStoreSection()
                        case .pro:
                            ProSubscriptionSection()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Store")
            .background(Color(.systemGroupedBackground))
        }
    }
}

enum StoreTab: String, CaseIterable {
    case gems = "Gems"
    case boosters = "Boosters"
    case cosmetics = "Cosmetics"
    case pro = "Pro"
}

struct CurrencyBadge: View {
    let icon: String
    let color: Color
    let amount: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(amount)")
                .font(.headline)
        }
    }
}

// MARK: - Store Sections

struct GemsStoreSection: View {
    @StateObject private var storeManager = StoreManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text("💎 Purchase Gems")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Use gems to unlock premium cosmetics, boosters, and seasonal passes")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(StoreManager.mockProducts.filter { $0.type == .gems }) { product in
                StoreProductCard(product: product)
            }
        }
    }
}

struct BoostersStoreSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("⚡ Boosters")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(StoreManager.mockProducts.filter { $0.type == .booster }) { product in
                StoreProductCard(product: product)
            }
        }
    }
}

struct CosmeticsStoreSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("✨ Cosmetics")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Coming Soon!")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(40)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
    }
}

struct ProSubscriptionSection: View {
    var body: some View {
        VStack(spacing: 20) {
            // Pro Header
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("LevelUp Pro")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock premium features and accelerate your progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            
            // Benefits
            VStack(alignment: .leading, spacing: 12) {
                Text("Premium Benefits")
                    .font(.headline)
                
                ProBenefitRow(icon: "chart.bar.fill", text: "Advanced analytics & insights")
                ProBenefitRow(icon: "brain.head.profile", text: "AI coach weekly plans")
                ProBenefitRow(icon: "infinity", text: "Unlimited custom quests")
                ProBenefitRow(icon: "shield.fill", text: "Priority streak recovery")
                ProBenefitRow(icon: "gift.fill", text: "Extra daily chest")
                ProBenefitRow(icon: "paintbrush.fill", text: "Premium themes")
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Pricing
            VStack(spacing: 12) {
                Button(action: {}) {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Annual Plan")
                                    .font(.headline)
                                Text("$59.99/year")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("SAVE 38%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 2)
                    )
                }
                
                Button(action: {}) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Monthly Plan")
                                .font(.headline)
                            Text("$7.99/month")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct ProBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct StoreProductCard: View {
    let product: StoreProduct
    @State private var isPurchasing = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: product.icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Purchase Button
            Button(action: {
                isPurchasing = true
                // Simulate purchase
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isPurchasing = false
                }
            }) {
                if isPurchasing {
                    ProgressView()
                } else {
                    Text(product.price)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
            }
            .disabled(isPurchasing)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
    
    private var iconColor: Color {
        switch product.type {
        case .gems: return .cyan
        case .subscription: return .yellow
        case .booster: return .orange
        case .cosmetic: return .pink
        }
    }
}

#Preview {
    StoreView()
}

