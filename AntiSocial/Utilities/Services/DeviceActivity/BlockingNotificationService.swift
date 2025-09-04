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
    
    let (endHour, endMin) = getEndTime(hourDuration: hours, minuteDuration: minutes)
    restrictionModel.endHour = endHour
    restrictionModel.endMins = endMin
    
    // Устанавливаем дату разблокировки сразу для UI
    if ShieldService.shared.unlockDate == nil || (ShieldService.shared.unlockDate ?? Date()) <= Date() {
      ShieldService.shared.setUnlockDate(hour: endHour, minute: endMin)
      // Also save to SharedData for extensions and app restart
      if let unlockDate = ShieldService.shared.unlockDate {
        SharedData.userDefaults?.set(unlockDate, forKey: SharedData.AppBlocking.unlockDate)
      }
    }

    // Все тяжелые операции в фоне
    Task {
      // Сохраняем выбор приложений
      await ShieldService.shared.saveFamilyActivitySelectionAsync(selection)
      
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
      await ShieldService.shared.setShieldRestrictionsAsync(restrictionModel.isStricted)
    }

    // Log blocking session using new AppBlockingLogger
    let plannedDuration = TimeInterval(hours * 3600 + minutes * 60)
    logPlannedDuration(plannedDuration, selection: selection)
  }


  func stopBlocking(selection: FamilyActivitySelection) {
    
    // Cancel related notifications
    LocalNotificationManager.shared.cancelNotifications(identifiers: ["blocking-end"])

    SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
    SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)

    Task { @MainActor in
      ShieldService.shared.stopAppRestrictions()
    }
    SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endHour)
    SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endMinutes)
    
    logCompleteSession()
  }
  
  
  private func logCompleteSession() {
    // Complete blocking session using new AppBlockingLogger
    Task { @MainActor in
      if let currentSession = AppBlockingLogger.shared.getCurrentSession(type: .appBlocking) {
        print("BlockingNotificationService: Ending blocking session \(currentSession.id)")
        AppBlockingLogger.shared.endSession(sessionId: currentSession.id, completed: true)
      } else {
        print("BlockingNotificationService: No current app blocking session to end")
      }
    }
  }
  
  private func logPlannedDuration(_ plannedDuration: TimeInterval, selection: FamilyActivitySelection) {
    Task { @MainActor in
      // Всегда логируем сессию, независимо от того, есть ли приложения или категории
      // Если есть отдельные приложения - используем их
      // Если нет приложений, но есть категории - создаем сессию для категорий
      // Если есть и то и другое - все равно логируем с приложениями (категории учитываются через selection)
      
      if !selection.applicationTokens.isEmpty {
        let apps = Array(selection.applicationTokens)
        print("BlockingNotificationService: Starting blocking with \(apps.count) apps and \(selection.categoryTokens.count) categories")
        _ = AppBlockingLogger.shared.startAppBlockingSession(
          apps: apps,
          duration: plannedDuration
        )
      } else if !selection.categoryTokens.isEmpty {
        print("BlockingNotificationService: Starting blocking with \(selection.categoryTokens.count) categories only")
        _ = AppBlockingLogger.shared.startAppBlockingSessionForCategories(
          duration: plannedDuration
        )
      } else {
        print("BlockingNotificationService: Warning - No apps or categories selected for blocking")
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
