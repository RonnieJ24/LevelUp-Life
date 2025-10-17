//
//  EnhancedAddQuestView.swift
//  LevelUp Life
//
//  Enhanced quest creation with proof options
//

import SwiftUI
import PhotosUI

struct EnhancedAddQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AppViewModel.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Category = .fitness
    @State private var selectedDifficulty: Difficulty = .standard
    @State private var proofType: ProofType = .manual
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingTemplates = true
    
    enum ProofType: String, CaseIterable {
        case manual = "Manual"
        case photo = "Photo"
        case timer = "Timer"
        case healthKit = "HealthKit"
        
        var icon: String {
            switch self {
            case .manual: return "hand.raised.fill"
            case .photo: return "camera.fill"
            case .timer: return "timer"
            case .healthKit: return "heart.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Templates vs Custom toggle
                Section {
                    Picker("Mode", selection: $showingTemplates) {
                        Text("Templates").tag(true)
                        Text("Custom").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                
                if showingTemplates {
                    // Show quest templates
                    Section("Quick Start") {
                        Text("Choose a pre-made quest template")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "list.bullet.clipboard")
                                Text("Browse Templates")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                } else {
                    // Custom quest creation
                    Section("Quest Details") {
                        TextField("Quest Title", text: $title)
                            .font(.headline)
                        
                        TextField("Description (optional)", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.subheadline)
                    }
                    
                    Section("Category") {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Label {
                                    Text(category.rawValue)
                                } icon: {
                                    Image(systemName: category.icon)
                                        .foregroundColor(categoryColor(category))
                                }
                                .tag(category)
                            }
                        }
                        
                        Text(selectedCategory.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Section("Difficulty") {
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                Text(difficulty.rawValue).tag(difficulty)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        HStack {
                            Text("XP Reward:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("+\(calculateXP()) XP")
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                        }
                        .font(.caption)
                    }
                    
                    Section("Verification Method") {
                        Picker("Proof Type", selection: $proofType) {
                            ForEach(ProofType.allCases, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        
                        switch proofType {
                        case .manual:
                            Text("Tap to complete when done")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        case .photo:
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.badge.plus")
                                    Text("Add Proof Photo (optional)")
                                    Spacer()
                                }
                            }
                        case .timer:
                            Text("Start a focus timer to track progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        case .healthKit:
                            Text("Auto-verify with HealthKit data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section {
                        Button(action: createQuest) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Create Quest")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.purple)
                        .disabled(title.isEmpty)
                    }
                }
            }
            .navigationTitle("Add Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func categoryColor(_ category: Category) -> Color {
        switch category {
        case .fitness: return .green
        case .focus: return .blue
        case .knowledge: return .purple
        case .social: return .pink
        case .wellbeing: return .orange
        }
    }
    
    private func calculateXP() -> Int {
        let base = 50
        let multiplier: Double
        
        switch selectedDifficulty {
        case .easy: multiplier = 0.7
        case .standard: multiplier = 1.0
        case .hard: multiplier = 1.5
        }
        
        return Int(Double(base) * multiplier)
    }
    
    private func createQuest() {
        guard let user = viewModel.currentUser else { return }
        
        let newQuest = Quest(
            userId: user.id,
            title: title,
            description: description.isEmpty ? nil : description,
            difficulty: selectedDifficulty,
            category: selectedCategory,
            verificationType: verificationTypeForProof(),
            signalsRequired: signalsForProof()
        )
        
        viewModel.dailyQuests.append(newQuest)
        
        HapticManager.shared.notification(.success)
        SoundManager.shared.play(.questComplete)
        
        dismiss()
    }
    
    private func verificationTypeForProof() -> VerificationType {
        switch proofType {
        case .manual: return .manual
        case .photo: return .photo
        case .timer: return .timer
        case .healthKit: return .healthKit
        }
    }
    
    private func signalsForProof() -> [VerificationSignal] {
        switch proofType {
        case .manual: return []
        case .photo: return [.photoProof]
        case .timer: return [.timerCompletion]
        case .healthKit: return selectedCategory == .fitness ? [.healthWorkout] : []
        }
    }
}

extension Category {
    var description: String {
        switch self {
        case .fitness: return "Physical activities and workouts"
        case .focus: return "Deep work and concentration"
        case .knowledge: return "Learning and skill development"
        case .social: return "Relationships and connections"
        case .wellbeing: return "Mental health and self-care"
        }
    }
}

#Preview {
    EnhancedAddQuestView()
}




