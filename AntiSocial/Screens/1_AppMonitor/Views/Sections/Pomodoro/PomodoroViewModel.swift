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
    @Published var allSessionsCompleted: Bool = false
    
    // Settings
    @Published var focusDuration: Int = 25 // minutes
    @Published var breakDuration: Int = 5 // minutes
    @Published var longBreakDuration: Int = 15 // minutes
    @Published var autoStartBreak: Bool = true
    @Published var autoStartNextSession: Bool = false
    @Published var notificationsEnabled: Bool = true
    @Published var soundEnabled: Bool = true
    
    // Statistics
    @Published var lifetimeFocusTime: Int = 0 // seconds
    @Published var weeklyFocusTime: Int = 0 // seconds
    @Published var todayFocusTime: Int = 0 // seconds
    
    // App Blocking Settings
    @Published var blockAllCategories: Bool = true
    @Published var selectionActivity = FamilyActivitySelection()
    @Published var blockDuringBreak: Bool = false
    
    private let pomodoroService = PomodoroBlockService.shared
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // Flag to prevent multiple handleSessionEnd calls
    private var isHandlingSessionEnd = false
    
    let presetOptions = [5, 10, 15, 25, 30, 45, 60, 90]
    
    init() {
        print("🍅 Pomodoro: init() called")
        loadSettings()
        loadStatistics()
        setupBindings()
        print("🍅 Pomodoro: init() completed, autoStartBreak = \(autoStartBreak)")
    }
    
    private func setupBindings() {
        // Bind service state to view model
        pomodoroService.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                print("🍅 Pomodoro: Binding triggered - isActive = \(isActive)")
                self?.isRunning = isActive
                if !isActive {
                    print("🍅 Pomodoro: Calling handleSessionEnd() from binding")
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
        print("🍅 Pomodoro: handleSessionEnd() called, currentSessionType = \(currentSessionType), isHandlingSessionEnd = \(isHandlingSessionEnd)")
        // Note: isRunning is already false at this point due to binding
        // We need to check if we're actually ending a session, not just stopping
        
        // Prevent multiple calls to this function
        guard !isHandlingSessionEnd else { 
            print("🍅 Pomodoro: handleSessionEnd() already being handled, skipping")
            return 
        }
        isHandlingSessionEnd = true
        
        // Log session completion
        if currentSessionType == .focus {
            // Update statistics
            let sessionDuration = focusDuration * 60
            updateStatistics(focusTimeAdded: sessionDuration)
            
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
            print("🍅 Pomodoro: Switching to break. autoStartBreak = \(autoStartBreak)")
            if autoStartBreak {
                print("🍅 Pomodoro: Scheduling break start in 2 seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    print("🍅 Pomodoro: Starting break now")
                    self?.startBreak()
                }
            } else {
                print("🍅 Pomodoro: autoStartBreak is disabled, break not started")
            }
        } else {
            // Switch back to focus
            currentSessionType = .focus
            currentSession += 1
            
            if currentSession > totalSessions {
                // All sessions completed
                allSessionsCompleted = true
                showCompletionCelebration()
            } else if autoStartNextSession {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.startPomodoro()
                }
            }
        }
        
        // Reset flag after handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isHandlingSessionEnd = false
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
        allSessionsCompleted = false
        isHandlingSessionEnd = false // Reset flag when starting new session
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
        print("🍅 Pomodoro: startBreak() called")
        currentSessionType = .breakTime
        isHandlingSessionEnd = false // Reset flag when starting break
        let duration = (currentSession % 4 == 0) ? longBreakDuration : breakDuration
        print("🍅 Pomodoro: Break duration = \(duration) minutes, blockDuringBreak = \(blockDuringBreak)")
        
        if blockDuringBreak {
            // Continue blocking during break
            pomodoroService.start(
                minutes: duration,
                selectionActivity: selectionActivity
            )
        } else {
            // Don't block during break - stop the service first then restart just for timer
            // Set flag to prevent handleSessionEnd from being called again
            isHandlingSessionEnd = true
            pomodoroService.stop()
            // Small delay to ensure clean stop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
              guard let self else { return }
              
                self.pomodoroService.start(
                    minutes: duration,
                    selectionActivity: self.selectionActivity
                )
                // Reset flag after starting break
                self.isHandlingSessionEnd = false
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
        isHandlingSessionEnd = false // Reset flag when manually stopping
        
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
        print("🍅 Pomodoro: saveSettings() - autoStartBreak = \(autoStartBreak)")
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
        print("🍅 Pomodoro: loadSettings() - autoStartBreak = \(autoStartBreak)")
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
    
    func loadStatistics() {
        // Load lifetime stats
        lifetimeFocusTime = SharedData.userDefaults?.integer(forKey: "pomodoroLifetimeFocusTime") ?? 0
        
        // Calculate weekly stats
        let weeklyKey = "pomodoroWeeklyFocusTime_\(getCurrentWeekIdentifier())"
        weeklyFocusTime = SharedData.userDefaults?.integer(forKey: weeklyKey) ?? 0
        
        // Calculate today stats  
        let todayKey = "pomodoroTodayFocusTime_\(getCurrentDayIdentifier())"
        todayFocusTime = SharedData.userDefaults?.integer(forKey: todayKey) ?? 0
    }
    
    private func updateStatistics(focusTimeAdded: Int) {
        // Update lifetime
        lifetimeFocusTime += focusTimeAdded
        SharedData.userDefaults?.set(lifetimeFocusTime, forKey: "pomodoroLifetimeFocusTime")
        
        // Update weekly
        let weeklyKey = "pomodoroWeeklyFocusTime_\(getCurrentWeekIdentifier())"
        weeklyFocusTime += focusTimeAdded
        SharedData.userDefaults?.set(weeklyFocusTime, forKey: weeklyKey)
        
        // Update today
        let todayKey = "pomodoroTodayFocusTime_\(getCurrentDayIdentifier())"
        todayFocusTime += focusTimeAdded
        SharedData.userDefaults?.set(todayFocusTime, forKey: todayKey)
    }
    
    private func getCurrentDayIdentifier() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func getCurrentWeekIdentifier() -> String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: Date())
        let year = calendar.component(.year, from: Date())
        return "\(year)-W\(weekOfYear)"
    }
}
