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
  
  // Track last trigger time to prevent rapid re-triggers
  private var lastInterruptionTrigger: Date?
  private var lastAlertTrigger: Date?
  private let minimumTriggerInterval: TimeInterval = 60 // 1 minute minimum between triggers
  
  //MARK: - Interval Start/End
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    scheduleNotification(with: "The monitoring session has started",
                         details: "\(activity.rawValue)")
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    
    DeviceActivityService.shared.stopAppRestrictions()
    
    scheduleNotification(with: "The monitoring session has finished",
                         details: "\(activity.rawValue)")
  }
  
  //MARK: - Threshold
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    
    // Check if this is an interruption event (could be interruption_1, interruption_2, etc)
    if event.rawValue.contains(DeviceActivityEvent.Name.interruption.rawValue) {
      // Check if enough time has passed since last trigger
      let now = Date()
      if let lastTrigger = lastInterruptionTrigger,
         now.timeIntervalSince(lastTrigger) < minimumTriggerInterval {
        print("Interruption triggered too soon, skipping. Last: \(lastTrigger), Now: \(now)")
        return
      }
      
      lastInterruptionTrigger = now
      print("Interruption event triggered: \(event.rawValue)")
      
      if let selection = SharedData.selectedInterruptionsActivity {
        BlockingNotificationServiceWithoutSaving.shared.startBlocking(
          hours: 0 ,
          minutes: 2,
          selection: selection,
          restrictionModel:  MyRestrictionModel()
        )
      }
    }
    
    // Check if this is a screen alert event (could be screenAlert_1, screenAlert_2, etc)
    if event.rawValue.contains(DeviceActivityEvent.Name.screenAlert.rawValue) {
      // Check if enough time has passed since last trigger
      let now = Date()
      if let lastTrigger = lastAlertTrigger,
         now.timeIntervalSince(lastTrigger) < minimumTriggerInterval {
        print("Alert triggered too soon, skipping. Last: \(lastTrigger), Now: \(now)")
        return
      }
      
      lastAlertTrigger = now
      print("Screen alert event triggered: \(event.rawValue)")
      
      if let selection = SharedData.selectedAlertActivity {
        for application in selection.applications {
          if let displayName = application.localizedDisplayName {
            scheduleNotification(with: "Hey! Time to take a break from this app", details: displayName)
          } else {
            scheduleNotification(with: "Phone Jail", details: "Hey! Time to take a break from this app")
          }
        }
      }
    }
  }
  
  //MARK: - Interval Warnings
  override func intervalWillStartWarning(for activity: DeviceActivityName) {
    super.intervalWillStartWarning(for: activity)
    // Handle the warning before the interval starts.
  }
  
  override func intervalWillEndWarning(for activity: DeviceActivityName) {
    super.intervalWillEndWarning(for: activity)
    // Handle the warning before the interval ends.
  }
  
  override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventWillReachThresholdWarning(event, activity: activity)
    
    // Handle the warning before the event reaches its threshold.
  }
  
  
  
  //MARK: - Notifications
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
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
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
