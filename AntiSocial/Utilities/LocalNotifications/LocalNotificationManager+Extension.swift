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
        
        // Use deterministic identifier to prevent duplicates
        let identifier = "\(title)-\(details)".replacingOccurrences(of: " ", with: "-")
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
          if let error = error {
            print("Error scheduling notification: \(error)")
          }
        }
      } else {
        print("Permission denied. \(error?.localizedDescription ?? "")")
      }
    }
  }
}