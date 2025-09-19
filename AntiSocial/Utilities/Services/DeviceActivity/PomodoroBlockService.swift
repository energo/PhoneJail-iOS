//
//  PomodoroBlockService.swift
//  AntiSocial
//
//  Created by D C on 28.08.2025.
//


import Foundation
import Combine
import ManagedSettings
import FamilyControls
import BackgroundTasks
import UserNotifications
import UIKit

final class PomodoroBlockService: ObservableObject {
  static let shared = PomodoroBlockService()
  private init() { restoreIfNeeded() }
  
  // MARK: - Public state
  @Published private(set) var isFocusActive: Bool = false
  @Published private(set) var isBreakActive: Bool = false
  @Published private(set) var remainingSeconds: Int = 0
  @Published private(set) var isPaused: Bool = false
  // Whether current session should actually block apps
  private var isBlockingApps: Bool = true
  // Umbrella session state
  @Published var session = PomodoroSession()
  
  // MARK: - Internals
  private let store = ManagedSettingsStore(named: .pomodoro)
  private var ticker: AnyCancellable?
  private let defaultsKey = "pomodoro.unlockDate"
  
  // Pause state
  private var pausedAt: Date?
  private var originalUnlockDate: Date?
  
  // MARK: - API
  /// Запускает помодоро-сессию на N минут. Если blockApps=false — только таймер без блокировки.
  func start(minutes: Int, isStrictBlock: Bool = false, selectionActivity: FamilyActivitySelection, blockApps: Bool = true, phase: String = "focus") {
    print("🍅 PomodoroBlockService: start() - minutes = \(minutes), phase = \(phase)")
    let m = max(5, minutes)
    print("🍅 PomodoroBlockService: start() - after max(1, minutes) = \(m)")
    let unlockDate = Date().addingTimeInterval(TimeInterval(m * 60))
    SharedData.userDefaults?.set(unlockDate.timeIntervalSince1970, forKey: defaultsKey)
    
    // Сохраняем выбранные приложения (используется в расширении)
    if let data = try? JSONEncoder().encode(selectionActivity) {
      SharedData.userDefaults?.set(data, forKey: "pomodoroSelectedApps")
    }
    SharedData.userDefaults?.set(isStrictBlock, forKey: "pomodoroIsStrictBlock")
    
    // Запускаем мониторинг через DeviceActivityMonitor (расширение применит/снимет ограничения)
    // Также накладываем щит локально сразу, чтобы избежать задержки до реакции extension
    isBlockingApps = blockApps
    // Update phase flags
    if phase == "focus" {
      isFocusActive = true
      isBreakActive = false
    } else {
      isBreakActive = true
      isFocusActive = false
    }
    
    if blockApps {
      // Start monitoring so extension can maintain lifecycle and cleanup
      DeviceActivityScheduleService.setPomodoroSchedule(endAt: unlockDate)
    }
    
    // Тикер для UI + авто-снятие в активном приложении
    startTicker(unlockDate: unlockDate)
  }
  
  /// Принудительно завершает текущую сессию. completed=true — считать завершенной (фокус выполнен).
  func stop(reason: PomodoroSession.EndReason = .manualStop, completed: Bool = false) {
//    print("🍅 PomodoroBlockService: stop() called, isActive was \(isActive)")
    // Остановить мониторинг и снять ограничения
    DeviceActivityScheduleService.stopPomodoroSchedule()
    ShieldService.shared.stopAppRestrictions(storeName: .pomodoro)
    SharedData.userDefaults?.removeObject(forKey: defaultsKey)
    SharedData.userDefaults?.removeObject(forKey: "pomodoro.isBreakPhase")
    SharedData.userDefaults?.removeObject(forKey: "pomodoro.isBlockingPhase")
    ticker?.cancel()
    
    // End both phase flags
    isFocusActive = false
    isBreakActive = false
    // Set remaining to zero only on completion; keep otherwise to help UI distinguish manual stop
    if completed { remainingSeconds = 0 }
    isPaused = false
    pausedAt = nil
    originalUnlockDate = nil
    // Завершить логирование
    Task { @MainActor in
      AppBlockingLogger.shared.endSession(type: .pomodoro, completed: completed)
    }
    session.end(reason: reason)
//    print("🍅 PomodoroBlockService: stop() completed, isActive now \(isActive)")
  }
  
  /// Ставит таймер на паузу
  func pause() {
    guard (isBreakActive || isFocusActive) && !isPaused else { return }
    print("🍅 PomodoroBlockService: pause() called")
    
    isPaused = true
    pausedAt = Date()

    // Store the current remaining seconds at pause time
    let currentRemaining = remainingSeconds
    SharedData.userDefaults?.set(currentRemaining, forKey: "pomodoro.pausedRemaining")
    
    // Останавливаем тикер
    ticker?.cancel()
  }
  
