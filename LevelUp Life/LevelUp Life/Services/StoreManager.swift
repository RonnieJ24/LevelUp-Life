//
//  StoreManager.swift
//  LevelUp Life
//
//  StoreKit 2 integration for IAP
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    
    // Product IDs (these would be configured in App Store Connect)
    private let productIDs = [
        // Gem Packs
        "com.leveluplife.gems.small",
        "com.leveluplife.gems.medium",
        "com.leveluplife.gems.large",
        "com.leveluplife.gems.mega",
        
        // Subscription
        "com.leveluplife.pro.monthly",
        "com.leveluplife.pro.annual",
        
        // Boosters
        "com.leveluplife.booster.xp",
        "com.leveluplife.booster.streaksaver",
        
        // Cosmetics
        "com.leveluplife.cosmetic.bundle1",
        "com.leveluplife.cosmetic.bundle2"
    ]
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        
        do {
            // In a real app, these products would be fetched from App Store Connect
            // For now, we'll create mock product data
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
            products = []
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Deliver the purchased content
            await deliverPurchase(transaction)
            
            // Finish the transaction
            await transaction.finish()
            
            return transaction
            
        case .userCancelled, .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                await deliverPurchase(transaction)
            } catch {
                print("Restore failed: \(error)")
            }
        }
    }
    
    // MARK: - Check Purchase Status
    
    func checkPurchased(_ product: Product) async throws -> Bool {
        guard let state = try await product.subscription?.status.first else {
            // Not a subscription
            return purchasedProductIDs.contains(product.id)
        }
        
        switch state.state {
        case .subscribed, .inGracePeriod:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func deliverPurchase(_ transaction: Transaction) async {
        purchasedProductIDs.insert(transaction.productID)
        
        // Deliver content based on product type
        await MainActor.run {
            deliverContent(for: transaction.productID, to: AppViewModel.shared)
        }
    }
    
    private func deliverContent(for productID: String, to viewModel: AppViewModel) {
        guard var user = viewModel.currentUser else { return }
        
        // Gems
        if productID.contains("gems.small") {
            user.currencies.gems += 100
        } else if productID.contains("gems.medium") {
            user.currencies.gems += 300
        } else if productID.contains("gems.large") {
            user.currencies.gems += 800
        } else if productID.contains("gems.mega") {
            user.currencies.gems += 2000
        }
        
        // Subscription (Pro)
        else if productID.contains("pro") {
            // Grant pro benefits
        }
        
        // Boosters
        else if productID.contains("streaksaver") {
            // Add streak saver to inventory
        }
        
        viewModel.currentUser = user
        viewModel.saveUserData()
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { @MainActor in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.deliverPurchase(transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Mock Products for Development
    
    func createMockProducts() {
        // This is for UI development only
        // Real products would come from App Store Connect
    }
    
    enum StoreError: Error {
        case failedVerification
    }
}

// MARK: - Store Product Models

struct StoreProduct: Identifiable {
    let id = UUID()
    let productID: String
    let name: String
    let description: String
    let price: String
    let type: ProductType
    let icon: String
    let gems: Int?
    
    enum ProductType {
        case gems
        case subscription
        case booster
        case cosmetic
    }
}

// Mock store data for UI
extension StoreManager {
    static var mockProducts: [StoreProduct] {
        [
            StoreProduct(
                productID: "gems.small",
                name: "Small Gem Pack",
                description: "100 Gems",
                price: "$1.99",
                type: .gems,
                icon: "diamond.fill",
                gems: 100
            ),
            StoreProduct(
                productID: "gems.medium",
                name: "Medium Gem Pack",
                description: "300 Gems",
                price: "$4.99",
                type: .gems,
                icon: "diamond.fill",
                gems: 300
            ),
            StoreProduct(
                productID: "gems.large",
                name: "Large Gem Pack",
                description: "800 Gems + 50 Bonus",
                price: "$9.99",
                type: .gems,
                icon: "diamond.fill",
                gems: 850
            ),
            StoreProduct(
                productID: "pro.monthly",
                name: "LevelUp Pro",
                description: "Monthly subscription with premium benefits",
                price: "$7.99/mo",
                type: .subscription,
                icon: "crown.fill",
                gems: nil
            ),
            StoreProduct(
                productID: "booster.streaksaver",
                name: "Streak Saver",
                description: "Protect your streak for one missed day",
                price: "$0.99",
                type: .booster,
                icon: "shield.fill",
                gems: nil
            )
        ]
    }
}

