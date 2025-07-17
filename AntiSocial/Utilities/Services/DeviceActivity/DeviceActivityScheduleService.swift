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
}
extension DeviceActivityEvent.Name {
  static let Shield = Self("Shield.Discouraged")
}

class DeviceActivityScheduleService {
  static public func setSchedule(endHour: Int, endMins: Int) {
    let now = Date()
    let calendar = Calendar.current
    
    let startDate = now
    
    let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
    let curHour = startComponents.hour ?? 0
    let curMins = startComponents.minute ?? 0
    
    let year = startComponents.year ?? 1
    let month = startComponents.month ?? 1
    let day = startComponents.day ?? 1
    
    // Вычисляем длительность блокировки в минутах
    let endDate = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMins))!
    let diffMinutes = Int(endDate.timeIntervalSince(startDate) / 60)
    let duration = DateComponents(minute: diffMinutes)
    
    print("DeviceActivityScheduleService: Start time: \(startDate)")
    print("DeviceActivityScheduleService: End time: \(endDate)")
    print("DeviceActivityScheduleService: Duration in minutes: \(diffMinutes)")
    print("DeviceActivityScheduleService: Duration components: \(duration)")

    let notifCenter = UNUserNotificationCenter.current()
    
    // Уведомление о начале
    let startTrigger = UNCalendarNotificationTrigger(dateMatching: startComponents, repeats: false)
    let startContent = UNMutableNotificationContent()
    startContent.title = "Phone Jail"
    startContent.body = "You've entered Restriction Mode! Good Luck!"
    startContent.categoryIdentifier = "customIdentifier"
    startContent.userInfo = ["customData": "fizzbuzz"]
    startContent.sound = .default
    let startRequest = UNNotificationRequest(identifier: UUID().uuidString, content: startContent, trigger: startTrigger)
    notifCenter.add(startRequest) { error in
      if let error = error { print("Start notification error:", error) }
    }
    
    // Уведомление о конце
    let endTrigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(year: year, month: month, day: day, hour: endHour, minute: endMins), repeats: false)
    let endContent = UNMutableNotificationContent()
    endContent.title = "Phone Jail"
    endContent.body = "Congrats! You've reached the end of Restriction Mode"
    endContent.categoryIdentifier = "customIdentifier"
    endContent.userInfo = ["customData": "fizzbuzz"]
    endContent.sound = .default
    let endRequest = UNNotificationRequest(identifier: UUID().uuidString, content: endContent, trigger: endTrigger)
    notifCenter.add(endRequest) { error in
      if let error = error { print("End notification error:", error) }
    }
    
    print("END TIME: \(endHour):\(endMins)")
    
    // Применяем ограничения
    DeviceActivityService.shared.setShieldRestrictions()
    
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: curHour, minute: curMins),
      intervalEnd: DateComponents(hour: endHour, minute: endMins),
      repeats: false
    )
    
    let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
      .Shield: DeviceActivityEvent(
        applications: DeviceActivityService.shared.selectionToDiscourage.applicationTokens,
        threshold: duration
      )
    ]
    
    let center = DeviceActivityCenter()
    do {
      print("Try to start monitoring...")
      try center.startMonitoring(.daily, during: schedule, events: events)
    } catch {
      print("Error monitoring schedule: ", error)
    }
  }
  
  static func stopSchedule() {
    let center = DeviceActivityCenter()
    center.stopMonitoring([.daily])
  }
}
