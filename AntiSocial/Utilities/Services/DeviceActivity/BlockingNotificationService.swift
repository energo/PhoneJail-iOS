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
    restrictionModel: MyRestrictionModel,
    animationDelay: TimeInterval = 0
  ) {
    guard hours > 0 || minutes > 0 else { return }
    
    // Минимальные синхронные операции для UI
    SharedData.userDefaults?.set(true, forKey: SharedData.Widget.isBlocked)
    // Сохраняем timestamp начала блокировки
    SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
    
    // Here is can be used animationDelay to compensate delay
    let compensatedDuration = TimeInterval(hours * 3600 + minutes * 60) + animationDelay
    let compensatedMinutes = Int(compensatedDuration) / 60
    
    // Получаем endHour и endMin с учетом компенсации
    let (endHour, endMin, endSec) = getEndTime(hourDuration: 0, minuteDuration: compensatedMinutes)
    // TODO: - Check if MyRestrictionModel is needed, seems like it has no real usage in code
    restrictionModel.endHour = endHour
    restrictionModel.endMins = endMin
    
    // Setting unlockDate with animation delay
    let totalSeconds = Int(compensatedDuration)
    let adjustedHours = totalSeconds / 3600
    let adjustedMinutes = (totalSeconds % 3600) / 60
    
    ShieldService.shared.setUnlockDuration(hours: adjustedHours, minutes: adjustedMinutes)
    
    if let unlockDate = ShieldService.shared.unlockDate {
      SharedData.userDefaults?.set(unlockDate, forKey: SharedData.AppBlocking.unlockDate)
    }
    // Сохраняем выбор приложений
    ShieldService.shared.saveFamilyActivitySelectionAsync(selection)
    
    // Устанавливаем время
    Task { @MainActor in
      DeviceActivityScheduleService.setSchedule(endHour: endHour, endMins: endMin, endSec: endSec)
      ShieldService.shared.setShieldRestrictions(restrictionModel.isStricted)
    }
    
    // Log blocking session using new AppBlockingLogger
    let plannedDuration = TimeInterval(hours * 3600 + minutes * 60)
    logPlannedDuration(plannedDuration, selection: selection)
    
    
    let now = Date()
    let calendar = Calendar.current
    
    let startDate = now
    let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
    
    let year = startComponents.year ?? 1
    let month = startComponents.month ?? 1
    let day = startComponents.day ?? 1
    
    var endDate = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMin, second: endSec))!
    // If end time is before current time, it means it's for tomorrow
    if endDate < now {
      endDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
    }
    
    // Schedule notifications
    LocalNotificationManager.shared.scheduleBlockingStartNotification()
    LocalNotificationManager.shared.scheduleBlockingEndNotification(
      at: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMin, second: endSec)
    )
    
    restrictionModel.startHour = calendar.component(.hour, from: now)
    restrictionModel.startMin  = calendar.component(.minute, from: now)
  }
  
  func stopBlocking(selection: FamilyActivitySelection) {
    
    // Cancel related notifications
    LocalNotificationManager.shared.cancelNotifications(identifiers: ["blocking-end"])
    
    SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
    SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
    
    Task { @MainActor in
      ShieldService.shared.stopAppRestrictions()
      DeviceActivityScheduleService.stopSchedule()
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
  
  private func saveWidgetData(endHour: Int, endMin: Int) {
    SharedData.userDefaults?.set(endHour, forKey: SharedData.Widget.endHour)
    SharedData.userDefaults?.set(endMin, forKey: SharedData.Widget.endMinutes)
  }
  
  func getEndTime(hourDuration: Int, minuteDuration: Int) -> (Int, Int, Int) {
    let now = Date()
    let calendar = Calendar.current
    if let endDate = calendar.date(byAdding: .minute, value: hourDuration * 60 + minuteDuration, to: now) {
      let comps = calendar.dateComponents([.hour, .minute, .second], from: endDate)
      return (comps.hour ?? 0, comps.minute ?? 0, comps.second ?? 0)
    }
    return (0, 0, 0)
  }
}
