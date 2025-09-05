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
                return Color.as_red
            case .breakTime:
                return Color(hex: "4CAF50") // Green color for break
            }
        }
        
        var gradientColors: [Color] {
            switch self {
            case .focus:
                return [Color.as_red, Color.as_red.opacity(0.8)]
            case .breakTime:
                return [Color(hex: "4CAF50"), Color(hex: "81C784")]
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
            // Background circle
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: size * 0.08
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
                        lineWidth: size * 0.08,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
                .shadow(color: timerType.color.opacity(0.3), radius: 10)
            
            // Inner content
            VStack(spacing: size * 0.02) {
                // Session type
                Text(sessionText)
                    .font(.system(size: size * 0.06, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
                
                // Timer text
                Text(timeText)
                    .font(.system(size: size * 0.15, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                // Status indicator
                if isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(timerType.color)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animateProgress ? 1.2 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: animateProgress
                            )
                        
                        Text("Active")
                            .font(.system(size: size * 0.05, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            // Decorative elements
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(index % 3 == 0 ? 0.3 : 0.1))
                    .frame(width: 2, height: index % 3 == 0 ? size * 0.04 : size * 0.02)
                    .offset(y: -size * 0.45)
                    .rotationEffect(.degrees(Double(index) * 30))
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