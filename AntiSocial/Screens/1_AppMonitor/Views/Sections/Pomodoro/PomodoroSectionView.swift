//
//  PomodoroSectionView.swift
//  AntiSocial
//
//  Created by Assistant on 2025.
//

import SwiftUI

struct PomodoroSectionView: View {
    @StateObject private var viewModel = PomodoroViewModel()
    @State private var showingPresetPicker = false
    
  private let adaptive = AdaptiveValues.current

    var body: some View {
        contentView
            .blurBackground()
            .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
            // Header
            headerView
                .padding(.horizontal)
                .padding(.top)
            
            separatorView
                .padding(.horizontal)
            
            // Timer display or duration selection
            if viewModel.isRunning {
                timerView
                    .padding(.horizontal)
                    .padding(.vertical)
            } else {
                durationSelectionView
                    .padding(.horizontal)
            }
            
            separatorView
                .padding(.horizontal)
            
            // Description
            descriptionView
                .padding(.horizontal)
            
            separatorView
                .padding(.horizontal)
            
            // Start/Stop button
            actionButton
                .padding(.horizontal)
                .padding(.bottom)
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
        }
    }
    
    private var timerView: some View {
        VStack(spacing: adaptive.spacing.small) {
            Text("Focus Time Remaining")
                .adaptiveFont(\.headline)
                .foregroundColor(Color.as_gray_light)
            
            Text(viewModel.timeRemaining)
                .font(.system(size: AdaptiveDeviceCategory.current.isCompact ? 48 : 60, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text("All apps are blocked")
                .adaptiveFont(\.subheadline)
                .foregroundColor(Color.as_gray_light)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, adaptive.spacing.large)
    }
    
    private var durationSelectionView: some View {
        VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
            Text("Select Focus Duration")
                .foregroundColor(.white)
                .adaptiveFont(\.body)
            
            // Quick presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: adaptive.spacing.small) {
                    ForEach(viewModel.presetOptions, id: \.self) { minutes in
                        presetButton(minutes: minutes)
                    }
                }
            }
            
            // Custom duration selector
            HStack {
                Text("Duration:")
                    .foregroundColor(.white)
                    .adaptiveFont(\.body)
                
                Spacer()
                
                HStack(spacing: adaptive.spacing.xSmall) {
                    Text("\(viewModel.selectedMinutes)")
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 50)
                    
                    Text("min")
                        .foregroundColor(Color.as_gray_light)
                        .adaptiveFont(\.body)
                }
                
                Stepper("", value: $viewModel.selectedMinutes, in: 5...120, step: 5)
                    .labelsHidden()
            }
            .padding(.horizontal, adaptive.spacing.medium)
            .padding(.vertical, adaptive.spacing.small)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func presetButton(minutes: Int) -> some View {
        Button(action: {
            viewModel.selectedMinutes = minutes
        }) {
            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(viewModel.selectedMinutes == minutes ? .black : .white)
                
                Text("min")
                    .adaptiveFont(\.caption2)
                    .foregroundColor(viewModel.selectedMinutes == minutes ? .black.opacity(0.7) : Color.as_gray_light)
            }
            .frame(width: 60, height: 60)
            .background(
                viewModel.selectedMinutes == minutes ?
                Color.white : Color.white.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: adaptive.spacing.small) {
            Label {
                Text("Blocks all apps immediately")
                    .foregroundColor(Color.as_gray_light)
                    .adaptiveFont(\.subheadline)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.orange)
                    .adaptiveFrame(width: \.iconSmall, height: \.iconSmall)
            }
            
            Label {
                Text("Auto-unblocks when timer ends")
                    .foregroundColor(Color.as_gray_light)
                    .adaptiveFont(\.subheadline)
            } icon: {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.green)
                    .adaptiveFrame(width: \.iconSmall, height: \.iconSmall)
            }
            
            Label {
                Text("Perfect for focused work sessions")
                    .foregroundColor(Color.as_gray_light)
                    .adaptiveFont(\.subheadline)
            } icon: {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .adaptiveFrame(width: \.iconSmall, height: \.iconSmall)
            }
        }
        .padding(.vertical, adaptive.spacing.small)
    }
    
    private var actionButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.togglePomodoro()
            }
        }) {
            HStack {
                Image(systemName: viewModel.isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Text(viewModel.isRunning ? "Stop Focus" : "Start Focus")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(viewModel.isRunning ? .white : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                viewModel.isRunning ?
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.red],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.white.opacity(0.9), Color.white],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: viewModel.isRunning ? Color.red.opacity(0.3) : Color.white.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .scaleEffect(viewModel.isRunning ? 1.02 : 1.0)
    }
    
    private var separatorView: some View {
        SeparatorView()
    }
}
