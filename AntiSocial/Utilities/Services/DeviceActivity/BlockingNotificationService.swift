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
    UserDefaults.standard.set(true, forKey: "inRestrictionMode")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(true, forKey:"widgetInRestrictionMode")

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
    UserDefaults.standard.set(endHour, forKey: "endHour")
    UserDefaults.standard.set(endMin, forKey: "endMins")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(endHour, forKey:"widgetEndHour")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(endMin, forKey:"widgetEndMins")

    WidgetCenter.shared.reloadAllTimelines()

    // Set schedule
    DeviceActivityScheduleService.setSchedule(endHour: endHour, endMins: endMin)

    // Save usage forecast
    let today = Date()
    for app in selection.applications {
      FocusedTimeStatsStore.shared.saveUsage(for: app.localizedDisplayName ?? "App", date: today, duration: TimeInterval(hours * 3600 + minutes * 60))
    }

    UserDefaults(suiteName: "group.ScreenTimeTestApp.sharedData")?.set(Date().timeIntervalSince1970, forKey: "restrictionStartTime")
  }

  func stopBlocking(selection: FamilyActivitySelection) {
    UserDefaults.standard.set(false, forKey: "inRestrictionMode")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(false, forKey:"widgetInRestrictionMode")

    DeviceActivityService.shared.savedSelection.removeAll()
    UserDefaults.standard.removeObject(forKey: "endHour")
    UserDefaults.standard.removeObject(forKey: "endMins")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.removeObject(forKey:"widgetEndHour")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.removeObject(forKey:"widgetEndMins")

    WidgetCenter.shared.reloadAllTimelines()

    // Save real usage duration
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
    UserDefaults.standard.set(false, forKey: "inRestrictionMode")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(false, forKey:"widgetInRestrictionMode")
    service.stopAppRestrictions()
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
