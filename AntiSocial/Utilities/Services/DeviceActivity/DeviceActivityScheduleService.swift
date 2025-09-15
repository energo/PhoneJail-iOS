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
  static let pomodoro = Self("Pomodoro Focus")
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
    
    var endDate = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMins))!
    
    // If end time is before current time, it means it's for tomorrow
    if endDate < now {
      endDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
    }
    
//    let diffMinutes = Int(endDate.timeIntervalSince(startDate) / 60)
//    AppLogger.notice("DeviceActivityScheduleService: Start time: \(startDate)")
//    AppLogger.notice("DeviceActivityScheduleService: End time: \(endDate)")
//    AppLogger.notice("DeviceActivityScheduleService: Duration in minutes: \(diffMinutes)")
    
          
    // Get current time components for interval start
    let intervalStart = Calendar.current.dateComponents(
        [.hour, .minute, .second],
        from: now
    )
    
    let intervalEnd = Calendar.current.dateComponents(
        [.hour, .minute, .second],
        from: endDate
    )
         
    let activity = DeviceActivityName.appBlocking
    let eventName = DeviceActivityEvent.Name.block
    
    let event = DeviceActivityEvent(
      applications: ShieldService.shared.selectionToDiscourage.applicationTokens,  // ВСЕ выбранные приложения
      categories: ShieldService.shared.selectionToDiscourage.categoryTokens,
      threshold: DateComponents(second: 10)
    )
    
    var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

    events[eventName] = event
        
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
//      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: true
    )
         
    do {
      try center.startMonitoring(activity,
                                 during: schedule,
                                 events: events)
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
    
    let activity = DeviceActivityName.appBlockingInterruption
    let eventName = DeviceActivityEvent.Name.interruption

    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0),
      intervalEnd: intervalEnd,
      repeats: false
    )
    
    // Mark this as interruption block
    SharedData.userDefaults?.set(true, forKey: SharedData.ScreenTime.isInterruptionBlock)
    let event: [DeviceActivityEvent.Name: DeviceActivityEvent]
      event = [ eventName : DeviceActivityEvent(
        applications: SharedData.selectedInterruptionsActivity?.applicationTokens ?? [],
        categories: SharedData.selectedInterruptionsActivity?.categoryTokens ?? [],
        threshold: DateComponents(second: 0)
      )]

    
    // Use separate activity for interruption blocking
    do {
//      try center.startMonitoring(.appBlockingInterruption, during: schedule)
      try center.startMonitoring(activity,
                                 during: schedule,
                                 events: event)

    } catch {
      print("Failed to start interruption schedule: \(error)")
    }
  }
  
  static func stopInterruptionSchedule() {
    center.stopMonitoring([.appBlockingInterruption])
  }

  // MARK: - Pomodoro
  static func setPomodoroSchedule(endAt endDate: Date) {
    let now = Date()
    let intervalStart = Calendar.current.dateComponents([.hour, .minute, .second], from: now)
    let intervalEnd = Calendar.current.dateComponents([.hour, .minute, .second], from: endDate)
    let schedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: false
    )
    do {
      try center.startMonitoring(.pomodoro, during: schedule)
    } catch {
      print("Failed to start Pomodoro schedule: \(error)")
    }
  }
  
  static func setPomodoroSchedule(durationMinutes: Int) {
    let endDate = Calendar.current.date(byAdding: .minute, value: max(1, durationMinutes), to: Date()) ?? Date()
    setPomodoroSchedule(endAt: endDate)
  }
  
  static func stopPomodoroSchedule() {
    center.stopMonitoring([.pomodoro])
  }
}
