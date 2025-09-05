//
//  PomodoroViewModel.swift
//  AntiSocial
//
//  Created by Assistant on 2025.
//

import SwiftUI
import Combine
import FamilyControls
import DeviceActivity
import ManagedSettings

enum SessionType {
    case focus
    case breakTime
}

class PomodoroViewModel: ObservableObject {
    // Timer state
    @Published var selectedMinutes: Int = 25
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var timeRemaining: String = "00:00"
    @Published var remainingSeconds: TimeInterval = 0
    
    // Session management
    @Published var currentSessionType: SessionType = .focus
    @Published var currentSession: Int = 1
    @Published var totalSessions: Int = 4
    
    // Settings
    @Published var focusDuration: Int = 25 // minutes
    @Published var breakDuration: Int = 5 // minutes
    @Published var longBreakDuration: Int = 15 // minutes
    @Published var autoStartBreak: Bool = true
    @Published var autoStartNextSession: Bool = false
    @Published var notificationsEnabled: Bool = true
    @Published var soundEnabled: Bool = true
    
    // App Blocking Settings
    @Published var blockAllCategories: Bool = true
    @Published var selectionActivity = FamilyActivitySelection()
    @Published var blockDuringBreak: Bool = false
    
    private let pomodoroService = PomodoroBlockService.shared
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    let presetOptions = [5, 10, 15, 25, 30, 45, 60, 90]
    
    init() {
        loadSettings()
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind service state to view model
        pomodoroService.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.isRunning = isActive
                if !isActive {
                    self?.handleSessionEnd()
                }
            }
            .store(in: &cancellables)
        
