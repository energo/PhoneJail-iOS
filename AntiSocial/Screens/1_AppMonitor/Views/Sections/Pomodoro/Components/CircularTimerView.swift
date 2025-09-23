//
//  CircularTimerView.swift
//  AntiSocial
//
//  Created by Assistant on current date.
//

import SwiftUI

struct CircularTimerView<Content: View>: View {
  // MARK: - Properties
  let totalTime: TimeInterval
  let remainingTime: TimeInterval
  let isActive: Bool
  let isPaused: Bool
  let timerType: TimerType
  let size: CGFloat
  let strokeWidth: CGFloat
  let content: Content?
  let showConfirmationDialog: Bool
  let confirmationDialog: PomodoroConfirmationDialog?
  
  var onTimeSelected: ((Int) -> Void)?
  @State private var showTimePicker: Bool = false
  @State private var timePickerValue: Int
  
  init(totalTime: TimeInterval,
       remainingTime: TimeInterval,
       isActive: Bool,
       isPaused: Bool = false,
       timerType: TimerType,
       size: CGFloat,
       strokeWidth: CGFloat = 10,
       showConfirmationDialog: Bool = false,
       confirmationDialog: PomodoroConfirmationDialog? = nil,
       @ViewBuilder content: () -> Content? = { nil }) {
    self.totalTime = totalTime
    self.timePickerValue = Int(totalTime) / 60
    self.remainingTime = remainingTime
    self.isActive = isActive
    self.isPaused = isPaused
    self.timerType = timerType
    self.size = size
    self.strokeWidth = strokeWidth
    self.showConfirmationDialog = showConfirmationDialog
    self.confirmationDialog = confirmationDialog
    self.content = content()
  }
  
  enum TimerType {
    case focus
    case focusCompleted

    case breakTime
    case breakTimeCompleted
    
    var color: Color {
      switch self {
        case .focus, .focusCompleted:
          return Color(red: 1.0, green: 0.2, blue: 0.2) // Bright red
        case .breakTime, .breakTimeCompleted:
          return Color(red: 0.2, green: 0.9, blue: 0.4) // Bright green
      }
    }
    
    var gradientColors: [Color] {
      switch self {
        case .focus, .focusCompleted:
          return [Color(red: 1.0, green: 0.2, blue: 0.2), Color(red: 0.9, green: 0.1, blue: 0.1)]
        case .breakTime, .breakTimeCompleted:
          return [Color(red: 0.2, green: 0.9, blue: 0.4), Color(red: 0.1, green: 0.8, blue: 0.3)]
      }
    }
    
  }
  
  private var progress: Double {
    guard totalTime > 0 else { return 0 }
    let progressValue = remainingTime / totalTime
    print("🍅 CircularTimerView: totalTime = \(totalTime), remainingTime = \(remainingTime), progress = \(progressValue)")
    return progressValue
  }
  
