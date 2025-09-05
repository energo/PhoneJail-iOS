//
//  PomodoroSettingsView.swift
//  AntiSocial
//
//  Created by Assistant on current date.
//

import SwiftUI
import FamilyControls

struct PomodoroSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: PomodoroViewModel
    @State private var showingAppPicker = false
    
    private let adaptive = AdaptiveValues.current
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: adaptive.spacing.large) {
                        // Focus Time Settings
                        settingsSection(
                            title: "Focus Time",
                            icon: "brain.head.profile",
                            iconColor: .as_red
                        ) {
                            timeDurationPicker(
                                value: $viewModel.focusDuration,
                                label: "Focus Duration",
                                range: 15...60,
                                step: 5
                            )
                        }
                        
                        // Break Time Settings
                        settingsSection(
                            title: "Break Time",
                            icon: "cup.and.saucer.fill",
                            iconColor: Color(hex: "4CAF50")
                        ) {
                            timeDurationPicker(
                                value: $viewModel.breakDuration,
                                label: "Break Duration",
                                range: 5...15,
                                step: 1
                            )
                        }
                        
                        // Sessions Settings
                        settingsSection(
                            title: "Sessions",
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .orange
                        ) {
                            sessionsPicker()
                        }
                        
                        // Notifications Settings
                        settingsSection(
                            title: "Notifications",
                            icon: "bell.fill",
                            iconColor: .purple
                        ) {
                            notificationSettings()
                        }
                        
                        // Auto-start Settings
                        settingsSection(
                            title: "Auto Features",
                            icon: "gearshape.2.fill",
                            iconColor: .blue
                        ) {
                            autoSettings()
                        }
                        
                        // App Blocking Settings
                        settingsSection(
                            title: "App Blocking",
                            icon: "lock.shield.fill",
                            iconColor: .as_red
                        ) {
                            appBlockingSettings()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Pomodoro Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveSettings()
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
            HStack(spacing: adaptive.spacing.small) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: adaptive.spacing.medium) {
                content()
            }
            .padding()
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func timeDurationPicker(
        value: Binding<Int>,
        label: String,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: adaptive.spacing.small) {
            Text(label)
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)
            
            HStack {
                Slider(
                    value: Binding(
                        get: { Double(value.wrappedValue) },
                        set: { value.wrappedValue = Int($0) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: Double(step)
                )
                .accentColor(.white)
                
                Text("\(value.wrappedValue) min")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 70, alignment: .trailing)
            }
        }
    }
    
    private func sessionsPicker() -> some View {
        VStack(alignment: .leading, spacing: adaptive.spacing.small) {
            Text("Number of Sessions")
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)
            
            HStack(spacing: adaptive.spacing.medium) {
                ForEach([2, 4, 6, 8], id: \.self) { count in
                    sessionButton(count: count)
                }
            }
        }
    }
    
    private func sessionButton(count: Int) -> some View {
        Button(action: {
            viewModel.totalSessions = count
        }) {
            Text("\(count)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(viewModel.totalSessions == count ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    viewModel.totalSessions == count ?
                    Color.white : Color.white.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func notificationSettings() -> some View {
        VStack(spacing: adaptive.spacing.medium) {
            Toggle(isOn: $viewModel.notificationsEnabled) {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Enable Notifications")
                        .foregroundColor(.white)
                }
            }
            .tint(.purple)
            
            Toggle(isOn: $viewModel.soundEnabled) {
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Sound Alerts")
                        .foregroundColor(.white)
                }
            }
            .tint(.purple)
        }
    }
    
    private func autoSettings() -> some View {
        VStack(spacing: adaptive.spacing.medium) {
            Toggle(isOn: $viewModel.autoStartBreak) {
                HStack {
                    Image(systemName: "play.circle")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Auto-start Break")
                        .foregroundColor(.white)
                }
            }
            .tint(.blue)
            
            Toggle(isOn: $viewModel.autoStartNextSession) {
                HStack {
                    Image(systemName: "arrow.forward.circle")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Auto-start Next Session")
                        .foregroundColor(.white)
                }
            }
            .tint(.blue)
        }
    }
    
    private func appBlockingSettings() -> some View {
        VStack(spacing: adaptive.spacing.medium) {
            // Block All Apps Toggle
            Toggle(isOn: $viewModel.blockAllCategories) {
                HStack {
                    Image(systemName: "apps.iphone")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Block All App Categories")
                        .foregroundColor(.white)
                }
            }
            .tint(.as_red)
            
            // Select specific apps button
            if !viewModel.blockAllCategories {
                Button(action: {
                    showingAppPicker = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Apps to Block")
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .medium))
                            
                            if !viewModel.selectionActivity.applicationTokens.isEmpty || 
                               !viewModel.selectionActivity.categoryTokens.isEmpty {
                                Text("\(viewModel.selectionActivity.applicationTokens.count) apps, \(viewModel.selectionActivity.categoryTokens.count) categories")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.system(size: 13))
                            } else {
                                Text("No apps selected")
                                    .foregroundColor(.white.opacity(0.4))
                                    .font(.system(size: 13))
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 14))
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .familyActivityPicker(
                    isPresented: $showingAppPicker,
                    selection: $viewModel.selectionActivity
                )
            }
            
            // Block During Break Toggle
            Toggle(isOn: $viewModel.blockDuringBreak) {
                HStack {
                    Image(systemName: "lock.open")
                        .foregroundColor(.white.opacity(0.7))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keep Blocked During Break")
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                        Text("Apps stay blocked during break time")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 12))
                    }
                }
            }
            .tint(.orange)
        }
    }
}

// MARK: - Preview
#Preview {
    PomodoroSettingsView(
        isPresented: .constant(true),
        viewModel: PomodoroViewModel()
    )
}