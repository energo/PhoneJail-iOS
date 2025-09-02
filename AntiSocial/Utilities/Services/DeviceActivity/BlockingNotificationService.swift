//
//  BlockingNotificationService.swift
//  AntiSocial
//
//  Created by D C on 08.07.2025.
//


import Foundation
import WidgetKit
import FamilyControls
import ManagedSettings



final class BlockingNotificationService: ObservableObject {
  static let shared = BlockingNotificationService()
  private init() {}

  func startBlocking(
    hours: Int,
    minutes: Int,
    selection: FamilyActivitySelection,
    restrictionModel: MyRestrictionModel
  ) {
    guard hours > 0 || minutes > 0 else { return }

    // Минимальные синхронные операции для UI
    SharedData.userDefaults?.set(true, forKey: SharedData.Widget.isBlocked)
    // Сохраняем timestamp начала блокировки
    SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
    
    // Сохраняем токены приложений и категорий для логирования
    var allTokens: [ApplicationToken] = []
    
    // Добавляем токены приложений
    allTokens.append(contentsOf: selection.applicationTokens)
    
    // Добавляем токены из категорий
    for category in selection.categoryTokens {
      // Категория содержит несколько приложений, но мы не можем получить их токены напрямую
      // Поэтому создаем фиктивный токен для категории
      // В реальности категория блокирует все приложения в ней
    }
    
    // Если нет отдельных приложений, но есть категории, создаем хотя бы один токен для логирования
    if allTokens.isEmpty && !selection.categoryTokens.isEmpty {
      // Используем фиктивный токен для представления категорий
      // Это нужно только для статистики
      print("BlockingNotificationService: Using categories, not individual apps")
    }
    
    let appTokens = allTokens
    
    let (endHour, endMin) = getEndTime(hourDuration: hours, minuteDuration: minutes)
    restrictionModel.endHour = endHour
    restrictionModel.endMins = endMin
    
    // Устанавливаем дату разблокировки сразу для UI
    if DeviceActivityService.shared.unlockDate == nil || (DeviceActivityService.shared.unlockDate ?? Date()) <= Date() {
      DeviceActivityService.shared.setUnlockDate(hour: endHour, minute: endMin)
      // Also save to SharedData for extensions and app restart
      if let unlockDate = DeviceActivityService.shared.unlockDate {
        SharedData.userDefaults?.set(unlockDate, forKey: SharedData.AppBlocking.unlockDate)
      }
    }

    // Все тяжелые операции в фоне
    Task {
      // Сохраняем выбор приложений
      await DeviceActivityService.shared.saveFamilyActivitySelectionAsync(selection)
      
      // Устанавливаем время
      let now = Date()
      let calendar = Calendar.current
      await MainActor.run {
        restrictionModel.startHour = calendar.component(.hour, from: now)
        restrictionModel.startMin = calendar.component(.minute, from: now)
      }
      
      // Сохраняем для виджетов
      await saveWidgetData(endHour: endHour, endMin: endMin)
      
      // Устанавливаем расписание
      await DeviceActivityScheduleService.setScheduleAsync(endHour: endHour, endMins: endMin)
      
      // Устанавливаем ограничения - самая тяжелая операция
      await DeviceActivityService.shared.setShieldRestrictionsAsync(restrictionModel.isStricted)
    }

    // Log blocking session using new AppBlockingLogger
    let plannedDuration = TimeInterval(hours * 3600 + minutes * 60)
    Task { @MainActor in
      if !appTokens.isEmpty {
        print("BlockingNotificationService: Starting blocking with \(appTokens.count) apps")
        _ = AppBlockingLogger.shared.startAppBlockingSession(
          apps: appTokens,
          duration: plannedDuration
        )
      } else if !selection.categoryTokens.isEmpty {
        print("BlockingNotificationService: Starting blocking with categories")
        _ = AppBlockingLogger.shared.startAppBlockingSessionForCategories(
          duration: plannedDuration
        )
      } else {
        print("BlockingNotificationService: No apps or categories selected for blocking")
      }
    }
  }

  func stopBlocking(selection: FamilyActivitySelection) {
    
    // Cancel related notifications
    LocalNotificationManager.shared.cancelNotifications(identifiers: ["blocking-end"])

    SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
    SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)

    Task { @MainActor in
      DeviceActivityService.shared.savedSelection.removeAll()
    }
    SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endHour)
    SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endMinutes)

//    WidgetCenter.shared.reloadAllTimelines()


    // Complete blocking session using new AppBlockingLogger
    Task { @MainActor in
      if let currentSession = AppBlockingLogger.shared.getCurrentSession(type: .appBlocking) {
        print("BlockingNotificationService: Ending blocking session \(currentSession.id)")
        AppBlockingLogger.shared.endSession(sessionId: currentSession.id, completed: true)
      } else {
        print("BlockingNotificationService: No current app blocking session to end")
      }
    }
    
    resetBlockingState()
  }

  func resetBlockingState() {
    let service = DeviceActivityService.shared
    
    Task { @MainActor in
      // Don't clear selectionToDiscourage - keep it for next time
      service.savedSelection.removeAll()
      service.unlockDate = nil
    }
    
    // Don't save empty selection - keep the saved apps for next use
    
    SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
    service.stopAppRestrictions()
    
    // Interrupt current blocking session using new AppBlockingLogger
    Task { @MainActor in
      if let currentSession = AppBlockingLogger.shared.getCurrentSession(type: .appBlocking) {
        AppBlockingLogger.shared.endSession(sessionId: currentSession.id, completed: false)
      }
    }
  }

  private func saveWidgetData(endHour: Int, endMin: Int) async {
    await withCheckedContinuation { continuation in
      SharedData.userDefaults?.set(endHour, forKey: SharedData.Widget.endHour)
      SharedData.userDefaults?.set(endMin, forKey: SharedData.Widget.endMinutes)
      continuation.resume()
    }
  }
  
  func getEndTime(hourDuration: Int, minuteDuration: Int) -> (Int, Int) {
    let now = Date()
    let calendar = Calendar.current
    if let endDate = calendar.date(byAdding: .minute, value: hourDuration * 60 + minuteDuration, to: now) {
      let comps = calendar.dateComponents([.hour, .minute], from: endDate)
      return (comps.hour ?? 0, comps.minute ?? 0)
    }
    return (0, 0)
  }
}
