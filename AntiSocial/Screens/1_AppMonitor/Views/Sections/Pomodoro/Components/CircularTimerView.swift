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
  let timerType: TimerType
  let size: CGFloat
  let strokeWidth: CGFloat
  let content: Content?
  
  @State private var animateProgress = false
  
  init(totalTime: TimeInterval,
       remainingTime: TimeInterval,
       isActive: Bool,
       timerType: TimerType,
       size: CGFloat,
       strokeWidth: CGFloat = 10,
       @ViewBuilder content: () -> Content? = { nil }) {
    self.totalTime = totalTime
    self.remainingTime = remainingTime
    self.isActive = isActive
    self.timerType = timerType
    self.size = size
    self.strokeWidth = strokeWidth
    self.content = content()
  }
  
  enum TimerType {
    case focus
    case breakTime
    
    var color: Color {
      switch self {
        case .focus:
          return Color(red: 1.0, green: 0.2, blue: 0.2) // Bright red
        case .breakTime:
          return Color(red: 0.2, green: 0.9, blue: 0.4) // Bright green
      }
    }
    
    var gradientColors: [Color] {
      switch self {
        case .focus:
          return [Color(red: 1.0, green: 0.2, blue: 0.2), Color(red: 0.9, green: 0.1, blue: 0.1)]
        case .breakTime:
          return [Color(red: 0.2, green: 0.9, blue: 0.4), Color(red: 0.1, green: 0.8, blue: 0.3)]
      }
    }
    
  }
  
  private var progress: Double {
    guard totalTime > 0 else { return 0 }
    return (totalTime - remainingTime) / totalTime
  }
  
  private var timeText: String {
    let minutes = Int(remainingTime) / 60
    let seconds = Int(remainingTime) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
  
  private var sessionText: String {
    switch timerType {
      case .focus:
        return "Focus Time"
      case .breakTime:
        return "Break Time"
    }
  }
  
  // MARK: - Body
  var body: some View {
    let trackSize = size - strokeWidth/2 // Track circle size
    let progressStrokeWidth = strokeWidth * 0.4
    let progressSize = trackSize * 0.98
    
    ZStack {
      // Layer 1: Outermost background circle with blur effect
      backgroundCircle
      
      // Layer 2: Track circle (gray stroke)
      trackCircle(size: trackSize)
      
      // Layer 3: Progress circle (centered inside track)
      progressCircle(size: progressSize, strokeWidth: progressStrokeWidth, fullSize: size)
      
      // Inner content
      innerContentView
    }
    .onAppear {
      withAnimation {
        animateProgress = true
      }
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
  
  private func progressCircle(size: CGFloat, strokeWidth: CGFloat, fullSize: CGFloat) -> some View {
    // Progress stroke
    Circle()
      .trim(from: 0, to: animateProgress ? progress : 0)
      .stroke(
        Color.as_gradient_pomodoro_focus_progress,
        style: StrokeStyle(
          lineWidth: strokeWidth,
          lineCap: .round  // Changed from .round to not interfere with end circle
        )
      )
      .frame(width: size, height: size)
      .rotationEffect(.degrees(-90))
      .animation(.easeInOut(duration: 0.5), value: progress)
      .shadow(color: timerType.color.opacity(0.5), radius: 8)
      .overlay(
        // End circle indicator as overlay to ensure proper positioning
        progressEndCircle(progressSize: size)
      )
  }
  
  private func progressEndCircle(progressSize: CGFloat) -> some View {
    GeometryReader { geometry in
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
      .opacity(progress > 0 ? 1 : 0)
      .animation(.easeInOut(duration: 0.5), value: progress)
    }
  }
  
  private var innerContentView: some View {
    VStack(spacing: 0) {
      // Timer text at top
      Text(timeText)
        .font(.system(size: min(size * 0.22, 50),
                      weight: .bold, design: .rounded))
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
        .padding(.top, size * 0.15)
      
      // Custom content below timer if provided
      if let content = content {
        Spacer()
        content
        Spacer()
      }
    }
    .frame(width: size - strokeWidth * 4,
           height: size - strokeWidth * 4)
  }
}

// MARK: - Preview
#Preview {
  BGView {
    VStack(spacing: 40) {
      CircularTimerView(
        totalTime: 1500,
        remainingTime: 900,
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
