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

/// Represents the current state of the Pomodoro timer view
enum PomodoroViewState {
    /// All pomodoro sessions have been completed
    case allSessionsCompleted
    /// Focus session just completed, showing completion animation
    case focusCompletion
    /// Timer is not running, showing setup interface
    case inactive
    /// Focus session is currently active
    case activeFocus
    /// Break session is currently active
    case activeBreak
}

class PomodoroViewModel: ObservableObject {
    // Main state
    @Published var currentState: PomodoroViewState = .inactive
    
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
    
    // Confirmation dialogs
    @Published var showStartFocusDialog: Bool = false
    @Published var showBreakEndDialog: Bool = false
    @Published var showStopSessionDialog: Bool = false
    @Published var showStopBreakDialog: Bool = false
    
    // Intermediate states
    @Published var showFocusCompletion: Bool = false
    
    // App Blocking Settings
    @Published var selectionActivity = FamilyActivitySelection()
    @Published var blockDuringBreak: Bool = false
    @Published var isStrictBlock: Bool = false
    
    // Computed property for blockAllCategories based on selectionActivity
    var blockAllCategories: Bool {
        return selectionActivity.applicationTokens.isEmpty && selectionActivity.categoryTokens.isEmpty
    }
    
    private let pomodoroService = PomodoroBlockService.shared
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // Flag to prevent multiple handleSessionEnd calls
    private var isHandlingSessionEnd = false
    
    // Flag to track if session was started by user (not restored from background)
    private var wasSessionStartedByUser = false
    
    // Flag to track if current session is part of an auto-started sequence
    private var isAutoStartedSequence = false
    
    let presetOptions = [5, 10, 15, 25, 30, 45, 60, 90]
    
    init() {
        print("🍅 Pomodoro: init() called")
        loadSettings()
        loadStatistics()
        setupBindings()
        showFocusCompletion = false // Ensure clean initial state
        print("🍅 Pomodoro: Before updateCurrentState - currentSession: \(currentSession), totalSessions: \(totalSessions), isRunning: \(isRunning), showFocusCompletion: \(showFocusCompletion), currentSessionType: \(currentSessionType)")
        updateCurrentState()
        print("🍅 Pomodoro: init() completed, autoStartBreak = \(autoStartBreak), currentState = \(currentState)")
    }
    
    // MARK: - State Management
    
    private func updateCurrentState() {
        let previousState = currentState
        
        if allSessionsCompleted {
            currentState = .allSessionsCompleted
        } else if showFocusCompletion {
            currentState = .focusCompletion
        } else if !isRunning {
            currentState = .inactive
        } else if currentSessionType == .focus {
            currentState = .activeFocus
        } else {
            currentState = .activeBreak
        }
        
        if previousState != currentState {
            print("🍅 Pomodoro: State changed from \(previousState) to \(currentState) (isRunning: \(isRunning), showFocusCompletion: \(showFocusCompletion), currentSessionType: \(currentSessionType), currentSession: \(currentSession)/\(totalSessions), allSessionsCompleted: \(allSessionsCompleted))")
        } else {
            print("🍅 Pomodoro: State unchanged: \(currentState) (isRunning: \(isRunning), showFocusCompletion: \(showFocusCompletion), currentSessionType: \(currentSessionType), currentSession: \(currentSession)/\(totalSessions), allSessionsCompleted: \(allSessionsCompleted))")
        }
    }
    
