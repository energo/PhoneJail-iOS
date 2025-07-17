//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Created by D C on 11.02.2025.
//

import DeviceActivity

import UserNotifications
import FamilyControls


// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
//  let userDefaultsKey = "FamilyActivitySelection"
  
  func scheduleNotification(with title: String, details: String = "") {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if granted {
        let content = UNMutableNotificationContent()
        content.title = title // Using the custom title here
        content.body =  details //"Here is the body text of the notification."
        content.sound = UNNotificationSound.default
        
//        Label(app)
//            .labelStyle(.iconOnly)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false) // 5 seconds from now
        
        let request = UNNotificationRequest(identifier: "MyNotification", content: content, trigger: trigger)
        
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
  
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    
    // Handle the start of the interval.
    print("intervalDidStart \n\(activity)")
//    DarwinNotificationManager.shared.postNotification(name: "com.yourapp.BroadcastStarted")
    
    scheduleNotification(with: "The monitor is now running", details: "\(activity.rawValue)")
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    
    // Handle the end of the interval.
    print("intervalDidEnd \n\(activity)")
//    DarwinNotificationManager.shared.postNotification(name: "com.yourapp.BroadcastStopped")
    scheduleNotification(with: "The monitoring session has finished", details: "\(activity.rawValue)")
  }
  
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    
    // Handle the event reaching its threshold.
    print("eventDidReachThreshold \n\(activity)")

    // Получаем сохранённые данные о выбранных приложениях
    if let selection = SharedData.selectedFamilyActivity {
//      DarwinNotificationManager.shared.postNotification(name: "com.antisocial.Broadcast.eventDidReachThreshold")
      if event.rawValue == DeviceActivityEvent.Name.Shield.rawValue {
        BlockingNotificationServiceWithoutSaving.shared.startBlocking(
          hours: 0 ,
          minutes: 2,
          selection: selection,
          restrictionModel:  MyRestrictionModel()
        )
      }
      
      for application in selection.applications {
          // Проверим, доступно ли отображаемое имя (если система предоставляет)
        print("Приложение выбранные: \(application.localizedDisplayName)")

        if let displayName = application.localizedDisplayName {
              print("Приложение достигло лимита: \(displayName)")
              scheduleNotification(with: "Hey! Time to take a break from this app", details: displayName)
          } else {
              print("Не удалось получить отображаемое имя приложения")
              scheduleNotification(with: "Phone Jail", details: "Hey! Time to take a break from this app")
          }
      }
    } else {
        print("Не удалось получить данные о выбранных приложениях")
    }
  }
  
  override func intervalWillStartWarning(for activity: DeviceActivityName) {
    super.intervalWillStartWarning(for: activity)
    
    // Handle the warning before the interval starts.
    print("intervalWillStartWarning \n\(activity)")
    scheduleNotification(with: "intervalWillStartWarning", details: "\(activity)")

  }
  
  override func intervalWillEndWarning(for activity: DeviceActivityName) {
    super.intervalWillEndWarning(for: activity)
    
    // Handle the warning before the interval ends.
    print("intervalWillEndWarning \n\(activity)")
    
    scheduleNotification(with: "intervalWillEndWarning", details: "\(activity)")
  }
  
  override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventWillReachThresholdWarning(event, activity: activity)
    
    // Handle the warning before the event reaches its threshold.
    print("eventWillReachThresholdWarning \n\(event) \n\(activity)")
    
    DarwinNotificationManager.shared.postNotification(name: "com.yourapp.ReachThresholdWarning")
    
    scheduleNotification(with: "eventWillReachThresholdWarning", details: "\(event) \(activity)")
  }
}
