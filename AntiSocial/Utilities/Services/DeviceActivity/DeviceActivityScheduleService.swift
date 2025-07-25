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
         
    DispatchQueue.main.async {
      do {
        DeviceActivityService.shared.setShieldRestrictions()
        
        try center.startMonitoring(activity,
                                   during: schedule,
                                   events: event)
      } catch {
        print("Error monitoring schedule: \(error)")
      }
    }
  }
  
  static func stopSchedule() {
    center.stopMonitoring([.appBlocking])
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

