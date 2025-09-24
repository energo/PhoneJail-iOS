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
  @Published var isRunning: Bool = false
  @Published var isPaused: Bool = false
  @Published var timeRemaining: String = "00:00"
  @Published var remainingSeconds: TimeInterval = 0
  
  // Session management
  @Published var currentSessionType: SessionType = .focus
  @Published var currentSession: Int = 1
  @Published var totalSessions: Int = 1
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
  // Track last activity flags to detect natural end transitions
  private var lastFocusActive: Bool = false
  private var lastBreakActive: Bool = false
  
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
    
    // Attempt to restore active session state on launch (e.g., break started while app closed)
    //        DispatchQueue.main.async { [weak self] in
    self.restoreFromPersistentState()
    //        }
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
    // Bind focus and break activity
    pomodoroService.$isFocusActive
      .receive(on: DispatchQueue.main)
      .sink { [weak self] focusActive in
        guard let self else { return }
        let ended = (
          self.lastFocusActive &&
          !focusActive &&
          Int(self.remainingSeconds) <= 0 &&
          (self.pomodoroService.session.lastEndReason == .autoTimer)
        )
        if ended && self.currentSessionType == .focus {
          self.handleSessionEnd()
        }
        self.lastFocusActive = focusActive
        self.isRunning = focusActive || self.pomodoroService.isBreakActive
        self.updateCurrentState()
      }
      .store(in: &cancellables)
    
    pomodoroService.$isBreakActive
      .receive(on: DispatchQueue.main)
      .sink { [weak self] breakActive in
        guard let self else { return }
        let ended = (
          self.lastBreakActive &&
          !breakActive &&
          Int(self.remainingSeconds) <= 0 &&
          (self.pomodoroService.session.lastEndReason == .autoTimer)
        )
        if ended && self.currentSessionType == .breakTime {
          self.handleSessionEnd()
        }
        self.lastBreakActive = breakActive
        self.isRunning = breakActive || self.pomodoroService.isFocusActive
        self.updateCurrentState()
      }
      .store(in: &cancellables)
    
    // Format remaining time
    pomodoroService.$remainingSeconds
      .receive(on: DispatchQueue.main)
      .sink { [weak self] seconds in
        print("🍅 Pomodoro: remainingSeconds updated = \(seconds)")
        self?.remainingSeconds = TimeInterval(seconds)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        self?.timeRemaining = String(format: "%02d:%02d", minutes, remainingSeconds)
        print("🍅 Pomodoro: timeRemaining = \(self?.timeRemaining ?? "nil")")
      }
      .store(in: &cancellables)
  }
  
  private func handleSessionEnd() {
    // Prevent multiple calls to this function
    guard !isHandlingSessionEnd else {
      print("🍅 Pomodoro: handleSessionEnd() already being handled, skipping")
      return
    }
    
    isHandlingSessionEnd = true
    defer { isHandlingSessionEnd = false }
    
    // Update internal pomodoro stats when focus finishes (AppBlockingLogger handled elsewhere)
    if currentSessionType == .focus {
      let sessionDuration = focusDuration * 60
      updateStatistics(focusTimeAdded: sessionDuration)
    }
    
    // Haptics
    if soundEnabled {
      HapticManager.shared.notification(type: .success)
    }
    
    // Phase transitions
    if currentSessionType == .focus {
      // Show completion for focus, then move to break
      showFocusCompletion = true
      updateCurrentState()
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
        guard let self else { return }
        self.showFocusCompletion = false
        if self.autoStartBreak {
          self.startBreakFlow()
        } else {
          self.currentSessionType = .breakTime
          self.updateCurrentState()
          self.showBreakEndDialog = true
        }
      }
    } else {
      // Break finished → next focus or complete
      currentSessionType = .focus
      currentSession += 1
      if currentSession > totalSessions {
        allSessionsCompleted = true
        updateCurrentState()
        showCompletionCelebration()
        // After completing the full cycle, ask user if they want to start again
        showBreakEndDialog = true
      } else {
        updateCurrentState()
        if autoStartNextSession {
          startFocusFlow()
        } else {
          showBreakEndDialog = true
        }
      }
    }
  }
  
  // MARK: - Flow helpers
  private func startBreakFlow() {
    startBreak(byUser: false)
  }
  
  private func startFocusFlow() {
    startFocusSession(duration: focusDuration)
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
    updateCurrentState()
    _ = focusDuration
    
    showStartFocusDialog = true
    print("🍅 Pomodoro: showStartFocusDialog = true")
  }
  
  private func startFocusSession(duration: Int) {
    // Logging is now handled by DeviceActivityMonitorExtension when Pomodoro interval starts
    
    // Persist state for restore after relaunch
    saveSettings()
    SharedData.userDefaults?.set("focus", forKey: SharedData.Pomodoro.currentSessionType)
    SharedData.userDefaults?.set(true, forKey: SharedData.Pomodoro.isFocusPhase)
    SharedData.userDefaults?.set(false, forKey: SharedData.Pomodoro.isBreakPhase)
    
    // Schedule ALL notifications for the entire pomodoro cycle
    scheduleAllPomodoroNotifications(focusDuration: duration)
    
    // Start the Pomodoro service which handles both timer and blocking
    // PomodoroBlockService blocks all apps by default when allowWebBlock is true
    
    pomodoroService.start(
      minutes: duration,
      selectionActivity: selectionActivity,
      blockApps: true,
      phase: "focus"
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
    updateCurrentState()
    
    isHandlingSessionEnd = true
    pomodoroService.stop(completed: true)

    // Persist break state for restore after relaunch
    saveSettings()
    SharedData.userDefaults?.set("break", forKey: SharedData.Pomodoro.currentSessionType)
    SharedData.userDefaults?.set(false, forKey: SharedData.Pomodoro.isFocusPhase)
    SharedData.userDefaults?.set(true, forKey: SharedData.Pomodoro.isBreakPhase)

    let duration = breakDuration
    print("🍅 Pomodoro: Break duration = \(duration) minutes, blockDuringBreak = \(blockDuringBreak)")
    
    // Don't block during break - stop the service first then restart just for timer
    // Set flag to prevent handleSessionEnd from being called again
    // Small delay to ensure clean stop
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self else { return }
      
      self.pomodoroService.start(
        minutes: duration,
        selectionActivity: self.selectionActivity,
        blockApps: false,
        phase: "break"
      )
      // Reset flag after starting break
      self.isHandlingSessionEnd = false
    }
    isPaused = false
  }
  
  func stopPomodoro() {
    pomodoroService.stop(reason: PomodoroSession.EndReason.manualStop, completed: false)
    timer?.invalidate()
    timer = nil
    isPaused = false
    isRunning = false
    isHandlingSessionEnd = false // Reset flag when manually stopping
    
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
      AppBlockingLogger.shared.endSession(type: .pomodoro, completed: false)
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
    pomodoroService.stop(reason: PomodoroSession.EndReason.manualStop, completed: false)
    isRunning = false
    isPaused = false
    isHandlingSessionEnd = false
    
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
  
  // MARK: - Restore
  /// Ensure UI reflects active focus/break session if app was closed when phase started
  func restoreFromPersistentState() {
    let now = Date().timeIntervalSince1970
    
    // Сначала проверяем, была ли пауза
    let wasPaused = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.isPaused) ?? false
    let pausedRemaining = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.pausedRemaining) ?? 0
    
    // Если был на паузе - восстанавливаем состояние паузы
    if wasPaused && pausedRemaining > 0 {
      print("🍅 Restoring paused state with remaining: \(pausedRemaining) seconds")
      
      isPaused = true
      remainingSeconds = TimeInterval(pausedRemaining)
      
      // Определяем тип сессии
      let isBreakPhase = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.isBreakPhase) ?? false
      if isBreakPhase {
        currentSessionType = .breakTime
        pomodoroService.isBreakActive = true
        pomodoroService.isFocusActive = false
      } else {
        let typeString = SharedData.userDefaults?.string(forKey: SharedData.Pomodoro.currentSessionType) ?? "focus"
        currentSessionType = (typeString == "break") ? .breakTime : .focus
        pomodoroService.isFocusActive = (currentSessionType == .focus)
        pomodoroService.isBreakActive = (currentSessionType == .breakTime)
      }
      
      // Синхронизируем состояние с сервисом
      pomodoroService.isPaused = true
      pomodoroService.remainingSeconds = pausedRemaining
      
      isRunning = true
            
      updateCurrentState()
      return
    }
    
    // Если не было паузы, проверяем активные сессии
    let ts = SharedData.userDefaults?.double(forKey: SharedData.Pomodoro.unlockDate) ?? 0
    let isFuture = ts > now
    let isBreakPhase = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.isBreakPhase) ?? false
    let isFocusActive = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.isFocusPhase) ?? false
    
    // Восстанавливаем break сессию
    if isBreakPhase {
      if isFuture {
        let typeString = SharedData.userDefaults?.string(forKey: SharedData.Pomodoro.currentSessionType) ?? "break"
        currentSessionType = (typeString == "break") ? .breakTime : .focus

        isRunning = true
        let left = Int(ts - now)
        remainingSeconds = TimeInterval(max(0, left))
        
        // Синхронизируемся с сервисом (он уже должен быть восстановлен через restoreIfNeeded)
        if pomodoroService.remainingSeconds > 0 {
          remainingSeconds = TimeInterval(pomodoroService.remainingSeconds)
        }
        
      } else {
        // Устаревший флаг break без оставшегося времени
        SharedData.userDefaults?.set(false, forKey: SharedData.Pomodoro.isBreakPhase)
        isRunning = false
      }
      
      updateCurrentState()
      return
    }
    
    // Восстанавливаем focus сессию или активную сессию с unlockDate
    if isFocusActive {
      let typeString = SharedData.userDefaults?.string(forKey: SharedData.Pomodoro.currentSessionType) ?? "focus"
      currentSessionType = (typeString == "break") ? .breakTime : .focus
      
      if isFuture {
        let left = Int(ts - now)
        remainingSeconds = TimeInterval(max(0, left))
        isRunning = true

        // Синхронизируемся с сервисом
        if pomodoroService.remainingSeconds > 0 {
          remainingSeconds = TimeInterval(pomodoroService.remainingSeconds)
        }
      } else {
        SharedData.userDefaults?.set(false, forKey: SharedData.Pomodoro.isFocusPhase)
        isRunning = false
      }
      
      updateCurrentState()
      return
    }
    
    // Нет активной сессии
    isRunning = false
    updateCurrentState()
  }
  
  func saveSettings() {
    _ = focusDuration // fix for section update after save

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
    let hasStoredAutoStartBreak = SharedData.userDefaults?.object(forKey: SharedData.Pomodoro.autoStartBreak) != nil
    
    let storedFocusDuration = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.focusDuration) ?? 25
    let storedBreakDuration = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.breakDuration) ?? 5
    
    print("🍅 Pomodoro: loadSettings() - storedFocusDuration = \(storedFocusDuration), storedBreakDuration = \(storedBreakDuration)")
    
    // Only use stored values if they are valid (not 0)
    focusDuration = storedFocusDuration > 0 ? storedFocusDuration : 25
    breakDuration = storedBreakDuration > 0 ? storedBreakDuration : 5
    longBreakDuration = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.longBreakDuration) ?? 15
    totalSessions = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.totalSessions) ?? 4
    if !hasStoredAutoStartBreak {
      // First time - use default true
      autoStartBreak = true
    } else {
      // User has explicitly set it
      autoStartBreak = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.autoStartBreak) ?? true
    }
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
    totalSessions = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.totalSessions) ?? 1
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
      // Only save if we have valid values (not 0)
      if focusDuration > 0 && breakDuration > 0 {
        saveSettings()
      }
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
    print("🍅 Pomodoro: confirmStartFocus() - focusDuration = \(focusDuration)")
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
    
    isPaused = false
    // Cancel current scheduled notifications
    cancelScheduledNotifications()
    print("🍅 Pomodoro: Cancelled current notifications")
    
    // Stop the current focus session and mark it as completed (user action)
    pomodoroService.stop(reason: PomodoroSession.EndReason.manualStop, completed: true)
    
    // Update statistics for the completed focus session
    let sessionDuration = focusDuration * 60
    updateStatistics(focusTimeAdded: sessionDuration)
    
    // Logging handled by PomodoroBlockService.stop(completed:)
    
    // Switch to break session
    currentSessionType = .breakTime
    isHandlingSessionEnd = false
    updateCurrentState()
    // Persist state change
    saveSettings()
    
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
