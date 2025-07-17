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
  static let daily = Self("daily")
  static let appMonitoring = Self("Monitoring App")
}

extension DeviceActivityEvent.Name {
  static let Shield = Self("Shield.Discouraged")
  static let Interruption = Self("Interruption App")
  static let ScreenAlert = Self("Screen Alert")
}

class DeviceActivityScheduleService {
  static let center = DeviceActivityCenter()
  
  static func setSchedule(endHour: Int, endMins: Int) {
    let now = Date()
    let calendar = Calendar.current
    
    let startDate = now
    let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
    let curHour = startComponents.hour ?? 0
    let curMins = startComponents.minute ?? 0
    
    let year = startComponents.year ?? 1
    let month = startComponents.month ?? 1
    let day = startComponents.day ?? 1
    
    let endDate = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMins))!
    let diffMinutes = Int(endDate.timeIntervalSince(startDate) / 60)
    let duration = DateComponents(minute: diffMinutes)
    
    print("DeviceActivityScheduleService: Start time: \(startDate)")
    print("DeviceActivityScheduleService: End time: \(endDate)")
    print("DeviceActivityScheduleService: Duration in minutes: \(diffMinutes)")
    
    // Schedule notifications
    scheduleNotification(
      title: "Phone Jail",
      body: "You've entered Restriction Mode! Good Luck!",
      dateComponents: startComponents
    )
    
    scheduleNotification(
      title: "Phone Jail",
      body: "Congrats! You've reached the end of Restriction Mode",
      dateComponents: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMins)
    )
    
    print("END TIME: \(endHour):\(endMins)")
    
    // Apply restrictions
    DeviceActivityService.shared.setShieldRestrictions()
    
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: curHour, minute: curMins),
      intervalEnd: DateComponents(hour: endHour, minute: endMins),
      repeats: false
    )
    
    print("DeviceActivityScheduleService: Schedule: \(schedule)")
    
    let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
      .Shield: DeviceActivityEvent(
        applications: DeviceActivityService.shared.selectionToDiscourage.applicationTokens,
        threshold: duration
      )
    ]
    
    do {
      print("Try to start monitoring...")
      try center.startMonitoring(.daily, during: schedule, events: events)
    } catch {
      print("Error monitoring schedule: ", error)
    }
  }
  
  static func stopSchedule() {
    center.stopMonitoring([.daily])
  }
  
  //MARK: - Notifications
  private static func scheduleNotification(title: String, body: String, dateComponents: DateComponents) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.categoryIdentifier = "customIdentifier"
    content.userInfo = ["customData": "fizzbuzz"]
    content.sound = .default
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Notification scheduling error: \(error)")
      }
    }
  }
}

