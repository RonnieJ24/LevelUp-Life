//
//  FocusTimerView.swift
//  LevelUp Life
//
//  Focus timer for deep work sessions
//

import SwiftUI
import Combine

struct FocusTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timerManager = FocusTimerManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Timer Display
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 20)
                            .frame(width: 280, height: 280)
                        
                        Circle()
                            .trim(from: 0, to: timerManager.progress)
                            .stroke(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: timerManager.progress)
                        
                        VStack(spacing: 8) {
                            Text(timerManager.timeString)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if timerManager.isRunning {
                                Text("Stay Focused")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // Controls
                    VStack(spacing: 20) {
                        if !timerManager.isRunning && timerManager.timeRemaining == 0 {
                            // Duration Selection
                            VStack(spacing: 16) {
                                Text("Select Duration")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 12) {
                                    DurationButton(minutes: 25, label: "Pomodoro", icon: "⚡️") {
                                        timerManager.setDuration(minutes: 25)
                                    }
                                    
                                    DurationButton(minutes: 45, label: "Standard", icon: "💪") {
                                        timerManager.setDuration(minutes: 45)
                                    }
                                    
                                    DurationButton(minutes: 90, label: "Deep Work", icon: "🧠") {
                                        timerManager.setDuration(minutes: 90)
                                    }
                                }
                            }
                        }
                        
                        // Start/Pause/Resume Button
                        if timerManager.timeRemaining > 0 {
                            Button(action: {
                                if timerManager.isRunning {
                                    timerManager.pause()
                                } else {
                                    timerManager.start()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                                        .font(.title3)
                                    Text(timerManager.isRunning ? "Pause" : (timerManager.hasStarted ? "Resume" : "Start"))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(width: 200, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(30)
                            }
                            
                            // Reset Button
                            Button(action: {
                                timerManager.reset()
                            }) {
                                Text("Reset")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Focus Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Focus Session Complete!", isPresented: $timerManager.showCompletionAlert) {
                Button("Great!") {
                    // TODO: Award XP for focus session
                    dismiss()
                }
            } message: {
                Text("You stayed focused for \(timerManager.sessionDuration) minutes! 🎉")
            }
        }
    }
}

struct DurationButton: View {
    let minutes: Int
    let label: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.largeTitle)
                
                Text("\(minutes)m")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

// MARK: - Focus Timer Manager

class FocusTimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var isRunning = false
    @Published var hasStarted = false
    @Published var showCompletionAlert = false
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: Date?
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var sessionDuration: Int {
        return Int(totalDuration / 60)
    }
    
    func setDuration(minutes: Int) {
        totalDuration = TimeInterval(minutes * 60)
        timeRemaining = totalDuration
    }
    
    func start() {
        guard timeRemaining > 0 else { return }
        
        isRunning = true
        hasStarted = true
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        isRunning = false
        pausedTime = Date()
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        isRunning = false
        hasStarted = false
        timeRemaining = 0
        totalDuration = 0
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard timeRemaining > 0 else {
            complete()
            return
        }
        
        timeRemaining -= 1
    }
    
    private func complete() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        showCompletionAlert = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    FocusTimerView()
}

