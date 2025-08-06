//
//  LocalNotificationManager+Extension.swift
//  AntiSocial
//
//  Created by D C on 31.07.2025.
//

import Foundation
import UserNotifications

// Extension accessible from app extensions
extension LocalNotificationManager {
  
  // Static method that can be called from app extensions
  static func scheduleExtensionNotification(title: String, details: String = "", delay: TimeInterval = 1) {
    let center = UNUserNotificationCenter.current()
    center.delegate = DTNNotificationHandler.shared
    
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if granted {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = details
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // Create unique identifier with timestamp for screen time alerts
        let timestamp = Date().timeIntervalSince1970
        let identifier = "\(title)-\(details)-\(timestamp)".replacingOccurrences(of: " ", with: "-")
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
          if let error = error {
//            AppLogger.critical(error, details: "Error scheduling notification")
          }
        }
      } else {
//        AppLogger.alert("Permission denied. \(error?.localizedDescription ?? "")")
      }
    }
  }
}
