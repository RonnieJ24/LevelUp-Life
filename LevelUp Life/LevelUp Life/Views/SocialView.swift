//
//  SocialView.swift
//  LevelUp Life
//
//  Social features: guilds, leaderboards, friends
//

import SwiftUI

struct SocialView: View {
    @State private var selectedTab: SocialTab = .leaderboard
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Social", selection: $selectedTab) {
                    ForEach(SocialTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    LeaderboardView()
                        .tag(SocialTab.leaderboard)
                    
                    GuildView()
                        .tag(SocialTab.guild)
                    
                    FriendsView()
                        .tag(SocialTab.friends)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Social")
        }
    }
}

enum SocialTab: String, CaseIterable {
    case leaderboard = "Leaderboard"
    case guild = "Guild"
    case friends = "Friends"
}

struct LeaderboardView: View {
    @StateObject private var viewModel = AppViewModel.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top Players Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Players")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(Array(topPlayers.enumerated()), id: \.element.id) { index, player in
                            PlayerRow(player: player, rank: index + 1)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Your Rank Section
                if let currentUser = viewModel.currentUser {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Rank")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        PlayerRow(player: currentUser, rank: currentUserRank)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var topPlayers: [User] {
        // Mock data for now
        return [
            User(id: "1", displayName: "ProGamer", level: 25, xp: 15000),
            User(id: "2", displayName: "QuestMaster", level: 23, xp: 13500),
            User(id: "3", displayName: "LevelUpKing", level: 22, xp: 12000),
            User(id: "4", displayName: "XPCollector", level: 21, xp: 11000),
            User(id: "5", displayName: "AchievementHunter", level: 20, xp: 10000)
        ]
    }
    
    private var currentUserRank: Int {
        // Mock rank calculation
        return 42
    }
}

struct PlayerRow: View {
    let player: User
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rank <= 3 ? .yellow : .primary)
                .frame(width: 40, alignment: .leading)
            
            // Avatar placeholder
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(player.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Level \(player.level) • \(player.xp) XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Medal for top 3
            if rank <= 3 {
                Image(systemName: rank == 1 ? "crown.fill" : rank == 2 ? "medal.fill" : "medal")
                    .font(.title2)
                    .foregroundColor(rank == 1 ? .yellow : rank == 2 ? .gray : .orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct GuildView: View {
    @StateObject private var viewModel = AppViewModel.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let guild = viewModel.currentGuild {
                    GuildCard(guild: guild)
                        .padding(.horizontal)
                } else {
                    NoGuildView()
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct NoGuildView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("No Guild Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Join or create a guild to compete in team challenges!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Create Guild")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {}) {
                    Text("Find Guild")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(10)
                }
            }
        }
        .padding(30)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct GuildCard: View {
    let guild: Guild
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading) {
                    Text(guild.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("\(guild.memberIds.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let rank = guild.leaderboardRank {
                    VStack {
                        Text("#\(rank)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        Text("Rank")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Weekly Goal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(guild.teamXP) / \(guild.weeklyGoal) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: guild.goalProgress)
                    .tint(.purple)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

struct FriendsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Friends")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Connect with friends and see their progress!\nComing soon...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    SocialView()
}

