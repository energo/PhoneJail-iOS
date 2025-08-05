//
//  BlockingNotificationService.swift
//  AntiSocial
//
//  Created by D C on 17.07.2025.
//

import Foundation
import WidgetKit
import FamilyControls
import DeviceActivity


final class BlockingNotificationServiceForInterruptions: ObservableObject {
  static let shared = BlockingNotificationServiceForInterruptions()
  private init() {}

  func startBlocking(
    hours: Int,
    minutes: Int,
    selection: FamilyActivitySelection,
    restrictionModel: MyRestrictionModel
  ) {
    guard hours > 0 || minutes > 0 else { return }

    // Mark as interruption block (not main block)
    SharedData.userDefaults?.set(true, forKey: SharedData.ScreenTime.isInterruptionBlock)

    // Apply shield restrictions to interruption store
    DeviceActivityService.shared.setShieldRestrictions(for: selection, storeName: .interruption)

    // Time setup
    let now = Date()
    let calendar = Calendar.current
    restrictionModel.startHour = calendar.component(.hour, from: now)
    restrictionModel.startMin = calendar.component(.minute, from: now)

    let (endHour, endMin) = getEndTime(hourDuration: hours, minuteDuration: minutes)
    restrictionModel.endHour = endHour
    restrictionModel.endMins = endMin

    // Don't save main blocking data for interruptions

//    WidgetCenter.shared.reloadAllTimelines()

    // Set schedule for interruption
    DeviceActivityScheduleService.setInterruptionSchedule(endHour: endHour, endMins: endMin, selection: selection)
    
    // Notification already sent from DeviceActivityMonitorExtension

    // Save interruption timestamp
    SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedData.AppBlocking.lastInterruptionBlockTime)
  }

  func stopBlocking(selection: FamilyActivitySelection) {
    SharedData.userDefaults?.set(false, forKey: SharedData.ScreenTime.isInterruptionBlock)
    SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.lastInterruptionBlockTime)

//    WidgetCenter.shared.reloadAllTimelines()

    DeviceActivityCenter().stopMonitoring([.appBlockingInterruption])
    resetBlockingState()
  }

  func resetBlockingState() {
    // Clear interruption-specific restrictions
    SharedData.userDefaults?.set(false, forKey: SharedData.ScreenTime.isInterruptionBlock)
    DeviceActivityService.shared.stopAppRestrictions(storeName: .interruption)
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
