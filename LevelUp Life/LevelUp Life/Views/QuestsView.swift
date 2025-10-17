//
//  QuestsView.swift
//  LevelUp Life
//
//  Quest management and history
//

import SwiftUI

struct QuestsView: View {
    @StateObject private var viewModel = AppViewModel.shared
    @State private var selectedFilter: QuestFilter = .today
    @State private var showAddQuest = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(QuestFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Quest List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredQuests) { quest in
                            QuestDetailCard(quest: quest)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Quests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddQuest = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
            }
            .sheet(isPresented: $showAddQuest) {
                EnhancedAddQuestView()
            }
        }
    }
    
    private var filteredQuests: [Quest] {
        switch selectedFilter {
        case .today:
            return viewModel.dailyQuests
        case .upcoming:
            return viewModel.dailyQuests.filter { $0.status == .active }
        case .completed:
            return viewModel.completedQuestsToday
        }
    }
}

enum QuestFilter: String, CaseIterable {
    case today = "Today"
    case upcoming = "Active"
    case completed = "Completed"
}

struct QuestDetailCard: View {
    let quest: Quest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: quest.category.icon)
                    .font(.title2)
                    .foregroundColor(categoryColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.headline)
                    
                    Text(quest.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: quest.status)
            }
            
            if let description = quest.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                Label("\(quest.baseXP) XP", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Label("\(quest.baseGold) Gold", systemImage: "dollarsign.circle.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Spacer()
                
                Label(quest.difficulty.rawValue, systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(difficultyColor)
            }
            
            if quest.isOnCooldown() {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("On cooldown")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
    
    private var categoryColor: Color {
        switch quest.category {
        case .fitness: return .green
        case .focus: return .blue
        case .knowledge: return .purple
        case .social: return .pink
        case .wellbeing: return .orange
        }
    }
    
    private var difficultyColor: Color {
        switch quest.difficulty {
        case .easy: return .green
        case .standard: return .blue
        case .hard: return .purple
        }
    }
}

struct StatusBadge: View {
    let status: QuestStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status {
        case .active: return .blue
        case .completed: return .green
        case .failed: return .red
        case .archived: return .gray
        }
    }
}

#Preview {
    QuestsView()
}