        // Format remaining time
        pomodoroService.$remainingSeconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] seconds in
                self?.remainingSeconds = TimeInterval(seconds)
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                self?.timeRemaining = String(format: "%02d:%02d", minutes, remainingSeconds)
            }
            .store(in: &cancellables)
    }
    
    private func handleSessionEnd() {
        guard isRunning else { return }
        
        // Log session completion
        if currentSessionType == .focus {
            Task { @MainActor in
                AppBlockingLogger.shared.endSession(type: .appBlocking, completed: true)
                print("Pomodoro: Focus session completed")
            }
        }
        
        // Play sound if enabled
        if soundEnabled {
            HapticManager.shared.notification(type: .success)
        }
        
        // Show notification if enabled
        if notificationsEnabled {
            let nextSession = currentSession % 4 == 0 ? "longBreak" : "break"
            LocalNotificationManager.shared.schedulePomodoroSessionComplete(
                sessionType: currentSessionType == .focus ? "focus" : "break",
                nextSession: nextSession
            )
        }
        
        // Switch session type
        if currentSessionType == .focus {
            // Switch to break
            currentSessionType = .breakTime
            if autoStartBreak {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.startBreak()
                }
            }
        } else {
            // Switch back to focus
            currentSessionType = .focus
            currentSession += 1
            
            if currentSession > totalSessions {
                // All sessions completed
                currentSession = 1
                showCompletionCelebration()
            } else if autoStartNextSession {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.startPomodoro()
                }
            }
        }
    }
    
    private func showCompletionCelebration() {
        // Show completion animation or notification
        if notificationsEnabled {
            LocalNotificationManager.shared.schedulePomodoroAllSessionsComplete(
                totalSessions: totalSessions
            )
        }
        HapticManager.shared.notification(type: .success)
    }
    
    func startPomodoro() {
        currentSessionType = .focus
        let duration = focusDuration
        
        // Log the blocking session
        Task { @MainActor in
            let sessionId = AppBlockingLogger.shared.startAppBlockingSessionForCategories(
                duration: TimeInterval(duration * 60)
            )
            print("Pomodoro: Started session \(sessionId) for \(duration) minutes")
        }
        
        // Start the Pomodoro service which handles both timer and blocking
        // PomodoroBlockService blocks all apps by default when allowWebBlock is true
        
        pomodoroService.start(
            minutes: duration,
            selectionActivity: selectionActivity
        )
        isPaused = false
    }
    
    func startBreak() {
        currentSessionType = .breakTime
        let duration = (currentSession % 4 == 0) ? longBreakDuration : breakDuration
        
        if blockDuringBreak {
            // Continue blocking during break
            pomodoroService.start(
                minutes: duration,
                selectionActivity: selectionActivity
            )
        } else {
            // Don't block during break - stop the service first then restart just for timer
            pomodoroService.stop()
            // Small delay to ensure clean stop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.pomodoroService.start(
                    minutes: duration,
                    selectionActivity: nil
                )
            }
        }
        isPaused = false
    }
    
    func stopPomodoro() {
        // Stop the Pomodoro service (handles both timer and blocking)
        pomodoroService.stop()
        timer?.invalidate()
        timer = nil
        isPaused = false
        isRunning = false
        
        // End the blocking session logging
        Task { @MainActor in
            AppBlockingLogger.shared.endSession(type: .appBlocking, completed: false)
            print("Pomodoro: Stopped blocking apps")
        }
    }
    
    func togglePomodoro() {
        if isRunning {
            stopPomodoro()
        } else {
            startPomodoro()
        }
    }
    
    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }
    
    func skipToNextFocus() {
        // Stop current break
        stopPomodoro()
        
        // Move to next focus session  
        currentSessionType = .focus
        currentSession += 1
        
        // Reset if completed all sessions
        if currentSession > totalSessions {
            currentSession = 1
        }
        
        // Start new focus session
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startPomodoro()
        }
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
        // Note: We keep the blocking active but pause the timer
    }
    
    func resume() {
        isPaused = false
        // Resume the timer
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            // Timer logic handled by PomodoroBlockService
        }
    }
    
    func saveSettings() {
        // Save settings to SharedData (App Group UserDefaults)
        SharedData.userDefaults?.set(focusDuration, forKey: SharedData.Pomodoro.focusDuration)
        SharedData.userDefaults?.set(breakDuration, forKey: SharedData.Pomodoro.breakDuration)
        SharedData.userDefaults?.set(longBreakDuration, forKey: SharedData.Pomodoro.longBreakDuration)
        SharedData.userDefaults?.set(totalSessions, forKey: SharedData.Pomodoro.totalSessions)
        SharedData.userDefaults?.set(autoStartBreak, forKey: SharedData.Pomodoro.autoStartBreak)
        SharedData.userDefaults?.set(autoStartNextSession, forKey: SharedData.Pomodoro.autoStartNextSession)
        SharedData.userDefaults?.set(notificationsEnabled, forKey: SharedData.Pomodoro.notificationsEnabled)
        SharedData.userDefaults?.set(soundEnabled, forKey: SharedData.Pomodoro.soundEnabled)
        
        // Save app blocking settings
        SharedData.userDefaults?.set(blockAllCategories, forKey: "pomodoroBlockAllCategories")
        SharedData.userDefaults?.set(blockDuringBreak, forKey: "pomodoroBlockDuringBreak")
        
        // Save selected apps
        if let data = try? JSONEncoder().encode(selectionActivity) {
            SharedData.userDefaults?.set(data, forKey: "pomodoroSelectedApps")
        }
        
        // Save current session state
        SharedData.userDefaults?.set(currentSession, forKey: SharedData.Pomodoro.currentSession)
        SharedData.userDefaults?.set(currentSessionType == .focus ? "focus" : "break", forKey: SharedData.Pomodoro.currentSessionType)
    }
    
    func loadSettings() {
        // Load from SharedData with default values if not set
        focusDuration = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.focusDuration) ?? 25
        breakDuration = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.breakDuration) ?? 5
        longBreakDuration = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.longBreakDuration) ?? 15
        totalSessions = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.totalSessions) ?? 4
        autoStartBreak = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.autoStartBreak) ?? true
        autoStartNextSession = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.autoStartNextSession) ?? false
        notificationsEnabled = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.notificationsEnabled) ?? true
        soundEnabled = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.soundEnabled) ?? true
        
        // Load app blocking settings
        blockAllCategories = SharedData.userDefaults?.bool(forKey: "pomodoroBlockAllCategories") ?? true
        blockDuringBreak = SharedData.userDefaults?.bool(forKey: "pomodoroBlockDuringBreak") ?? false
        
        // Load selected apps
        if let data = SharedData.userDefaults?.data(forKey: "pomodoroSelectedApps"),
           let apps = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectionActivity = apps
        }
        
        // Load session state
        currentSession = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.currentSession) ?? 1
        let sessionTypeString = SharedData.userDefaults?.string(forKey: SharedData.Pomodoro.currentSessionType) ?? "focus"
        currentSessionType = sessionTypeString == "focus" ? .focus : .breakTime
        
        // If no settings were saved before, save defaults
        if SharedData.userDefaults?.object(forKey: SharedData.Pomodoro.focusDuration) == nil {
            saveSettings()
        }
    }
}
