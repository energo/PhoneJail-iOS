//
//  MySchedule.swift
//  AntiSocial
//
//  Created by D C on 03.07.2025.
//


import Foundation
import DeviceActivity
import UserNotifications
import FamilyControls
import ManagedSettings


extension DeviceActivityName {
  static let appBlocking = Self("Block Apps")
  static let appBlockingInterruption = Self("Block Apps Interruption")
  static let appMonitoringAlert = Self("Monitoring Alert App")
  static let appMonitoringInterruption = Self("Monitoring Interruption App")
}

extension DeviceActivityEvent.Name {
  static let block = Self("Block Apps")
  static let interruption = Self("Interruption App")
  static let screenAlert = Self("Screen Alert")
}

class DeviceActivityScheduleService {
  static let center = DeviceActivityCenter()
  
  static func setScheduleAsync(endHour: Int, endMins: Int, isInterruption: Bool = false) async {
    await withCheckedContinuation { continuation in
      Task {
        setSchedule(endHour: endHour, endMins: endMins, isInterruption: isInterruption)
        continuation.resume()
      }
    }
  }
  
  static func setSchedule(endHour: Int, endMins: Int, isInterruption: Bool = false) {
    let now = Date()
    let calendar = Calendar.current
    
    let startDate = now
    let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
    
    let year = startComponents.year ?? 1
    let month = startComponents.month ?? 1
    let day = startComponents.day ?? 1
    
    var endDate = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMins))!
    
    // If end time is before current time, it means it's for tomorrow
    if endDate < now {
      endDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
    }
    
//    let diffMinutes = Int(endDate.timeIntervalSince(startDate) / 60)
//    AppLogger.notice("DeviceActivityScheduleService: Start time: \(startDate)")
//    AppLogger.notice("DeviceActivityScheduleService: End time: \(endDate)")
//    AppLogger.notice("DeviceActivityScheduleService: Duration in minutes: \(diffMinutes)")
    
    // Schedule notifications
    LocalNotificationManager.shared.scheduleBlockingStartNotification()
    LocalNotificationManager.shared.scheduleBlockingEndNotification(
      at: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMins)
    )
          
    // Get current time components for interval start
    let intervalStart = Calendar.current.dateComponents(
        [.hour, .minute, .second],
        from: now
    )
    
    let intervalEnd = Calendar.current.dateComponents(
        [.hour, .minute, .second],
        from: endDate
    )
    
    let schedule = DeviceActivitySchedule(
        intervalStart: intervalStart,
        intervalEnd: intervalEnd,
        repeats: false
    )
     
    let activity = DeviceActivityName.appBlocking
    let eventName = DeviceActivityEvent.Name.block
    
    // Use different tokens based on type
    let enabledTokens: Set<ApplicationToken>
    if isInterruption {
      // For interruptions, use the interruption selection
      enabledTokens = SharedData.selectedInterruptionsActivity?.applicationTokens ?? []
      // Mark this as interruption block
      SharedData.userDefaults?.set(true, forKey: SharedData.ScreenTime.isInterruptionBlock)
    } else {
      // For regular blocking, use the main selection
      enabledTokens = ShieldService.shared.selectionToDiscourage.applicationTokens
    }

    // For regular blocking, we want immediate effect, not a threshold
    let event: [DeviceActivityEvent.Name: DeviceActivityEvent]
//    if isInterruption {
//      // Interruptions don't need immediate blocking, they wait for threshold
//      event = [:]
//    } else {
      // Regular blocking should have immediate effect with threshold 0
      event = [ eventName : DeviceActivityEvent(
        applications: enabledTokens, 
        threshold: DateComponents(second: 0)
      )]
//    }
         
    // Убираем DispatchQueue.main.async - это блокирует main thread!
    // setShieldRestrictions уже вызывается в startBlocking
    do {
      try center.startMonitoring(activity,
                                 during: schedule,
                                 events: event)
    } catch {
//      AppLogger.critical(error, details: "Error monitoring schedule")
    }
  }
  
  static func stopSchedule() {
    center.stopMonitoring([.appBlocking])
    
    // Cancel related notifications
    LocalNotificationManager.shared.cancelNotifications(identifiers: ["blocking-start", "blocking-end"])
  }
  
  static func setInterruptionSchedule(endHour: Int, endMins: Int, selection: FamilyActivitySelection) {
    let now = Date()
    let calendar = Calendar.current
    
    // Simple 2-minute schedule from now
    let endDate = calendar.date(byAdding: .minute, value: 2, to: now) ?? now
    let intervalEnd = calendar.dateComponents([.hour, .minute, .second], from: endDate)
    
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0),
      intervalEnd: intervalEnd,
      repeats: false
    )
    
    // Use separate activity for interruption blocking
    do {
      try center.startMonitoring(.appBlockingInterruption, during: schedule)
    } catch {
      print("Failed to start interruption schedule: \(error)")
    }
  }
  
  static func stopInterruptionSchedule() {
    center.stopMonitoring([.appBlockingInterruption])
  }
}

