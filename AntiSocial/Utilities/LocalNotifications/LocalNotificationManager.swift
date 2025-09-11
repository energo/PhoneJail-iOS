//
//  LocalNotificationManager.swift
//  AntiSocial
//
//  Created by D C on 10.07.2025.
//

import Foundation
import UserNotifications
import SwiftUI

final class LocalNotificationManager {
  static let shared = LocalNotificationManager()
  private let notificationCenter = UNUserNotificationCenter.current()
  
  private init() {}
  
  func requestAuthorization(completion: @escaping (Bool) -> Void) {
    notificationCenter.requestAuthorization(options: [.alert, .sound, .criticalAlert]) { granted, _ in
      DispatchQueue.main.async {
        completion(granted)
      }
    }
  }
  
  // MARK: - Screen Time Notifications  
  func scheduleBlockingStartNotification() {
    let content = UNMutableNotificationContent()
    content.title = "🔒 App Blocking Mode Started"
    content.body = "Your selected apps are now blocked"
    content.categoryIdentifier = "blocking-app"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: "blocking-start", content: content, trigger: trigger)
    
    notificationCenter.add(request) { error in
//      if let error = error {
//        AppLogger.critical(error, details: "Notification scheduling error")
//      }
    }
  }
  
  func scheduleBlockingEndNotification(at dateComponents: DateComponents) {
    let content = UNMutableNotificationContent()
    content.title = "✅ App Blocking Mode Ended"
    content.body = "Great job! Your apps are now accessible"
    content.categoryIdentifier = "blocking-app"
    content.sound = .default

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    let request = UNNotificationRequest(identifier: "blocking-end", content: content, trigger: trigger)
    
    notificationCenter.add(request) { error in
//      if let error = error {
//        AppLogger.critical(error, details: "Notification scheduling error")
//      }
    }
  }
  
  func scheduleScreenTimeNotification(title: String, body: String, identifier: String? = nil, delay: TimeInterval = 1) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
    let timestamp = Date().timeIntervalSince1970
    // Use deterministic identifier to prevent duplicates
    let notificationId = identifier ?? "\(title)-\(body)".replacingOccurrences(of: " ", with: "-")
    let request = UNNotificationRequest(identifier: "\(notificationId)-\(timestamp)", content: content, trigger: trigger)
    
    notificationCenter.add(request) { error in
      if let error = error {
//        AppLogger.critical(error, details: "Error scheduling notification")
      }
    }
  }
  
  func scheduleMonitoringNotification(title: String, details: String = "") {
    // Set delegate if needed
    notificationCenter.delegate = DTNNotificationHandler.shared
    
    requestAuthorization { granted in
      if granted {
        self.scheduleScreenTimeNotification(title: title, body: details)
      } else {
//        AppLogger.alert("Permission denied for notifications")
      }
    }
  }
  
  // MARK: - Generic Notification Methods
  
  func scheduleNotification(
    title: String,
    body: String,
    identifier: String,
    dateComponents: DateComponents,
    repeats: Bool = false
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    notificationCenter.add(request) { error in
      if let error = error {
        // Log error if needed
        print("Failed to schedule notification: \(error)")
      }
    }
  }
  
  func cancelNotifications(identifiers: [String]) {
    notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
  }
  
  // MARK: - Pomodoro Notifications
  
  func schedulePomodoroNotification(
    title: String,
    body: String,
    timeInterval: TimeInterval = 0.1,
    sound: UNNotificationSound? = .default
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.categoryIdentifier = "pomodoro"
    content.sound = sound ?? .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(timeInterval, 0.1), repeats: false)
    let identifier = "pomodoro-\(Date().timeIntervalSince1970)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    print("🔔 LocalNotificationManager: Adding notification request - identifier: \(identifier)")
    notificationCenter.add(request) { error in
      if let error = error {
        print("❌ Failed to schedule Pomodoro notification: \(error)")
      } else {
        print("✅ Pomodoro notification scheduled successfully")
      }
    }
  }
  
  func schedulePomodoroSessionStarted(sessionType: String, nextSession: String, timeInterval: TimeInterval = 0.1) {
    let title: String
    let body: String
    
    if sessionType == "focus" {
      title = "🎯 Focus Session Started!"
      body = "Time to focus! You'll get a \(nextSession == "longBreak" ? "long break" : "short break") after this session."
    } else {
      title = "☕ Break Time Started!"
      body = "Enjoy your break! Focus session will start after this."
    }
    
    print("🔔 LocalNotificationManager: Scheduling pomodoro session started notification - title: \(title), body: \(body), timeInterval: \(timeInterval)")
    schedulePomodoroNotification(title: title, body: body, timeInterval: timeInterval)
  }
  
  func scheduleFocusSessionEnded(timeInterval: TimeInterval) {
    let title = "🎯 Focus Session Ended!"
    let body = "Congratulations! You completed your focus session."
    
    print("🔔 LocalNotificationManager: Scheduling focus session ended notification - timeInterval: \(timeInterval)")
    schedulePomodoroNotification(title: title, body: body, timeInterval: timeInterval)
  }
  
  func scheduleBreakSessionEnded(timeInterval: TimeInterval) {
    let title = "☕ Break Time Ended!"
    let body = "Break time is over. Ready to focus again?"
    
    print("🔔 LocalNotificationManager: Scheduling break session ended notification - timeInterval: \(timeInterval)")
    schedulePomodoroNotification(title: title, body: body, timeInterval: timeInterval)
  }
  
  func schedulePomodoroAllSessionsComplete(totalSessions: Int) {
    let title = "🍅 Pomodoro Complete!"
    let body = "Congratulations! You've completed all \(totalSessions) focus sessions."
    
    schedulePomodoroNotification(
      title: title,
      body: body,
      timeInterval: 0.1,
      sound: .defaultCritical
    )
  }
  
  func cancelAllPomodoroNotifications() {
    notificationCenter.getPendingNotificationRequests { requests in
      let pomodoroIds = requests
        .filter { $0.identifier.hasPrefix("pomodoro-") }
        .map { $0.identifier }
      
      if !pomodoroIds.isEmpty {
        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: pomodoroIds)
      }
    }
  }
  
  func cancelScheduledPomodoroNotifications() {
    notificationCenter.getPendingNotificationRequests { requests in
      let pomodoroIds = requests
        .filter { $0.identifier.hasPrefix("pomodoro-") }
        .map { $0.identifier }
      
      if !pomodoroIds.isEmpty {
        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: pomodoroIds)
        print("🍅 LocalNotificationManager: Cancelled \(pomodoroIds.count) scheduled pomodoro notifications: \(pomodoroIds)")
      } else {
        print("🍅 LocalNotificationManager: No pomodoro notifications to cancel")
      }
    }
  }
}
