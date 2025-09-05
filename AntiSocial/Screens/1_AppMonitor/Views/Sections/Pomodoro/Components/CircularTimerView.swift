//
//  CircularTimerView.swift
//  AntiSocial
//
//  Created by Assistant on current date.
//

import SwiftUI

struct CircularTimerView: View {
    // MARK: - Properties
    let totalTime: TimeInterval
    let remainingTime: TimeInterval
    let isActive: Bool
    let timerType: TimerType
    let size: CGFloat
    
    @State private var animateProgress = false
    
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
        ZStack {
            // Background circle with blur effect similar to blurBackground
            Circle()
                .fill(Color.clear)
                .frame(width: size, height: size)
                .overlay(
                    ZStack {
                        // Use BackdropBlurView for blur effect
                        BackdropBlurView(isBlack: false, radius: 10)
                            .clipShape(Circle())
                        
                        // White overlay for consistency with blurBackground
                        Circle()
                            .fill(Color.white.opacity(0.07))
                    }
                )
            
            // Background circle stroke
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: 10
                )
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animateProgress ? progress : 0)
                .stroke(
                    LinearGradient(
                        colors: timerType.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 10,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
                .shadow(color: timerType.color.opacity(0.5), radius: 8)
            
            // Inner content
            VStack(spacing: 4) {
                // Timer text only - big and bold
                Text(timeText)
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
            }
        }
        .onAppear {
            withAnimation {
                animateProgress = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            CircularTimerView(
                totalTime: 1500,
                remainingTime: 900,
                isActive: true,
                timerType: .focus,
                size: 250
            )
            
            CircularTimerView(
                totalTime: 300,
                remainingTime: 150,
                isActive: true,
                timerType: .breakTime,
                size: 200
            )
        }
    }
}