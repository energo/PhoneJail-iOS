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
  
  private let circleSize = UIScreen.main.bounds.width * 0.7
  private let circleProgressSize = UIScreen.main.bounds.width * 0.07
  
  var body: some View {
    contentView
      .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
      .animation(.easeInOut(duration: 0.3), value: viewModel.currentSessionType)
  }
  
  private var contentView: some View {
    VStack(spacing: 0) {
      // Header
      headerView
        .padding(.horizontal)
        .padding(.vertical, adaptive.spacing.medium)
        .padding(.top)

      Spacer()
      
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
      
      // Large Circular Timer with everything inside
      CircularTimerView(
        totalTime: TimeInterval(viewModel.focusDuration * 60),
        remainingTime: TimeInterval(viewModel.focusDuration * 60), // Full time when inactive
        isActive: false,
        timerType: .focus,
        size: circleSize,
        strokeWidth: circleProgressSize
      ) {
        VStack(spacing: adaptive.spacing.medium) {
          // Apps to block display
          blockedAppsDisplay
          
          // Start button inside the circle
          startFocusButton
        }
      }
      
      Spacer()
      
      // Statistics at bottom
      statisticsView
        .padding(.bottom, adaptive.spacing.xLarge)
    }
  }
  
  private var activeFocusStateView: some View {
    VStack(spacing: 0) {
      Spacer()
      
      // Large Circular Timer with controls inside
      CircularTimerView(
        totalTime: TimeInterval(viewModel.focusDuration * 60),
        remainingTime: TimeInterval(viewModel.remainingSeconds),
        isActive: viewModel.isRunning && !viewModel.isPaused,
        timerType: .focus,
        size: circleSize,
        strokeWidth: circleProgressSize
      ) {
        VStack(spacing: adaptive.spacing.medium) {
          // Session info
          Text("Session \(viewModel.currentSession) of \(viewModel.totalSessions)")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
          
          // Control buttons
          HStack(spacing: adaptive.spacing.medium) {
            // Pause/Resume
            Button(action: { viewModel.togglePause() }) {
              Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                  Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
            }
            
            // Stop
            Button(action: {
              viewModel.stopPomodoro()
              HapticManager.shared.impact(style: .medium)
            }) {
              Image(systemName: "stop.fill")
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 50, height: 50)
                .background(
                  Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
            }
          }
        }
      }
      
      Spacer()
      
      // Statistics at bottom
      statisticsView
        .padding(.bottom, adaptive.spacing.xLarge)
    }
  }
  
  private var breakStateView: some View {
    VStack(spacing: 0) {
      Spacer()
      
      // Large Circular Timer with controls inside
      CircularTimerView(
        totalTime: TimeInterval(viewModel.breakDuration * 60),
        remainingTime: TimeInterval(viewModel.remainingSeconds),
        isActive: viewModel.isRunning && !viewModel.isPaused,
        timerType: .breakTime,
        size: circleSize,
        strokeWidth: circleProgressSize
      ) {
        VStack(spacing: adaptive.spacing.medium) {
          // Break info
          VStack(spacing: 4) {
            Text("BREAK TIME")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(.green)
              .tracking(1.5)
            
            Text("After session \(viewModel.currentSession)")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.white.opacity(0.6))
          }
          
          // Control buttons
          HStack(spacing: adaptive.spacing.medium) {
            // Skip to next focus
            Button(action: {
              viewModel.skipToNextFocus()
              HapticManager.shared.impact(style: .light)
            }) {
              Image(systemName: "forward.fill")
                .font(.system(size: 22))
                .foregroundColor(.green)
                .frame(width: 50, height: 50)
                .background(
                  Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                )
            }
            
            // Stop
            Button(action: {
              viewModel.stopPomodoro()
            }) {
              Image(systemName: "stop.fill")
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 50, height: 50)
                .background(
                  Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
            }
          }
        }
      }
      
      Spacer()
      
      // Statistics at bottom
      statisticsView
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
          overlap: -10,
          showCount: false
        )
      }
      
      if !viewModel.selectionActivity.categoryTokens.isEmpty {
        CategoryTokensView(
          tokens: viewModel.selectionActivity.categoryTokens,
          maxIcons: 3,
          iconSize: 28,
          overlap: -10,
          showCount: false
        )
      }
      
      // Show count
      let totalCount = viewModel.selectionActivity.applicationTokens.count +
      viewModel.selectionActivity.categoryTokens.count
      if totalCount > 0 {
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
