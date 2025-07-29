//
//  BlockingNotificationService.swift
//  AntiSocial
//
//  Created by D C on 17.07.2025.
//

import Foundation
import WidgetKit
import FamilyControls



final class BlockingNotificationServiceWithoutSaving: ObservableObject {
  static let shared = BlockingNotificationServiceWithoutSaving()
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

    // Save start timestamp
    SharedDataConstants.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedDataConstants.AppBlocking.currentBlockingStartTimestamp)
  }

  func stopBlocking(selection: FamilyActivitySelection) {
    SharedDataConstants.userDefaults?.set(false, forKey: SharedDataConstants.Widget.isBlocked)
    SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.AppBlocking.currentBlockingStartTimestamp)

    DeviceActivityService.shared.savedSelection.removeAll()
    SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endHour)
    SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endMinutes)

    WidgetCenter.shared.reloadAllTimelines()

    
    resetBlockingState()
  }

  func resetBlockingState() {
    let service = DeviceActivityService.shared
    service.selectionToDiscourage = FamilyActivitySelection()
    service.savedSelection.removeAll()
    service.saveFamilyActivitySelection(service.selectionToDiscourage)
    service.unlockDate = nil
    
    SharedDataConstants.userDefaults?.set(false, forKey: SharedDataConstants.Widget.isBlocked)
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
