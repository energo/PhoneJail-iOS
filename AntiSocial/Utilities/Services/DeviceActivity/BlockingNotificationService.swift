//
//  BlockingNotificationService.swift
//  AntiSocial
//
//  Created by D C on 08.07.2025.
//


import Foundation
import WidgetKit
import FamilyControls



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
      AppLogger.notice("Shield restrictions set for blocking session")
    }

    // Log blocking sessions for each app
    let plannedDuration = TimeInterval(hours * 3600 + minutes * 60)
    Task {
      // Выполняем в фоновой очереди, чтобы не блокировать UI
      for app in selection.applications {
        guard let appToken = app.token else { continue }
        do {
          _ = try await AppBlockingLogger.shared.startBlockingSession(
            applicationToken: appToken,
            appDisplayName: app.localizedDisplayName ?? "Unknown App",
            plannedDuration: plannedDuration
          )
        } catch {
          AppLogger.critical(error, details: "Failed to start blocking session for \(app.localizedDisplayName ?? "Unknown App")")
        }
      }
    }
  }

  func stopBlocking(selection: FamilyActivitySelection) {
    AppLogger.alert("stopBlocking selection")
    
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


    // Complete blocking sessions for each app
    Task {
      // Выполняем в фоновой очереди
      for app in selection.applications {
        guard let appToken = app.token else { continue }
        if let activeSession = await AppBlockingLogger.shared.findActiveSession(for: appToken) {
          do {
            try await AppBlockingLogger.shared.completeBlockingSession(activeSession.id)
          } catch {
            AppLogger.critical(error, details: "Failed to complete blocking session for \(app.localizedDisplayName ?? "Unknown App")")
          }
        }
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
    
    // Interrupt all active blocking sessions
    Task {
      // Выполняем в фоновой очереди
      let activeSessions = await AppBlockingLogger.shared.activeSessions
      for session in activeSessions {
        do {
          try await AppBlockingLogger.shared.interruptBlockingSession(session.id)
        } catch {
          AppLogger.critical(error, details: "Failed to interrupt blocking session for \(session.appDisplayName)")
        }
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