    private func setupBindings() {
        // Bind service state to view model
        pomodoroService.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                print("🍅 Pomodoro: Binding triggered - isActive = \(isActive)")
                self?.isRunning = isActive
                self?.updateCurrentState() // Update state when isRunning changes
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
        print("🍅 Pomodoro: handleSessionEnd() called, currentSessionType = \(currentSessionType), isHandlingSessionEnd = \(isHandlingSessionEnd), wasSessionStartedByUser = \(wasSessionStartedByUser)")
        // Note: isRunning is already false at this point due to binding
        // We need to check if we're actually ending a session, not just stopping
        
        // Prevent multiple calls to this function
        guard !isHandlingSessionEnd else { 
            print("🍅 Pomodoro: handleSessionEnd() already being handled, skipping")
            return 
        }
        
        // Only handle session end if it was started by user OR if it's part of an auto-started sequence
        guard wasSessionStartedByUser || isAutoStartedSequence else {
            print("🍅 Pomodoro: Session was not started by user and not part of auto sequence, skipping handleSessionEnd")
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
        
        // All notifications are already scheduled in startFocusSession
        // No need to schedule them again here
        print("🍅 Pomodoro: Session ended - notifications already scheduled")
        
        // Switch session type
        if currentSessionType == .focus {
            // Show focus completion state first
            showFocusCompletion = true
            updateCurrentState() // Update state to show focus completion
            print("🍅 Pomodoro: Showing focus completion state")
            
            // Schedule break start after showing completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                self.showFocusCompletion = false
                
                if self.autoStartBreak {
                    print("🍅 Pomodoro: Starting break immediately after focus completion")
                    self.startBreak(byUser: false) // Auto-started break
                } else {
                    // Switch to break but don't start it
                    self.currentSessionType = .breakTime
                    self.updateCurrentState()
                    print("🍅 Pomodoro: Switching to break. autoStartBreak = \(self.autoStartBreak)")
                }
            }
        } else {
            // Switch back to focus
            currentSessionType = .focus
            currentSession += 1
                        
            if currentSession > totalSessions {
                // All sessions completed
                allSessionsCompleted = true
                updateCurrentState()
                showCompletionCelebration()
            } else {
                // Show confirmation dialog after break session ends
                updateCurrentState()
            }
          
          if !autoStartNextSession {
            showBreakEndDialog = true
          }
        }
        
        // Reset flags after handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isHandlingSessionEnd = false
            // Don't reset wasSessionStartedByUser and isAutoStartedSequence here
            // as they might be needed for the next auto-started session
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
        startPomodoro(byUser: true)
    }
    
    private func startPomodoro(byUser: Bool) {
        print("🍅 Pomodoro: startPomodoro(byUser: \(byUser)) called")
        currentSessionType = .focus
        allSessionsCompleted = false
        isHandlingSessionEnd = false // Reset flag when starting new session
        wasSessionStartedByUser = byUser // Mark if session was started by user
        isAutoStartedSequence = !byUser // Mark if it's part of auto sequence
        updateCurrentState()
        _ = focusDuration
        
        showStartFocusDialog = true
        print("🍅 Pomodoro: showStartFocusDialog = true")
        // Show confirmation dialog if all categories are blocked
//        if blockAllCategories {
//            showStartFocusDialog = true
//            return
//        }
        // Start the session directly
//        startFocusSession(duration: duration)
    }
    
    private func startFocusSession(duration: Int) {
        // Logging is now handled by DeviceActivityMonitorExtension when Pomodoro interval starts
        
        // Schedule ALL notifications for the entire pomodoro cycle
        scheduleAllPomodoroNotifications(focusDuration: duration)
        
        // Start the Pomodoro service which handles both timer and blocking
        // PomodoroBlockService blocks all apps by default when allowWebBlock is true
        
        pomodoroService.start(
            minutes: duration,
            selectionActivity: selectionActivity,
            blockApps: true
        )
        isPaused = false
        // updateCurrentState() will be called by the binding when isRunning changes
    }
    
    func startBreak() {
        startBreak(byUser: true)
    }
    
