//
//  MySchedule.swift
//  AntiSocial
//
//  Created by D C on 03.07.2025.
//


import Foundation
import DeviceActivity
import UserNotifications

extension DeviceActivityName {
  static let appBlocking = Self("Block Apps")
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
  
  static func setScheduleAsync(endHour: Int, endMins: Int) async {
    await withCheckedContinuation { continuation in
      Task {
        setSchedule(endHour: endHour, endMins: endMins)
        continuation.resume()
      }
    }
  }
  
  static func setSchedule(endHour: Int, endMins: Int) {
    let now = Date()
    let calendar = Calendar.current
    
    let startDate = now
    let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
    
    let year = startComponents.year ?? 1
    let month = startComponents.month ?? 1
    let day = startComponents.day ?? 1
    
    let endDate = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMins))!
    let diffMinutes = Int(endDate.timeIntervalSince(startDate) / 60)
    
//    AppLogger.notice("DeviceActivityScheduleService: Start time: \(startDate)")
//    AppLogger.notice("DeviceActivityScheduleService: End time: \(endDate)")
//    AppLogger.notice("DeviceActivityScheduleService: Duration in minutes: \(diffMinutes)")
    
    // Schedule notifications
    LocalNotificationManager.shared.scheduleBlockingStartNotification()
    LocalNotificationManager.shared.scheduleBlockingEndNotification(
      at: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMins)
    )
          
    let intervalEnd = Calendar.current.dateComponents(
        [.hour, .minute, .second],
        from: Calendar.current.date(byAdding: .minute, value: diffMinutes, to: Date.now) ?? Date.now
    )
    
    let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 0, minute: 0),
        intervalEnd: intervalEnd,
        repeats: false
    )
     
    let activity = DeviceActivityName.appBlocking
    let eventName = DeviceActivityEvent.Name.block
    
    let enabledTokens = DeviceActivityService.shared.selectionToDiscourage.applicationTokens

    let event: [DeviceActivityEvent.Name: DeviceActivityEvent] = [ eventName : DeviceActivityEvent(applications: enabledTokens, threshold: DateComponents(minute: diffMinutes))
    ]
         
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
  }
}

