//
//  MainTabView.swift
//  LevelUp Life
//
//  Main tab navigation
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = AppViewModel.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            QuestsView()
                .tabItem {
                    Label("Quests", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(1)
            
            RPMAvatarView()
                .tabItem {
                    Label("Avatar", systemImage: "person.circle.fill")
                }
                .tag(2)
            
            VStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("Boosters")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Coming Soon!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .tabItem {
                Label("Boosters", systemImage: "bolt.fill")
            }
            .tag(3)
            
            ChestView()
                .tabItem {
                    Label("Chest", systemImage: "gift.fill")
                }
                .tag(4)
            
            EnhancedStoreView()
                .tabItem {
                    Label("Store", systemImage: "cart.fill")
                }
                .tag(5)
            
            SocialView()
                .tabItem {
                    Label("Social", systemImage: "person.3.fill")
                }
                .tag(6)
            
            DeveloperToolsView()
                .tabItem {
                    Label("Dev Tools", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(7)
        }
        .accentColor(.purple)
        .overlay {
            // Reward animation
            if viewModel.showRewardAnimation {
                RewardAnimationView(rewards: viewModel.lastRewards) {
                    viewModel.showRewardAnimation = false
                }
            }
            
            // Level up modal
            if viewModel.showLevelUpModal {
                LevelUpModalView(newLevel: viewModel.levelUpNewLevel) {
                    viewModel.showLevelUpModal = false
                }
            }
            
            // Achievement toast
            if let achievement = viewModel.showAchievement {
                AchievementModalView(achievement: achievement) {
                    viewModel.showAchievement = nil
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}