  private var timeText: String {
    let minutes = Int(remainingTime) / 60
    let seconds = Int(remainingTime) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
  
  private var sessionText: String {
    switch timerType {
      case .focus, .focusCompleted:
        return "Focus Time"
      case .breakTime, .breakTimeCompleted:
        return "Break Time"
    }
  }
  
  private var progressGradient: LinearGradient {
    switch timerType {
      case .focus, .focusCompleted:
        return Color.as_gradient_pomodoro_focus_progress
      case .breakTime, .breakTimeCompleted:
        return Color.as_gradient_pomodoro_break_progress
    }
  }
  
  // MARK: - Body
  var body: some View {
    let trackSize = size - strokeWidth/3 // Track circle size
    let progressStrokeWidth = strokeWidth * 0.4
    let progressSize = trackSize - strokeWidth * 0.6 // Progress circle slightly smaller to be inside track
    
    ZStack {
      // Layer 1: Outermost background circle with blur effect
      backgroundCircle
      
      // Layer 2: Track circle (gray stroke)
      trackCircle(size: trackSize)
      
      // Inner content or dialog overlay
      if showConfirmationDialog, let dialog = confirmationDialog {
        // Dialog is inside trackCircle
        dialog
          .frame(width: trackSize - strokeWidth, height: trackSize - strokeWidth)
      } else {
        // Normal inner content
        innerContentView
      }
      
      // Layer 3: Progress circle (inside track)
      progressCircle(size: progressSize,
                     strokeWidth: progressStrokeWidth,
                     fullSize: size,
                     trackSize: trackSize,
                     progressSize: progressSize)
    }
  }
  
  private var backgroundCircle: some View {
    Circle()
      .fill(Color.clear)
      .frame(width: size, height: size)
      .overlay(
        Circle().fill(Color.white.opacity(0.07))
      )
  }
  
  private func trackCircle(size: CGFloat) -> some View {
    Circle()
      .stroke(
        Color.white.opacity(0.05),
        lineWidth: strokeWidth
      )
      .frame(width: size, height: size)
  }
  
  private func progressCircle(size: CGFloat, strokeWidth: CGFloat, fullSize: CGFloat, trackSize: CGFloat, progressSize: CGFloat) -> some View {
    // Progress stroke - animating from full circle (1.0) to empty (0.0)
    Circle()
      .trim(from: 0, to: isActive ? progress : 1)
      .stroke(
        progressGradient,
        style: StrokeStyle(
          lineWidth: strokeWidth,
          lineCap: .round
        )
      )
      .frame(width: size, height: size)
      .rotationEffect(.degrees(-90))
      .animation(isActive ? (isPaused ? .none : .linear(duration: 1.0)) : .none, value: progress)  // No animation when inactive
      .shadow(color: timerType.color.opacity(0.5), radius: 8)
      .overlay(
        // End circle indicator as overlay to ensure proper positioning
        progressEndCircle(progressSize: progressSize, trackSize: trackSize)
      )
  }
  
  private func progressEndCircle(progressSize: CGFloat, trackSize: CGFloat) -> some View {
    GeometryReader { geometry in
      // Calculate angle for the end of the progress arc (where the indicator should be)
      // progress represents remaining time (1.0 to 0.0), so the indicator should be at the end of the arc
      let angle = 2 * .pi * progress - .pi / 2
      // Calculate position on the progress circle's radius
      let radius = progressSize / 2
      let centerX = geometry.size.width / 2
      let centerY = geometry.size.height / 2
      let x = centerX + cos(angle) * radius
      let y = centerY + sin(angle) * radius
      
      ZStack {
        // Outer circle (22pt)
        Circle()
          .fill(Color.white)
          .frame(width: 22, height: 22)
          .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        
        // Inner circle (16pt) 
        Circle()
          .fill(
            LinearGradient(
              colors: timerType.gradientColors,
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 16, height: 16)
      }
      .position(x: x, y: y)
      .opacity(isActive && progress > 0 ? 1 : 0)  // Show only when timer is active and there's remaining time
      .animation(isPaused ? .none : .linear(duration: 1.0), value: progress)  // No animation when paused
    }
  }
  
  private var shouldShowTimerText: Bool {
      switch timerType {
      case .focusCompleted, .breakTimeCompleted:
          return false
      default:
          return true
      }
  }

  private var innerContentView: some View {
    VStack(spacing: 0) {
      if shouldShowTimerText {
          timerTextView
          .onTapGesture {
            if onTimeSelected != nil {
              withAnimation(.easeInOut(duration: 0.3)) {
                showTimePicker = true
              }
            }
          }
      }
      
      // Custom content below timer if provided
      if showTimePicker {
        Spacer()
        timePickerView
      } else if let content = content {
        Spacer()
        content
        Spacer()
      }
      
    }
    .frame(width: size - strokeWidth * 4,
           height: size - strokeWidth * 4)
  }
  
  private var timePickerView: some View {
    VStack(spacing: 16) {
      CustomPickerView(
        actualValue: .init(
          get: { timePickerValue },
          set: { timePickerValue = $0 }
        ),
        fromValue: 2, toValue: 60,
        spacing: 0,
        steps: 1, valueStep: 1,
        style: .styleSlim
      )
      
      Button {
        onTimeSelected?(timePickerValue)
        withAnimation(.easeInOut(duration: 0.3)) {
          showTimePicker = false
        }
      } label: {
        Text("Save")
          .font(.system(size: 16, weight: .regular))
          .foregroundColor(.white)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .frame(height: 42)
          .background(Color.as_gradient_pomodoro_focus_progress)
          .clipShape(RoundedRectangle(cornerRadius: 21))
      }
    }
  }
  
  private var timerTextView: some View {
    // Timer text at top
    let minutes = onTimeSelected != nil ? timePickerValue : Int(remainingTime) / 60
    let seconds = onTimeSelected != nil ? 0 : Int(remainingTime) % 60
    let minuteTens = minutes / 10
    let minuteOnes = minutes % 10
    let secondTens = seconds / 10
    let secondOnes = seconds % 10
    
    let pointSize: CGFloat = 34
    var boxWidth: CGFloat { pointSize * 0.804 }
    
    // Helper function to check if digit is narrow (odd numbers are typically narrower)
    func isNarrowDigit(_ digit: Int) -> Bool {
      return digit == 1
    }
    
    func isMediumNarrowDigit(_ digit: Int) -> Bool {
      return digit == 7
    }
    
    return HStack(alignment: .center, spacing: 2) {
      // Минуты
      Spacer()

      Text("\(minuteTens)")
        .font(Font.primary(weight: .digital, size: .big))
        .foregroundColor(.white)
        .frame(width: boxWidth, alignment: .center)
      
      Text("\(minuteOnes)")
        .font(Font.primary(weight: .digital, size: .big))
        .foregroundColor(.white)
        .frame(width: boxWidth, alignment: .center)

      
      // Двоеточие — в этом шрифте тоже моноширинное
      Text(":")
        .font(Font.primary(weight: .digital, size: .big))
        .foregroundColor(.white)
        .frame(width: 20, alignment: .center)
        .offset(x: -4)
      
      // Секунды
        Text("\(secondTens)")
          .font(Font.primary(weight: .digital, size: .big))
          .foregroundColor(.white)
          .frame(width: boxWidth, alignment: .center)
          .offset(x: isNarrowDigit(secondTens) ? -15 : 0)
        
        Text("\(secondOnes)")
          .font(Font.primary(weight: .digital, size: .big))
          .foregroundColor(.white)
          .frame(width: boxWidth, alignment: .center)
          .offset(x: isNarrowDigit(secondTens) ? -10 : isNarrowDigit(secondOnes) ? -0 : 0)
      Spacer()
    }
    .padding(.trailing, 6)
    .padding(.top, size * (showTimePicker ? 0.0 : 0.15))
    // TODO: - CircularTimerView paddings need to be refactored
  }
}

// MARK: - Preview
#Preview {
  BGView {
    VStack(spacing: 40) {
      CircularTimerView(
        totalTime: 1500,
        remainingTime: 570,
        isActive: true,
        timerType: .focus,
        size: 300,
        strokeWidth: 28
      ) {
        VStack {
          Text("Focus Session")
            .foregroundColor(.white.opacity(0.7))
          Button("Pause") {}
            .foregroundColor(.white)
        }
      }
      
      //            CircularTimerView(
      //                totalTime: 300,
      //                remainingTime: 150,
      //                isActive: true,
      //                timerType: .breakTime,
      //                size: 200,
      //                strokeWidth: 10
      //            ) {
      //            }
    }
  }
}
