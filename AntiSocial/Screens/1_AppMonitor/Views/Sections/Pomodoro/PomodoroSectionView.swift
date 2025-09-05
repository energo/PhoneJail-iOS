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
    @State private var showCompletionAnimation = false
    
    
    private let adaptive = AdaptiveValues.current

    var body: some View {
        contentView
//            .blurBackground()
            .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentSessionType)
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal)
                .padding(.vertical, adaptive.spacing.medium)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            if !viewModel.isRunning {
                // Inactive state - show setup
                inactiveStateView
            } else if viewModel.currentSessionType == .focus {
                // Active focus state
                activeFocusStateView
            } else {
                // Break state
                breakStateView
            }
        }
    }
    
    // MARK: - State Views
    
    private var inactiveStateView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: adaptive.spacing.xLarge)
            
            // Circular Timer with apps display
            ZStack {
                // Timer
                CircularTimerView(
                    totalTime: TimeInterval(viewModel.focusDuration * 60),
                    remainingTime: TimeInterval(viewModel.focusDuration * 60), // Full time when inactive
                    isActive: false,
                    timerType: .focus,
                    size: 280
                )
                
                // Apps to block overlay
                VStack {
                    Spacer()
                    blockedAppsDisplay
                        .offset(y: -40)
                }
            }
            .frame(height: 280)
            .padding(.vertical, adaptive.spacing.large)
            
            // Start button
            startFocusButton
                .padding(.top, adaptive.spacing.medium)
            
            Spacer()
            
            // Statistics
            statisticsView
                .padding(.horizontal)
                .padding(.bottom, adaptive.spacing.xLarge)
        }
    }
    
    private var activeFocusStateView: some View {
        VStack(spacing: 0) {
            // Session progress
            HStack {
                Text("Session \(viewModel.currentSession) of \(viewModel.totalSessions)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, adaptive.spacing.medium)
            
            // Circular Timer
            CircularTimerView(
                totalTime: TimeInterval(viewModel.focusDuration * 60),
                remainingTime: TimeInterval(viewModel.remainingSeconds),
                isActive: viewModel.isRunning && !viewModel.isPaused,
                timerType: .focus,
                size: 240
            )
            .padding(.vertical, adaptive.spacing.xLarge)

            // Focus label
            VStack(spacing: 8) {
                Text("FOCUS TIME")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
                    .tracking(1.5)
                
                Text("Stay focused and productive")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, adaptive.spacing.large)
            
            // Control buttons
            HStack(spacing: adaptive.spacing.large) {
                // Pause/Resume
                Button(action: { viewModel.togglePause() }) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
                
                // Stop
                Button(action: { 
                    viewModel.stopPomodoro()
                  HapticManager.shared.impact(style: .medium)
                }) {
                    Text("End Session")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 140, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.bottom, adaptive.spacing.xLarge)
        }
    }
    
    private var breakStateView: some View {
        VStack(spacing: 0) {
            // Session progress
            HStack {
                Text("Break after session \(viewModel.currentSession)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, adaptive.spacing.medium)
            
            // Circular Timer
            CircularTimerView(
                totalTime: TimeInterval(viewModel.breakDuration * 60),
                remainingTime: TimeInterval(viewModel.remainingSeconds),
                isActive: viewModel.isRunning && !viewModel.isPaused,
                timerType: .breakTime,
                size: 240
            )
            .padding(.vertical, adaptive.spacing.xLarge)
            
            // Break label
            VStack(spacing: 8) {
                Text("BREAK TIME")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
                    .tracking(1.5)
                
                Text("Relax and recharge")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, adaptive.spacing.large)
            
            // Control buttons
            HStack(spacing: adaptive.spacing.large) {
                // Skip to next focus
                Button(action: { 
                    viewModel.skipToNextFocus()
                  HapticManager.shared.impact(style: .light)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.fill")
                        Text("Skip to Focus")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 160, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.green.opacity(0.2))
                    )
                }
                
                // End break  
                Button(action: { 
                    viewModel.stopPomodoro()
                }) {
                    Text("End")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 80, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .padding(.bottom, adaptive.spacing.xLarge)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: adaptive.spacing.medium) {
            HStack {
              Spacer()

                Image("ic_nav_pomodoro")
                    .resizable()
                    .adaptiveFrame(width: \.iconMedium, height: \.iconMedium)
                    .foregroundColor(.white)
                
                Text("Pomodoro Blocker")
                    .adaptiveFont(\.title2)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Customize button
            Button(action: { showingSettings = true }) {
                HStack(spacing: 8) {
                    Text("Customize")
                        .font(.system(size: 16, weight: .medium))
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            PomodoroSettingsView(isPresented: $showingSettings, viewModel: viewModel)
        }
    }
        
    private var startFocusButton: some View {
        Button(action: {
            viewModel.selectedMinutes = viewModel.focusDuration
            viewModel.startPomodoro()
            HapticManager.shared.notification(type: .success)
        }) {
            Image(systemName: "play.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 120, height: 60)
                .background(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
        }
    }
    
    private var blockedAppsDisplay: some View {
        HStack(spacing: -8) {
            // Show up to 3 app icons
            if !viewModel.selectionActivity.applicationTokens.isEmpty {
                AppTokensView(
                    tokens: viewModel.selectionActivity.applicationTokens,
                    maxIcons: 3,
                    iconSize: 28,
                    overlap: -10, showCount: false
                )
            }
            
            if !viewModel.selectionActivity.categoryTokens.isEmpty {
                CategoryTokensView(
                    tokens: viewModel.selectionActivity.categoryTokens,
                    maxIcons: 3,
                    iconSize: 28,
                    overlap: -10, showCount: false
                )
            }
            
            // Show count
            let totalCount = viewModel.selectionActivity.applicationTokens.count + 
                           viewModel.selectionActivity.categoryTokens.count
            if totalCount > 0 {
                HStack(spacing: 4) {
                    Text("+\(totalCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.leading, 8)
            } else {
                Text("All Apps")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    private var statisticsView: some View {
        HStack(spacing: 0) {
            // Lifetime
            VStack(spacing: 8) {
                Text("Lifetime")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(formatTime(viewModel.lifetimeFocusTime))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            
            // Weekly
            VStack(spacing: 8) {
                Text("Weekly")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(formatTime(viewModel.weeklyFocusTime))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            
            // Today
            VStack(spacing: 8) {
                Text("Today")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(formatTime(viewModel.todayFocusTime))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, adaptive.spacing.medium)
        .padding(.horizontal)
        .blurBackground()
      }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            return "\(seconds / 60)m"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        }
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
