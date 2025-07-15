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

    // Save restriction mode
    SharedDataConstants.userDefaults?.set(true, forKey: SharedDataConstants.Widget.isBlocked)

    // Save selection
    DeviceActivityService.shared.saveFamilyActivitySelection(selection)

    // Time setup
    let now = Date()
    let calendar = Calendar.current
    restrictionModel.startHour = calendar.component(.hour, from: now)
    restrictionModel.startMin = calendar.component(.minute, from: now)

    let (endHour, endMin) = getEndTime(hourDuration: hours, minuteDuration: minutes)
    restrictionModel.endHour = endHour
    restrictionModel.endMins = endMin

    // Save unlockDate if not already set
    if DeviceActivityService.shared.unlockDate == nil || (DeviceActivityService.shared.unlockDate ?? Date()) <= Date() {
      DeviceActivityService.shared.setUnlockDate(hour: endHour, minute: endMin)
    }

    // Store for widgets
    SharedDataConstants.userDefaults?.set(endHour, forKey: SharedDataConstants.Widget.endHour)
    SharedDataConstants.userDefaults?.set(endMin, forKey: SharedDataConstants.Widget.endMinutes)

    WidgetCenter.shared.reloadAllTimelines()

    // Set schedule
    DeviceActivityScheduleService.setSchedule(endHour: endHour, endMins: endMin)

    // Log blocking sessions for each app
    let plannedDuration = TimeInterval(hours * 3600 + minutes * 60)
    Task { @MainActor in
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

    // Save usage forecast (legacy support)
    let today = Date()
    for app in selection.applications {
      FocusedTimeStatsStore.shared.saveUsage(for: app.localizedDisplayName ?? "App",
                                             date: today,
                                             duration: TimeInterval(hours * 3600 + minutes * 60))
    }

    SharedDataConstants.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedDataConstants.AppBlocking.currentBlockingStartTimestamp)
  }

  func stopBlocking(selection: FamilyActivitySelection) {
    SharedDataConstants.userDefaults?.set(false, forKey: SharedDataConstants.Widget.isBlocked)
    SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.AppBlocking.currentBlockingStartTimestamp)

    DeviceActivityService.shared.savedSelection.removeAll()
    SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endHour)
    SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endMinutes)

    WidgetCenter.shared.reloadAllTimelines()

    // Complete blocking sessions for each app
    Task { @MainActor in
      for app in selection.applications {
        guard let appToken = app.token else { continue }
        if let activeSession = AppBlockingLogger.shared.findActiveSession(for: appToken) {
          do {
            try await AppBlockingLogger.shared.completeBlockingSession(activeSession.id)
          } catch {
            AppLogger.critical(error, details: "Failed to complete blocking session for \(app.localizedDisplayName ?? "Unknown App")")
          }
        }
      }
    }

    // Save real usage duration (legacy support)
    if let startTimestamp = UserDefaults(suiteName: "group.ScreenTimeTestApp.sharedData")?.double(forKey: "restrictionStartTime") {
      let duration = Date().timeIntervalSince1970 - startTimestamp
      let today = Date()
      for app in selection.applications {
        FocusedTimeStatsStore.shared.saveUsage(for: app.localizedDisplayName ?? "App", date: today, duration: duration)
      }
      UserDefaults(suiteName: "group.ScreenTimeTestApp.sharedData")?.removeObject(forKey: "restrictionStartTime")
    }
  }

  func resetBlockingState() {
    let service = DeviceActivityService.shared
    service.selectionToDiscourage = FamilyActivitySelection()
    service.savedSelection.removeAll()
    service.saveFamilyActivitySelection(service.selectionToDiscourage)
    service.unlockDate = nil
    
    SharedDataConstants.userDefaults?.set(false, forKey: SharedDataConstants.Widget.isBlocked)
    service.stopAppRestrictions()
    
    // Interrupt all active blocking sessions
    Task { @MainActor in
      let activeSessions = AppBlockingLogger.shared.activeSessions
      for session in activeSessions {
        do {
          try await AppBlockingLogger.shared.interruptBlockingSession(session.id)
        } catch {
          AppLogger.critical(error, details: "Failed to interrupt blocking session for \(session.appDisplayName)")
        }
      }
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
