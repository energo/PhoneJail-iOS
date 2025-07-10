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
  
  //TODO: Refactoring 
//  func scheduleRoutineItemCompletionNotification(for item: RoutineItem) {
//    let content = UNMutableNotificationContent()
//    content.title = "\(item.title) Time has finished"
//    content.body = "Did you complete it?"
//    content.sound = .default
//    
//    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//    let request = UNNotificationRequest(identifier: item.id, content: content, trigger: trigger)
//    
//    notificationCenter.add(request) { error in
//      if let error = error {
//        print("❌ Failed to schedule notification for \(item.id): \(error)")
//      }
//    }
//  }
//  
//  func scheduleRoutineItemStartNotification(for item: RoutineItem, ritual: RitualPackage) {
//    guard let startTime = item.startTime else {
//      print("⚠️ startTime is nil for item \(item.id), skipping notification")
//      return
//    }
//    
//    let calendar = Calendar.current
//    let components = calendar.dateComponents([.hour, .minute], from: startTime)
//    
//    let content = UNMutableNotificationContent()
//    content.title = "\(ritual.title)"
//    content.body = "\(item.title)"
//    content.sound = .default
//    
//    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
//    let request = UNNotificationRequest(identifier: item.id, content: content, trigger: trigger)
//    
//    notificationCenter.add(request) { error in
//      if let error = error {
//        print("❌ Failed to schedule daily notification for \(item.id): \(error)")
//      } else {
//        print("🔔 Scheduled daily notification for \(item.title) at \(components.hour ?? 0):\(components.minute ?? 0)")
//      }
//    }
//  }
//  
//  func rescheduleFirstRoutineItemNotification(from oldPackage: RitualPackage?, to newPackage: RitualPackage) {
//    if let oldFirstItem = oldPackage?.items.first {
//      self.cancelRoutineItemNotification(for: oldFirstItem)
//    }
//    
//    guard let newFirstItem = newPackage.items.first else {
//      print("⚠️ No first item in new package to schedule")
//      return
//    }
//    
//    self.scheduleRoutineItemStartNotification(for: newFirstItem, ritual: newPackage)
//  }
//  
//  func cancelRoutineItemNotification(for item: RoutineItem) {
//    notificationCenter.removePendingNotificationRequests(withIdentifiers: [item.id])
//    print("🔕 Canceled daily notification for item \(item.title)")
//  }
//  
//  func schedule40PercentProgressNotification(for item: RoutineItem, after delay: TimeInterval) {
//    let content = UNMutableNotificationContent()
//    //      content.title = "Almost halfway!"
//    //      content.body = "You've completed 40% of \(item.title). Keep going! 💪"
//    content.title = "Done with \(item.title)?"
//    content.body = "Tap here to finish"
//    content.sound = .default
//    
//    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
//    let request = UNNotificationRequest(
//      identifier: "routineItem_\(item.id)_40percent",
//      content: content,
//      trigger: trigger
//    )
//    
//    UNUserNotificationCenter.current().add(request) { error in
//      if let error = error {
//        print("❌ Failed to schedule 40% notification: \(error)")
//      } else {
//        print("✅ Scheduled 40% progress notification for \(item.title)")
//      }
//    }
//  }
//  
//  func cancel40PercentNotification(for item: RoutineItem) {
//    let id = "routineItem_\(item.id)_40percent"
//    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
//    print("🗑 Canceled 40% progress notification for \(item.title)")
//  }
}
