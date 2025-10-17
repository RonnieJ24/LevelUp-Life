//
//  ProfileView.swift
//  LevelUp Life
//
//  User profile, stats, and settings
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = AppViewModel.shared
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = viewModel.currentUser {
                        // Profile Header
                        ProfileHeaderView(user: user)
                            .padding(.horizontal)
                        
                        // Stats Grid
                        StatsGridView(user: user)
                            .padding(.horizontal)
                        
                        // Progress Section
                        ProgressSection(user: user)
                            .padding(.horizontal)
                        
                        // Settings Button
                        Button(action: { showSettings = true }) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Settings & Privacy")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .shadow(color: .purple.opacity(0.5), radius: 20, x: 0, y: 10)
                
                Image(systemName: user.classId.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(spacing: 8) {
                Text(user.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(user.classId.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    VStack {
                        Text("Level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(user.level)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack {
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Text("\(user.streak)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack {
                        Text("Trust Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(user.trustScore))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct StatsGridView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resources")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "dollarsign.circle.fill",
                    color: .yellow,
                    title: "Gold",
                    value: "\(user.currencies.gold)"
                )
                
                StatCard(
                    icon: "diamond.fill",
                    color: .cyan,
                    title: "Gems",
                    value: "\(user.currencies.gems)"
                )
                
                StatCard(
                    icon: "ticket.fill",
                    color: .orange,
                    title: "Tickets",
                    value: "\(user.currencies.tickets)"
                )
                
                StatCard(
                    icon: "star.fill",
                    color: .purple,
                    title: "Total XP",
                    value: "\(user.xp)"
                )
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ProgressSection: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Level Progress")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Level \(user.level)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(user.xp) / \(user.xpForNextLevel()) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: user.levelProgress())
                    .tint(.purple)
                    .frame(height: 8)
                
                Text("\(Int(user.levelProgress() * 100))% to Level \(user.level + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AppViewModel.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var showHealthKitPermission = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Permissions") {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("HealthKit")
                        Spacer()
                        if healthKitManager.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button("Enable") {
                                showHealthKitPermission = true
                            }
                        }
                    }
                    
                    Button(action: {
                        // Mock notification setup
                        HapticManager.shared.notification(.success)
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Notifications")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section("Preferences") {
                    Toggle(isOn: .constant(true)) {
                        Text("Haptic Feedback")
                    }
                    
                    Toggle(isOn: .constant(true)) {
                        Text("Sound Effects")
                    }
                    
                    Toggle(isOn: .constant(true)) {
                        Text("Share on Social Feed")
                    }
                }
                
                Section("Developer") {
                    NavigationLink(destination: DeveloperToolsView()) {
                        Label("Developer Tools", systemImage: "hammer.fill")
                    }
                }
                
                Section("Account") {
                    Button("Export Data") {
                        // TODO: Export user data
                    }
                    
                    Button("Delete Account", role: .destructive) {
                        // TODO: Delete account confirmation
                    }
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Enable HealthKit", isPresented: $showHealthKitPermission) {
                Button("Cancel", role: .cancel) {}
                Button("Enable") {
                    Task {
                        try? await healthKitManager.requestAuthorization()
                    }
                }
            } message: {
                Text("Connect HealthKit to automatically verify workouts, steps, and sleep for bonus XP and higher trust score.")
            }
        }
    }
}

#Preview {
    ProfileView()
}

