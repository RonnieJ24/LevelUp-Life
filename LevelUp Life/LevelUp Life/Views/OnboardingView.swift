//
//  OnboardingView.swift
//  LevelUp Life
//
//  Onboarding flow with class selection and first quest
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = AppViewModel.shared
    @State private var currentStep = 0
    @State private var displayName = ""
    @State private var selectedClass: LifeClass = .adventurer
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            TabView(selection: $currentStep) {
                WelcomeStep()
                    .tag(0)
                
                NameStep(displayName: $displayName)
                    .tag(1)
                
                ClassSelectionStep(selectedClass: $selectedClass)
                    .tag(2)
                
                FirstQuestStep(
                    displayName: displayName,
                    selectedClass: selectedClass
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 100))
                .foregroundColor(.purple)
                .shadow(color: .purple, radius: 30)
            
            Text("LevelUp Life")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            Text("Turn your daily habits into an epic RPG adventure")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                FeatureRow(icon: "star.fill", text: "Earn XP and level up", color: .purple)
                FeatureRow(icon: "gift.fill", text: "Unlock epic rewards", color: .cyan)
                FeatureRow(icon: "flame.fill", text: "Build powerful streaks", color: .orange)
                FeatureRow(icon: "person.3.fill", text: "Compete with friends", color: .pink)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct NameStep: View {
    @Binding var displayName: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("What should we call you?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Choose your hero name")
                .font(.title3)
                .foregroundColor(.gray)
            
            TextField("Hero Name", text: $displayName)
                .font(.title2)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .autocapitalization(.words)
                .textContentType(.name)
            
            Spacer()
        }
        .padding()
    }
}

struct ClassSelectionStep: View {
    @Binding var selectedClass: LifeClass
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Choose Your Path")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select a class that matches your goals")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(LifeClass.allCases, id: \.self) { lifeClass in
                        ClassCard(
                            lifeClass: lifeClass,
                            isSelected: selectedClass == lifeClass
                        ) {
                            selectedClass = lifeClass
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct ClassCard: View {
    let lifeClass: LifeClass
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: lifeClass.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.purple : Color.white.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(lifeClass.rawValue)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(lifeClass.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.purple.opacity(0.3) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct FirstQuestStep: View {
    let displayName: String
    let selectedClass: LifeClass
    @StateObject private var viewModel = AppViewModel.shared
    @State private var showConfetti = false
    @State private var hasCompleted = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if !hasCompleted {
                VStack(spacing: 20) {
                    Text("Your First Quest")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Complete this to start your journey!")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "scroll.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("Begin Your Journey")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Welcome to LevelUp Life, \(displayName)!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        
                        Button(action: completeFirstQuest) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Complete Quest")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow, radius: 30)
                    
                    Text("Quest Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You earned your first rewards!")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 12) {
                        RewardBadge(icon: "star.fill", text: "+50 XP", color: .purple)
                        RewardBadge(icon: "dollarsign.circle.fill", text: "+100 Gold", color: .yellow)
                        RewardBadge(icon: "diamond.fill", text: "+10 Gems", color: .cyan)
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
        .overlay {
            if showConfetti {
                ConfettiView()
            }
        }
    }
    
    private func completeFirstQuest() {
        hasCompleted = true
        showConfetti = true
        
        // Create user after 1 second to show rewards
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            viewModel.createNewUser(displayName: displayName, selectedClass: selectedClass)
        }
    }
}

struct RewardBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { index in
                Circle()
                    .fill(Color.random)
                    .frame(width: CGFloat.random(in: 4...8))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animate ? UIScreen.main.bounds.height + 20 : -20
                    )
                    .animation(
                        .linear(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
        .allowsHitTesting(false)
    }
}

extension Color {
    static var random: Color {
        [.red, .blue, .green, .yellow, .purple, .orange, .pink].randomElement() ?? .purple
    }
}

#Preview {
    OnboardingView()
}

