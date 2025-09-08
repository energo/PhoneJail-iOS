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
  
  // MARK: - Internals
  private let store = ManagedSettingsStore(named: .pomodoro)
  private var ticker: AnyCancellable?
  private let defaultsKey = "pomodoro.unlockDate"
  private let bgTaskId = "com.app.antisocial.pomodoro.unlock"
  
  // Register once in AppDelegate/SceneDelegate:
  // BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.app.antisocial.pomodoro.unlock", using: nil) { task in
  //     PomodoroBlockService.shared.handleUnlockBGTask(task: task as! BGAppRefreshTask)
  // }

  // MARK: - API
  /// Запускает помодоро-блок на N минут (минимум 1)
  func start(minutes: Int, isStrictBlock: Bool = false, selectionActivity: FamilyActivitySelection) {
    let m = max(1, minutes)
    let unlockDate = Date().addingTimeInterval(TimeInterval(m * 60))
    SharedData.userDefaults?.set(unlockDate.timeIntervalSince1970, forKey: defaultsKey)
    
    // 1) Вешаем щит на всё
    if selectionActivity.applicationTokens.isEmpty && selectionActivity.categoryTokens.isEmpty {
      store.shield.applicationCategories = .all()
//      store.shield.webDomainCategories = .all()
    } else {
      store.shield.applications = selectionActivity.applicationTokens
      store.shield.applicationCategories = (selectionActivity.categoryTokens.isEmpty)
      ? nil
      : ShieldSettings.ActivityCategoryPolicy.specific(selectionActivity.categoryTokens)
      store.shield.webDomains = selectionActivity.webDomainTokens

      store.application.denyAppRemoval = isStrictBlock
    }
    
    // 3) Локалка «начали» и «закончим»
    scheduleLocalNotifications(unlockDate: unlockDate, durationMinutes: m)
    
    // 4) Тикер для UI + авто-снятие
    startTicker(unlockDate: unlockDate)
    
    // 5) Резервный фоновый «разблокировщик»
    scheduleBGUnlock(at: unlockDate)
    
    isActive = true
  }
  
  /// Принудительно снимает блок
  func stop() {
    print("🍅 PomodoroBlockService: stop() called, isActive was \(isActive)")
    clearShield()
    SharedData.userDefaults?.removeObject(forKey: defaultsKey)
    ticker?.cancel()
    isActive = false
    remainingSeconds = 0
    print("🍅 PomodoroBlockService: stop() completed, isActive now \(isActive)")
  }
  
  /// Экстренная очистка ВСЕХ блокировок (для отладки)
  func emergencyClearAllBlocks() {
    // Очищаем Pomodoro store
    clearShield()
    
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
  
  // MARK: - Background task handler
  func handleUnlockBGTask(task: BGAppRefreshTask) {
    // Если уже пора — снять блок; если нет — перезапланировать
    if let unlock = savedUnlockDate() {
      if Date() >= unlock {
        clearShield()
        SharedData.userDefaults?.removeObject(forKey: defaultsKey)
        isActive = false
        remainingSeconds = 0
        task.setTaskCompleted(success: true)
      } else {
        scheduleBGUnlock(at: unlock)
        task.setTaskCompleted(success: true)
      }
    } else {
      task.setTaskCompleted(success: true)
    }
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
          self.stop() // снимет щит и почистит стейт
        }
      }
  }
  
  private func restoreIfNeeded() {
    guard let unlock = savedUnlockDate() else { return }
    if Date() < unlock {
      // Приложение перезапустили — вернуть «щит» и тикер
//      store.shield.applicationCategories = .all()
//      store.shield.webDomainCategories = .all()
      startTicker(unlockDate: unlock)
      isActive = true
    } else {
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
  
  private func clearShield() {
    store.shield.applications = []
    store.shield.applicationCategories = Optional.none
    store.shield.webDomains = []
    store.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy<WebDomain>.none
  }
  
  private func scheduleBGUnlock(at date: Date) {
    // Требуется capability Background fetch + Permitted identifiers в Info.plist
    let req = BGAppRefreshTaskRequest(identifier: bgTaskId)
    req.earliestBeginDate = date
    do { try BGTaskScheduler.shared.submit(req) }
    catch { print("BGTask submit failed:", error) }
  }
  
  private func scheduleLocalNotifications(unlockDate: Date, durationMinutes: Int) {
    // Разрешения на уведомления запросите заранее в онбординге.
    let center = UNUserNotificationCenter.current()
    
    // Старт
    let startContent = UNMutableNotificationContent()
    startContent.title = "Focus started"
    startContent.body = "Blocking all apps for \(durationMinutes) minutes."
    let startReq = UNNotificationRequest(
      identifier: "pomodoro.start.\(UUID().uuidString)",
      content: startContent,
      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
    )
    center.add(startReq)
    
    // Финиш
    let endContent = UNMutableNotificationContent()
    endContent.title = "Focus finished"
    endContent.body = "Time’s up. Unblocking apps now."
    let endReq = UNNotificationRequest(
      identifier: "pomodoro.end.\(UUID().uuidString)",
      content: endContent,
      trigger: UNTimeIntervalNotificationTrigger(
        timeInterval: max(1, unlockDate.timeIntervalSinceNow),
        repeats: false
      )
    )
    center.add(endReq)
  }
}