  /// Возобновляет таймер после паузы
  func resume() {
    guard (isBreakActive || isFocusActive) && isPaused else { return }
    
    // Get the remaining seconds from when we paused
    let pausedRemaining = SharedData.userDefaults?.integer(forKey: "pomodoro.pausedRemaining") ?? remainingSeconds
    
    // Set new unlock date based on paused remaining time
    let newUnlockDate = Date().addingTimeInterval(TimeInterval(pausedRemaining))
    SharedData.userDefaults?.set(newUnlockDate.timeIntervalSince1970, forKey: defaultsKey)
    
    // Restart ticker with new unlock date
    startTicker(unlockDate: newUnlockDate)
    
    if isBlockingApps {
      DeviceActivityScheduleService.stopPomodoroSchedule()
      DeviceActivityScheduleService.setPomodoroSchedule(endAt: newUnlockDate)
    }
    
    isPaused = false
    pausedAt = nil
    originalUnlockDate = nil
  }
  
  /// Экстренная очистка ВСЕХ блокировок (для отладки)
  func emergencyClearAllBlocks() {
    
    // Очищаем другие возможные stores
    let appBlockingStore = ManagedSettingsStore(named: .appBlocking)
    appBlockingStore.shield.applications = []
    appBlockingStore.shield.applicationCategories = nil
    appBlockingStore.shield.webDomains = []
    appBlockingStore.shield.webDomainCategories = nil
    
    let interruptionStore = ManagedSettingsStore(named: .interruption)
    interruptionStore.shield.applications = []
    interruptionStore.shield.applicationCategories = nil
    interruptionStore.shield.webDomains = []
    interruptionStore.shield.webDomainCategories = nil
    
    // Очищаем дефолтный store
    let defaultStore = ManagedSettingsStore()
    defaultStore.shield.applications = []
    defaultStore.shield.applicationCategories = nil
    defaultStore.shield.webDomains = []
    defaultStore.shield.webDomainCategories = nil
    
    // Очищаем все ключи в SharedData
    SharedData.userDefaults?.removeObject(forKey: defaultsKey)
    SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.isBlocked)
    SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.unlockDate)
    SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
    
    // Останавливаем все таймеры
    ticker?.cancel()
//    isActive = false
    isBreakActive = false
    isFocusActive = false

    remainingSeconds = 0
        
    ShieldService.shared.stopAppRestrictions()
    DeviceActivityScheduleService.stopSchedule()

    print("🚨 Emergency clear: All blocks removed")
  }
    
  // MARK: - Helpers
  private func startTicker(unlockDate: Date) {
    ticker?.cancel()
    // Set initial remaining immediately so UI reflects progress on restore/open
    let initialLeft = Int(max(0, unlockDate.timeIntervalSinceNow))
    print("🍅 PomodoroBlockService: startTicker - unlockDate = \(unlockDate), initialLeft = \(initialLeft)")
    self.remainingSeconds = initialLeft
    ticker = Timer
      .publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] now in
        guard let self else { return }
        let left = Int(unlockDate.timeIntervalSince(now))
        self.remainingSeconds = max(0, left)
        if left <= 0 {
          print("🍅 PomodoroBlockService: Timer reached 0, calling stop()")
          self.stop(reason: .autoTimer, completed: true) // снимет щит и почистит стейт
        }
      }
  }
  
  private func restoreIfNeeded() {
    let unlock = savedUnlockDate()
    guard let unlock = unlock else { 
      print("🍅 PomodoroBlockService: restoreIfNeeded - no saved unlock date")
      return 
    }
    
    print("🍅 PomodoroBlockService: restoreIfNeeded - unlock = \(unlock), now = \(Date())")
    if Date() < unlock {
      // Приложение перезапустили — восстановить тикер. Ограничения поднимет расширение.
      startTicker(unlockDate: unlock)
      // Restore blocking flag for current phase (focus/break)
      let isBlockingPhase = SharedData.userDefaults?.bool(forKey: "pomodoro.isBlockingPhase") ?? true
      isBlockingApps = isBlockingPhase
      let isBreakPhase = SharedData.userDefaults?.bool(forKey: "pomodoro.isBreakPhase") ?? false

      

      // Set phase flags
      if isBreakPhase {
        isBreakActive = true
        isFocusActive = false
      } else if isBlockingPhase {
        isFocusActive = true
        isBreakActive = false
      } else {
        isBreakActive = false
        isFocusActive = false
      }
    } else {
      // Session expired, stop as autoTimer
      stop(reason: .autoTimer, completed: true)
    }
  }
  
  private func savedUnlockDate() -> Date? {
    guard let ts = SharedData.userDefaults?.double(forKey: defaultsKey),
          ts > 0
    else {
      return nil
    }
    
    return Date(timeIntervalSince1970: ts)
  }
}