    private func startBreak(byUser: Bool) {
        print("🍅 Pomodoro: startBreak() called, byUser: \(byUser)")
        currentSessionType = .breakTime
        isHandlingSessionEnd = false // Reset flag when starting break
        wasSessionStartedByUser = byUser // Mark if break was started by user
        isAutoStartedSequence = !byUser // Mark if it's part of auto sequence
        updateCurrentState()
        let duration = (currentSession % 4 == 0) ? longBreakDuration : breakDuration
        print("🍅 Pomodoro: Break duration = \(duration) minutes, blockDuringBreak = \(blockDuringBreak)")
        
        // All notifications are already scheduled in startFocusSession
        // No need to schedule them again here
        
        if blockDuringBreak {
            // Continue blocking during break
            pomodoroService.start(
                minutes: duration,
                selectionActivity: selectionActivity,
                blockApps: true
            )
        } else {
            // Don't block during break - stop the service first then restart just for timer
            // Set flag to prevent handleSessionEnd from being called again
            isHandlingSessionEnd = true
            pomodoroService.stop(completed: true)
            // Small delay to ensure clean stop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
              guard let self else { return }
              
                self.pomodoroService.start(
                    minutes: duration,
                    selectionActivity: self.selectionActivity,
                    blockApps: false
                )
                // Reset flag after starting break
                self.isHandlingSessionEnd = false
            }
        }
        isPaused = false
        // updateCurrentState() will be called by the binding when isRunning changes
    }
    
    func stopPomodoro() {
        // Stop the Pomodoro service (handles both timer and blocking)
        pomodoroService.stop()
        timer?.invalidate()
        timer = nil
        isPaused = false
        isRunning = false
        isHandlingSessionEnd = false // Reset flag when manually stopping
        wasSessionStartedByUser = false // Reset flag when manually stopping
        isAutoStartedSequence = false // Reset auto sequence flag
        
        // Reset to initial state (inactiveStateView)
        currentSessionType = .focus
        currentSession = 1
        allSessionsCompleted = false
        remainingSeconds = 0
        timeRemaining = "00:00"
        
        // Reset all dialog states
        showStartFocusDialog = false
        showBreakEndDialog = false
        showStopSessionDialog = false
        showStopBreakDialog = false
        showFocusCompletion = false
        
        updateCurrentState()
        
        // Cancel any scheduled notifications
        cancelScheduledNotifications()
        
        // End the blocking session logging
        Task { @MainActor in
            AppBlockingLogger.shared.endSession(type: .appBlocking, completed: false)
            print("Pomodoro: Stopped blocking apps")
        }
    }
    
    func requestStopPomodoro() {
        // Show confirmation dialog before stopping
        showStopSessionDialog = true
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
        print("🍅 Pomodoro: skipToNextFocus() called")
        
        // Stop current break session only (don't reset everything)
        pomodoroService.stop()
        isRunning = false
        isPaused = false
        isHandlingSessionEnd = false
        wasSessionStartedByUser = false
        isAutoStartedSequence = false
        
        // Move to next focus session  
        currentSessionType = .focus
        currentSession += 1
        
        // Reset if completed all sessions
        if currentSession > totalSessions {
            currentSession = 1
            allSessionsCompleted = true
        } else {
            allSessionsCompleted = false
        }
        
        updateCurrentState()
        
        // Start new focus session
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startPomodoro()
        }
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
        // Pause the PomodoroBlockService timer
        pomodoroService.pause()
    }
    
    func resume() {
        isPaused = false
        // Resume the PomodoroBlockService timer
        pomodoroService.resume()
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
        SharedData.userDefaults?.set(blockDuringBreak, forKey: "pomodoroBlockDuringBreak")
        SharedData.userDefaults?.set(isStrictBlock, forKey: "pomodoroIsStrictBlock")
        
        // Save selected apps
        if let data = try? JSONEncoder().encode(selectionActivity) {
            SharedData.userDefaults?.set(data, forKey: "pomodoroSelectedApps")
        }
        
        // Save current session state
        SharedData.userDefaults?.set(currentSession, forKey: SharedData.Pomodoro.currentSession)
        SharedData.userDefaults?.set(currentSessionType == .focus ? "focus" : "break", forKey: SharedData.Pomodoro.currentSessionType)
        SharedData.userDefaults?.set(allSessionsCompleted, forKey: "pomodoroAllSessionsCompleted")
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
        blockDuringBreak = SharedData.userDefaults?.bool(forKey: "pomodoroBlockDuringBreak") ?? false
        isStrictBlock = SharedData.userDefaults?.bool(forKey: "pomodoroIsStrictBlock") ?? false
        
        // Load selected apps
        if let data = SharedData.userDefaults?.data(forKey: "pomodoroSelectedApps"),
           let apps = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectionActivity = apps
        }
        
        // Load session state
        currentSession = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.currentSession) ?? 1
        let sessionTypeString = SharedData.userDefaults?.string(forKey: SharedData.Pomodoro.currentSessionType) ?? "focus"
        currentSessionType = sessionTypeString == "focus" ? .focus : .breakTime
        allSessionsCompleted = SharedData.userDefaults?.bool(forKey: "pomodoroAllSessionsCompleted") ?? false
        
        // Reset session state if it's invalid (e.g., currentSession > totalSessions)
        if currentSession > totalSessions {
            print("🍅 Pomodoro: Invalid session state detected (currentSession: \(currentSession) > totalSessions: \(totalSessions)), resetting to 1")
            currentSession = 1
            currentSessionType = .focus
            allSessionsCompleted = false
        }
        
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
    
    // MARK: - Dialog Actions
    
    func confirmStartFocus() {
        showStartFocusDialog = false
        startFocusSession(duration: focusDuration)
    }
    
    func cancelStartFocus() {
        showStartFocusDialog = false
    }
    
    func confirmBreakEnd() {
        showBreakEndDialog = false
        
        // Reset session state for new cycle
        currentSession = 1
      allSessionsCompleted = false
        updateCurrentState()
        
        // Start new focus session with same settings
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startPomodoro(byUser: true) // User confirmed to start new cycle
        }
    }
    
    func cancelBreakEnd() {
        showBreakEndDialog = false
        
        // Stop pomodoro and go to inactive state
        stopPomodoro()
    }
    
    func confirmStopSession() {
        showStopSessionDialog = false
        stopPomodoro()
    }
    
    func cancelStopSession() {
        showStopSessionDialog = false
    }
    
    func requestStopBreak() {
        // Show confirmation dialog before stopping break
        showStopBreakDialog = true
    }
    
    func confirmStopBreak() {
        showStopBreakDialog = false
        stopPomodoro()
    }
    
    func cancelStopBreak() {
        showStopBreakDialog = false
    }
    
    func skipToBreak() {
        // Stop current focus session and immediately start break
        print("🍅 Pomodoro: skipToBreak() called")
        
        // Cancel current scheduled notifications
        cancelScheduledNotifications()
        print("🍅 Pomodoro: Cancelled current notifications")
        
        // Stop the current focus session and mark it as completed
        pomodoroService.stop(completed: true)
        
        // Update statistics for the completed focus session
        let sessionDuration = focusDuration * 60
        updateStatistics(focusTimeAdded: sessionDuration)
        
        // Logging handled by PomodoroBlockService.stop(completed:)
        
        // Switch to break session
        currentSessionType = .breakTime
        isHandlingSessionEnd = false
        wasSessionStartedByUser = true // Mark as user-initiated
        isAutoStartedSequence = false
        updateCurrentState()
        
        // Schedule new notifications for break session
        scheduleBreakNotifications()
        print("🍅 Pomodoro: Scheduled new break notifications")
        
        // Start break session immediately
        startBreak(byUser: true)
    }
    
    // MARK: - Notification Scheduling
    
    private func scheduleAllPomodoroNotifications(focusDuration: Int) {
        guard notificationsEnabled else {
            print("🍅 Pomodoro: Notifications disabled, skipping notification scheduling")
            return
        }
        
        print("🍅 Pomodoro: Scheduling all notifications for pomodoro cycle")
        
        // 1. Focus session start notification (immediate)
        LocalNotificationManager.shared.schedulePomodoroSessionStarted(
            sessionType: "focus",
            nextSession: "break",
            timeInterval: 0.1
        )
        
        // 2. Focus session end notification (scheduled for when focus ends)
        let focusEndTime = TimeInterval(focusDuration * 60) // Convert minutes to seconds
        LocalNotificationManager.shared.scheduleFocusSessionEnded(timeInterval: focusEndTime)
        
        // 3. Break session start notification (scheduled for when break starts)
        let breakStartTime = focusEndTime + 0.1 // Start break right after focus ends
        LocalNotificationManager.shared.schedulePomodoroSessionStarted(
            sessionType: "break",
            nextSession: "focus",
            timeInterval: breakStartTime
        )
        
        // 4. Break session end notification (scheduled for when break ends)
        let breakDurationMinutes = (currentSession % 4 == 0) ? longBreakDuration : breakDuration
        let breakEndTime = breakStartTime + TimeInterval(breakDurationMinutes * 60)
        LocalNotificationManager.shared.scheduleBreakSessionEnded(timeInterval: breakEndTime)
        
        print("🍅 Pomodoro: All notifications scheduled successfully")
    }
    
    // MARK: - Notification Management
    
    private func cancelScheduledNotifications() {
        LocalNotificationManager.shared.cancelScheduledPomodoroNotifications()
    }
    
    private func scheduleBreakNotifications() {
        guard notificationsEnabled else {
            print("🍅 Pomodoro: Notifications disabled, skipping break notification scheduling")
            return
        }
        
        print("🍅 Pomodoro: Scheduling break notifications")
        
        // 1. Break session start notification (immediate)
        LocalNotificationManager.shared.schedulePomodoroSessionStarted(
            sessionType: "break",
            nextSession: "focus",
            timeInterval: 0.1
        )
        
        // 2. Break session end notification (scheduled for when break ends)
        let breakDurationMinutes = (currentSession % 4 == 0) ? longBreakDuration : breakDuration
        let breakEndTime = TimeInterval(breakDurationMinutes * 60)
        LocalNotificationManager.shared.scheduleBreakSessionEnded(timeInterval: breakEndTime)
        
        print("🍅 Pomodoro: Break notifications scheduled successfully")
    }
}
