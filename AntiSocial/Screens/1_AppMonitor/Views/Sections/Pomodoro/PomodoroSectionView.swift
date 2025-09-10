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
  @State private var showingAppPicker = false
  
  private let adaptive = AdaptiveValues.current
  
  private let circleSize = UIScreen.main.bounds.width * 0.8
  private let circleProgressSize = UIScreen.main.bounds.width * 0.08
  
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
      
      if viewModel.allSessionsCompleted {
        // Completed state - all sessions done
        completedStateView
      } else if !viewModel.isRunning {
        // Inactive state - show setup
        inactiveStateView
      } else if viewModel.currentSessionType == .focus {
        // Active focus state
        activeFocusStateView
      } else {
        // Break state
        breakStateView
      }
      
      Spacer()

      // Statistics at bottom
      statisticsView
        .padding(.bottom, adaptive.spacing.xLarge)

    }
  }
  
  // MARK: - State Views
  
  private var inactiveStateView: some View {
    VStack(spacing: 0) {
      // Large Circular Timer with everything inside
      CircularTimerView(
        totalTime: TimeInterval(viewModel.focusDuration * 60),
        remainingTime: TimeInterval(viewModel.focusDuration * 60), // Full time when inactive
        isActive: false,
        isPaused: false,
        timerType: .focus,
        size: circleSize,
        strokeWidth: circleProgressSize,
        showConfirmationDialog: viewModel.showStartFocusDialog,
        confirmationDialog: startFocusDialog
      ) {
        VStack(spacing: adaptive.spacing.medium) {
          // Apps to block display
          blockedAppsDisplay
          
          // Start button inside the circle
          startFocusButton
        }
      }
    }
  }
  
  private var activeFocusStateView: some View {
    VStack(spacing: 0) {
      
      // Large Circular Timer with controls inside
      CircularTimerView(
        totalTime: TimeInterval(viewModel.focusDuration * 60),
        remainingTime: TimeInterval(viewModel.remainingSeconds),
        isActive: viewModel.isRunning,
        isPaused: viewModel.isPaused,
        timerType: .focus,
        size: circleSize,
        strokeWidth: circleProgressSize,
        showConfirmationDialog: viewModel.showStartFocusDialog || viewModel.showStopSessionDialog,
        confirmationDialog: viewModel.showStartFocusDialog ? startFocusDialog : (viewModel.showStopSessionDialog ? stopSessionDialog : nil)
      ) {
        activeInnerContentView
      }
    }
  }
  
  private var activeInnerContentView: some View {
    VStack(spacing: adaptive.spacing.medium) {
      blockedAppsDisplay
      controlButtonsView
    }
  }
  
  private var controlButtonsView: some View {
    HStack(spacing: 0) {
      Spacer()
        .frame(maxWidth: .infinity)

       // Left side - skip to break
       Button(action: {
         viewModel.skipToBreak()
         HapticManager.shared.impact(style: .medium)
       }) {
        Image(systemName: "cup.and.heat.waves.fill")
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.8))
          .frame(width: 24, height: 24)
          .background(
            Circle()
              .stroke(Color.as_gradietn_stroke, lineWidth: 2)
          )
      }
      
        // Pause/Resume button
      Button(action: {
        HapticManager.shared.impact(style: .medium)
        viewModel.togglePause()
      }) {
          Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
            .font(.system(size: 24))
            .foregroundColor(.white)
            .frame(width: 88, height: 50)
            .background(
              Capsule()
                .stroke(Color.as_gradietn_stroke, lineWidth: 2)
            )
        }
        .padding(.horizontal, 8)
        
        // Stop button - close to main button
        Button(action: {
          viewModel.requestStopPomodoro()
          HapticManager.shared.impact(style: .medium)
        }) {
          Image(systemName: "stop.fill")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.8))
            .frame(width: 24, height: 24)
            .background(
              Circle()
                .stroke(Color.as_gradietn_stroke, lineWidth: 2)
            )
        }
      
      Spacer()
        .frame(maxWidth: .infinity)
    }
  }
  
  private var breakStateView: some View {
    VStack(spacing: 0) {
      // Large Circular Timer with controls inside
      CircularTimerView(
        totalTime: TimeInterval(viewModel.breakDuration * 60),
        remainingTime: TimeInterval(viewModel.remainingSeconds),
        isActive: viewModel.isRunning,
        isPaused: viewModel.isPaused,
        timerType: .breakTime,
        size: circleSize,
        strokeWidth: circleProgressSize,
        showConfirmationDialog: viewModel.showStopBreakDialog,
        confirmationDialog: viewModel.showStopBreakDialog ? stopBreakDialog : nil
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
          controlButtonsBkeakView
        }
      }
    }
  }
  
  private var controlButtonsBkeakView: some View {
    HStack(spacing: 0) {
      Color.clear
        .frame(width: 24, height: 24)
      
      Spacer()
        .frame(maxWidth: .infinity)

       Button(action: {
         viewModel.requestStopBreak()
         HapticManager.shared.impact(style: .medium)
       }) {
        Image(systemName: "stop.fill")
          .font(.system(size: 24))
          .foregroundColor(.white)
          .frame(width: 88, height: 50)
          .background(
            Capsule()
              .stroke(Color.as_gradietn_stroke, lineWidth: 2)
          )
      }
      .padding(.horizontal, 8)
      
      Button(action: {
        viewModel.skipToNextFocus()
        HapticManager.shared.impact(style: .light)
      }) {
        Image(systemName: "forward.fill")
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.8))
          .frame(width: 24, height: 24)
          .background(
            Circle()
              .stroke(Color.as_gradietn_stroke, lineWidth: 2)
          )
      }
      
      Spacer()
        .frame(maxWidth: .infinity)
    }
  }
  
  private var completedStateView: some View {
    VStack(spacing: 0) {
      Spacer()
      
      // Large Circular Timer showing completion
      CircularTimerView(
        totalTime: TimeInterval(viewModel.breakDuration * 60),
        remainingTime: 0, // Full circle for completed state
        isActive: false,
        isPaused: false,
        timerType: .focus,
        size: circleSize,
        strokeWidth: circleProgressSize,
        showConfirmationDialog: viewModel.showBreakEndDialog,
        confirmationDialog: breakEndDialog
      ) {
        VStack(spacing: adaptive.spacing.large) {
          // Checkmark icon
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 30))
            .foregroundColor(.green)
          
          // Start new cycle button
          Button(action: {
            viewModel.allSessionsCompleted = false
            viewModel.currentSession = 1
            HapticManager.shared.notification(type: .success)
          }) {
            Text("Start New Cycle")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(.white)
              .frame(width: 160, height: 44)
              .background(
                Capsule()
                  .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
              )
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
      Button(action: {
        HapticManager.shared.impact(style: .medium)
        showingSettings = true
      }) {
        HStack(spacing: 8) {
          Text("Customize")
            .font(.system(size: 12, weight: .regular))
          Image(systemName: "gearshape.fill")
            .font(.system(size: 14))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 13)
        .background(
          Capsule()
            .fill(Color.white.opacity(0.07))
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
        .font(.system(size: 24))
        .foregroundColor(.white)
        .frame(width: 88, height: 50)
        .background(
          Capsule()
            .stroke(Color.as_gradietn_stroke, lineWidth: 2)
        )
    }
  }
  
  private var blockedAppsDisplay: some View {
    Button(action: {
      showingAppPicker = true
      HapticManager.shared.impact(style: .light)
    }) {
      HStack(spacing: 8) {
        
        // Show up to 3 app icons
        if !viewModel.selectionActivity.applicationTokens.isEmpty || !viewModel.selectionActivity.categoryTokens.isEmpty
        {
          UnifiedTokensView(
            familyActivitySelection: viewModel.selectionActivity,
            maxIcons: 3,
            showCount: false,
            tokenTypes: [.applications, .categories]
          )
        }
        
        let totalCount = viewModel.selectionActivity.applicationTokens.count +
        viewModel.selectionActivity.categoryTokens.count
        if totalCount > 0 {
          Text("+\(totalCount)")
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Color.white)
            .padding(.leading, 8)
        } else {
          Text("All Apps")
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Color.white)
        }
        
        Spacer()
          .frame(maxWidth: 8)
        
        Image(systemName: "chevron.right")
          .foregroundColor(Color.as_white_light)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(
        Capsule()
          .fill(Color.white.opacity(0.07))
      )
    }
    .buttonStyle(PlainButtonStyle())
    .familyActivityPicker(
      isPresented: $showingAppPicker,
      selection: $viewModel.selectionActivity
    )
    .onChange(of: viewModel.selectionActivity) { _ in
      // Auto-save when selection changes
      viewModel.saveSettings()
    }
  }
  
  private var statisticsView: some View {
    HStack(spacing: 0) {
      // Lifetime
      VStack(spacing: 8) {
        Text("Lifetime")
          .font(.system(size: 20, weight: .medium))
          .foregroundColor(Color.as_white_light)
        
        Text(formatTime(viewModel.lifetimeFocusTime))
          .font(.system(size: 16, weight: .regular))
          .foregroundColor(.white)
      }
      .frame(maxWidth: .infinity)
      
      // Weekly
      VStack(spacing: 8) {
        Text("Weekly")
          .font(.system(size: 20, weight: .medium))
          .foregroundColor(Color.as_white_light)

        Text(formatTime(viewModel.weeklyFocusTime))
          .font(.system(size: 16, weight: .regular))
          .foregroundColor(.white)
      }
      .frame(maxWidth: .infinity)
      
      // Today
      VStack(spacing: 8) {
        Text("Today")
          .font(.system(size: 20, weight: .medium))
          .foregroundColor(Color.as_white_light)

        Text(formatTime(viewModel.todayFocusTime))
          .font(.system(size: 16, weight: .regular))
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
  
  // MARK: - Dialogs
  private var startFocusDialog: PomodoroConfirmationDialog {
    let appsText = viewModel.blockAllCategories ? "All" : "Selected"
    return PomodoroConfirmationDialog(
      dialogType: .startFocus,
      customMessage: "\(appsText) apps will be blocked for the next \(viewModel.focusDuration) minutes?",
      onCancel: {
        viewModel.cancelStartFocus()
      },
      onConfirm: {
        viewModel.confirmStartFocus()
      }
    )
  }
  
  private var breakEndDialog: PomodoroConfirmationDialog {
    PomodoroConfirmationDialog(
      dialogType: .breakEnd,
      customMessage: "Ready to start another \(viewModel.focusDuration) minutes focus session?",
      onCancel: {
        viewModel.cancelBreakEnd()
      },
      onConfirm: {
        viewModel.confirmBreakEnd()
      }
    )
  }
  
  private var stopSessionDialog: PomodoroConfirmationDialog {
    PomodoroConfirmationDialog(
      dialogType: .stopSession,
      customMessage: "Are you sure you want to leave early?",
      onCancel: {
        viewModel.cancelStopSession()
      },
      onConfirm: {
        viewModel.confirmStopSession()
      }
    )
  }
  
  private var stopBreakDialog: PomodoroConfirmationDialog {
    PomodoroConfirmationDialog(
      dialogType: .stopBreak,
      customMessage: "Are you sure you want to leave early?",
      onCancel: {
        viewModel.cancelStopBreak()
      },
      onConfirm: {
        viewModel.confirmStopBreak()
      }
    )
  }
}

// MARK: - Preview
#Preview {
  BGView {
      ScrollView {
        PomodoroSectionView()
          .padding()
      }
  }
}
