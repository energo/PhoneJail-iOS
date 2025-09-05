//
//  PomodoroSectionView.swift
//  AntiSocial
//
//  Created by Assistant on 2025.
//

import SwiftUI
import FamilyControls

struct PomodoroSectionView: View {
    @StateObject private var viewModel = PomodoroViewModel()
    @State private var showingSettings = false
    @State private var showingTimer = false
    
    private let adaptive = AdaptiveValues.current

    var body: some View {
        contentView
            .blurBackground()
            .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal)
                .padding(.vertical, adaptive.spacing.medium)
            
            if !viewModel.isRunning {
                // When not running, show duration selector and start button
                VStack(spacing: adaptive.spacing.large) {
                    // Duration Selector
                    durationSelectorView
                        .padding(.horizontal)
                    
                    // Description
                    descriptionView
                        .padding(.horizontal)
                    
                    // Start Button
                    startButton
                        .padding(.horizontal)
                        .padding(.bottom, adaptive.spacing.large)
                }
            } else {
                // When running, show circular timer
                VStack(spacing: adaptive.spacing.medium) {
                    // Circular Timer
                    CircularTimerView(
                        totalTime: TimeInterval(viewModel.selectedMinutes * 60),
                        remainingTime: TimeInterval(viewModel.remainingSeconds),
                        isActive: viewModel.isRunning && !viewModel.isPaused,
                        timerType: viewModel.currentSessionType == .focus ? .focus : .breakTime,
                        size: 220
                    )
                    .padding(.vertical, adaptive.spacing.large)
                    
                    // Session Info
                    sessionStatusView
                        .padding(.horizontal)
                    
                    // Control Buttons
                    controlButtons
                        .padding(.horizontal)
                        .padding(.bottom, adaptive.spacing.large)
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Image("ic_nav_pomodoro")
                .resizable()
                .adaptiveFrame(width: \.iconMedium, height: \.iconMedium)
                .foregroundColor(.white)
            
            Text("Pomodoro Focus")
                .adaptiveFont(\.title2)
                .foregroundColor(.white)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Stats Badge
            if viewModel.currentSession > 1 || viewModel.isRunning {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(viewModel.currentSession)/\(viewModel.totalSessions)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
            }
        }
    }
    
    private var durationSelectorView: some View {
        VStack(spacing: adaptive.spacing.medium) {
            // Quick presets
            HStack(spacing: adaptive.spacing.small) {
                presetButton(minutes: 15, label: "Quick")
                presetButton(minutes: 25, label: "Pomodoro")
                presetButton(minutes: 45, label: "Deep")
                presetButton(minutes: 60, label: "Long")
            }
            
            // Custom duration slider
            VStack(alignment: .leading, spacing: adaptive.spacing.small) {
                HStack {
                    Text("Custom Duration")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Text("\(viewModel.selectedMinutes) min")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.selectedMinutes) },
                        set: { viewModel.selectedMinutes = Int($0) }
                    ),
                    in: 5...120,
                    step: 5
                )
                .accentColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func presetButton(minutes: Int, label: String) -> some View {
        Button(action: {
            viewModel.selectedMinutes = minutes
            HapticManager.shared.selection()
        }) {
            VStack(spacing: 6) {
                Text("\(minutes)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(viewModel.selectedMinutes == minutes ? .black : .white)
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(viewModel.selectedMinutes == minutes ? .black.opacity(0.7) : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.selectedMinutes == minutes ? Color.white : Color.white.opacity(0.1))
            )
        }
    }
    
    private var descriptionView: some View {
        VStack(spacing: adaptive.spacing.medium) {
            // What gets blocked
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Apps to Block")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                    
                    // Show selected apps or "All Apps" text
                    if viewModel.selectionActivity.applicationTokens.isEmpty && 
                       viewModel.selectionActivity.categoryTokens.isEmpty {
                        Text("All Apps")
                            .foregroundColor(.white.opacity(0.9))
                            .font(.system(size: 13, weight: .medium))
                    } else {
                        HStack(spacing: 8) {
                            if !viewModel.selectionActivity.applicationTokens.isEmpty {
                                AppTokensView(
                                    tokens: viewModel.selectionActivity.applicationTokens,
                                    iconSize: 18,
                                    showCount: false,
                                    spacing: 2
                                )
                            }
                            
                            if !viewModel.selectionActivity.categoryTokens.isEmpty {
                                CategoryTokensView(
                                    tokens: viewModel.selectionActivity.categoryTokens,
                                    iconSize: 18, showCount: false,
                                    spacing: 2
                                )
                            }
                            
                            // Show count if more than 4 apps
                            let totalCount = viewModel.selectionActivity.applicationTokens.count + 
                                           viewModel.selectionActivity.categoryTokens.count
                            if totalCount > 4 {
                                Text("+\(totalCount - 4)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Text("Change")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Features
            HStack(spacing: adaptive.spacing.large) {
                featureTag(icon: "bell", text: "Notifications", enabled: viewModel.notificationsEnabled)
                featureTag(icon: "speaker.wave.2", text: "Sound", enabled: viewModel.soundEnabled)
                featureTag(icon: "arrow.triangle.2.circlepath", text: "Auto-cycle", enabled: viewModel.autoStartNextSession)
            }
        }
        .sheet(isPresented: $showingSettings) {
            PomodoroSettingsView(isPresented: $showingSettings, viewModel: viewModel)
        }
    }
    
    private func featureTag(icon: String, text: String, enabled: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(enabled ? .green : .gray)
            
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(enabled ? .white.opacity(0.8) : .gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(enabled ? 0.1 : 0.05))
        .clipShape(Capsule())
    }
    
    private var sessionStatusView: some View {
        VStack(spacing: adaptive.spacing.small) {
            // Session type indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.currentSessionType == .focus ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.currentSessionType == .focus ? "Focus Time" : "Break Time")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                if viewModel.isPaused {
                    Text("(Paused)")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                }
            }
            
            // Apps blocked status
            if viewModel.currentSessionType == .focus || viewModel.blockDuringBreak {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("Apps blocked")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var startButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                viewModel.startPomodoro()
            }
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 18))
                
                Text("Start Focus Session")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: Color.white.opacity(0.25), radius: 10, x: 0, y: 5)
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: adaptive.spacing.medium) {
            // Pause/Resume button
            Button(action: {
                withAnimation {
                    viewModel.togglePause()
                }
            }) {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            
            // Stop button
            Button(action: {
                withAnimation {
                    viewModel.stopPomodoro()
                }
            }) {
                HStack {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16))
                    
                    Text("End Session")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.red.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            
            // Skip button (for break to next focus)
            if viewModel.currentSessionType == .breakTime {
                Button(action: {
                    withAnimation {
                        viewModel.skipToNextFocus()
                    }
                }) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    Circle()
                                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
            }
        }
    }
    
    private var separatorView: some View {
        SeparatorView()
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        PomodoroSectionView()
            .padding()
    }
    .background(Color.black)
}
