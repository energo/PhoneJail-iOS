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
    content.title = "🔒 Restriction Mode Started"
    content.body = "Your selected apps are now blocked"
    content.categoryIdentifier = "customIdentifier"
    content.userInfo = ["customData": "fizzbuzz"]
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: "blocking-start", content: content, trigger: trigger)
    
    notificationCenter.add(request) { error in
      if let error = error {
        print("Notification scheduling error: \(error)")
      }
    }
  }
  
  func scheduleBlockingEndNotification(at dateComponents: DateComponents) {
    let content = UNMutableNotificationContent()
    content.title = "✅ Restriction Mode Ended"
    content.body = "Great job! Your apps are now accessible"
    content.categoryIdentifier = "customIdentifier"
    content.userInfo = ["customData": "fizzbuzz"]
    content.sound = .default
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    let request = UNNotificationRequest(identifier: "blocking-end", content: content, trigger: trigger)
    
    notificationCenter.add(request) { error in
      if let error = error {
        print("Notification scheduling error: \(error)")
      }
    }
  }
  
  func scheduleScreenTimeNotification(title: String, body: String, identifier: String? = nil, delay: TimeInterval = 1) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
    
    // Use deterministic identifier to prevent duplicates
    let notificationId = identifier ?? "\(title)-\(body)".replacingOccurrences(of: " ", with: "-")
    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
    
    notificationCenter.add(request) { error in
      if let error = error {
        print("Error scheduling notification: \(error)")
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
        print("Permission denied for notifications")
      }
    }
  }
}
