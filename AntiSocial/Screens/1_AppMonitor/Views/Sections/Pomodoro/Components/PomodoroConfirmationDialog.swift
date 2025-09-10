//
//  PomodoroConfirmationDialog.swift
//  AntiSocial
//
//  Created by Assistant on current date.
//

import SwiftUI

enum PomodoroDialogType {
    case startFocus
    case breakEnd
    case stopSession
    
    var title: String {
        switch self {
        case .startFocus:
            return "Ready to start?"
        case .breakEnd:
            return "Leave early?"
        case .stopSession:
            return "Stop session?"
        }
    }
    
    var confirmButtonTitle: String {
        return "Confirm"
    }
}

struct PomodoroConfirmationDialog: View {
    let dialogType: PomodoroDialogType
    var customMessage: String? = nil
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            // Blur background covering the entire inner circle
            Circle()
                .fill(Color.clear)
                .background(
                    BackdropBlurView(isBlack: false, radius: 10)
                        .clipShape(Circle())
                )
            
            // Dialog content
            VStack(spacing: 16) {
              
              Spacer()
                .frame(maxHeight: 20)

                // Title
//                Text(dialogType.title)
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.white)
//                    .multilineTextAlignment(.center)
//                    .lineLimit(2)
                
                // Custom message if provided
                if let customMessage = customMessage {
                    Text(customMessage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
              Spacer()
                .frame(maxHeight: 30)
              
                // Buttons
                HStack(spacing: 12) {
                    // Cancel button
                    Button(action: {
                        HapticManager.shared.impact(style: .light)
                        onCancel()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 36)
                            .background(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.pink.opacity(0.6), Color.blue.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    
                    // Confirm button
                    Button(action: {
                        HapticManager.shared.impact(style: .medium)
                        onConfirm()
                    }) {
                        Text(dialogType.confirmButtonTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 36)
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Background circle to simulate CircularTimerView
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.8)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .frame(width: 300, height: 300)
        
        // Dialog overlay
        PomodoroConfirmationDialog(
            dialogType: .startFocus,
            customMessage: "Ready to start another 25 minute focus session?",
            onCancel: {},
            onConfirm: {}
        )
    }
    .background(Color.black)
}
