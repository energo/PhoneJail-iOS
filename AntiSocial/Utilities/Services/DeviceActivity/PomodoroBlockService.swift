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
  @Published private(set) var isActive: Bool = false
  @Published private(set) var remainingSeconds: Int = 0
  @Published private(set) var isPaused: Bool = false
  // Whether current session should actually block apps
  private var isBlockingApps: Bool = true

  // MARK: - Internals
  private let store = ManagedSettingsStore(named: .pomodoro)
  private var ticker: AnyCancellable?
  private let defaultsKey = "pomodoro.unlockDate"
  
  // Pause state
  private var pausedAt: Date?
  private var originalUnlockDate: Date?
  
  // MARK: - API
  /// Запускает помодоро-сессию на N минут. Если blockApps=false — только таймер без блокировки.
  func start(minutes: Int, isStrictBlock: Bool = false, selectionActivity: FamilyActivitySelection, blockApps: Bool = true) {
    let m = max(1, minutes)
    let unlockDate = Date().addingTimeInterval(TimeInterval(m * 60))
    SharedData.userDefaults?.set(unlockDate.timeIntervalSince1970, forKey: defaultsKey)
    
    // Сохраняем выбранные приложения (используется в расширении)
    if let data = try? JSONEncoder().encode(selectionActivity) {
      SharedData.userDefaults?.set(data, forKey: "pomodoroSelectedApps")
    }
    SharedData.userDefaults?.set(isStrictBlock, forKey: "pomodoroIsStrictBlock")
    
    // Запускаем мониторинг через DeviceActivityMonitor (расширение применит/снимет ограничения)
    isBlockingApps = blockApps
    if blockApps {
      DeviceActivityScheduleService.setPomodoroSchedule(endAt: unlockDate)
    }
    
    // Тикер для UI + авто-снятие в активном приложении
    startTicker(unlockDate: unlockDate)
    
    isActive = true
  }
  
  /// Принудительно завершает текущую сессию. completed=true — считать завершенной (фокус выполнен).
  func stop(completed: Bool = false) {
    print("🍅 PomodoroBlockService: stop() called, isActive was \(isActive)")
    // Остановить мониторинг и снять ограничения
    DeviceActivityScheduleService.stopPomodoroSchedule()
    ShieldService.shared.stopAppRestrictions(storeName: .pomodoro)
    SharedData.userDefaults?.removeObject(forKey: defaultsKey)
    ticker?.cancel()
    
    isActive = false
    remainingSeconds = 0
    isPaused = false
    pausedAt = nil
    originalUnlockDate = nil
    // Завершить логирование
    Task { @MainActor in
      AppBlockingLogger.shared.endSession(type: .appBlocking, completed: completed)
    }
    print("🍅 PomodoroBlockService: stop() completed, isActive now \(isActive)")
  }
  
  /// Ставит таймер на паузу
  func pause() {
    guard isActive && !isPaused else { return }
    print("🍅 PomodoroBlockService: pause() called")
    
    isPaused = true
    pausedAt = Date()
    originalUnlockDate = savedUnlockDate()
    
    // Останавливаем тикер
    ticker?.cancel()
  }
  
  /// Возобновляет таймер после паузы
  func resume() {
    guard isActive && isPaused else { return }
    print("🍅 PomodoroBlockService: resume() called")
    
    guard let pausedAt = pausedAt,
          let originalUnlock = originalUnlockDate else { return }
    
    // Вычисляем, сколько времени прошло в паузе
    let pauseDuration = Date().timeIntervalSince(pausedAt)
    let newUnlockDate = originalUnlock.addingTimeInterval(pauseDuration)
    
    // Обновляем дату разблокировки
    SharedData.userDefaults?.set(newUnlockDate.timeIntervalSince1970, forKey: defaultsKey)
    
    // Перезапускаем тикер
    startTicker(unlockDate: newUnlockDate)
    
    // Переназначаем расписание для блокировки, если она включена
    if isBlockingApps {
      DeviceActivityScheduleService.stopPomodoroSchedule()
      DeviceActivityScheduleService.setPomodoroSchedule(endAt: newUnlockDate)
    }
    
    isPaused = false
    self.pausedAt = nil
    self.originalUnlockDate = nil
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
    isActive = false
    remainingSeconds = 0
        
    ShieldService.shared.stopAppRestrictions()
    DeviceActivityScheduleService.stopSchedule()

    print("🚨 Emergency clear: All blocks removed")
  }
    
  // MARK: - Helpers
  private func startTicker(unlockDate: Date) {
    ticker?.cancel()
    ticker = Timer
      .publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] now in
        guard let self else { return }
        let left = Int(unlockDate.timeIntervalSince(now))
        self.remainingSeconds = max(0, left)
        if left <= 0 {
          print("🍅 PomodoroBlockService: Timer reached 0, calling stop()")
          self.stop(completed: true) // снимет щит и почистит стейт
        }
      }
  }
  
  private func restoreIfNeeded() {
    
    guard let unlock = savedUnlockDate() else { return }
    if Date() < unlock {
      // Приложение перезапустили — восстановить тикер. Ограничения поднимет расширение.
      startTicker(unlockDate: unlock)
      isActive = true
    } else {
      // Session expired, stop
      stop()
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
