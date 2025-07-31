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

    LocalNotificationManager.scheduleExtensionNotification(
      title: "The monitoring session has started",
      details: "\(activity.rawValue)"
    )
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    
    DeviceActivityService.shared.stopAppRestrictions()
    
    // Clear blocking state when interruption blocking period ends
    if activity == .appBlocking {
      SharedDataConstants.userDefaults?.set(false, forKey: SharedDataConstants.Widget.isBlocked)
      SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.AppBlocking.currentBlockingStartTimestamp)
      SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endHour)
      SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endMinutes)
      SharedDataConstants.userDefaults?.removeObject(forKey: "UnlockDate")
      
      print("Cleared blocking state after interval end")
    }
    
    LocalNotificationManager.scheduleExtensionNotification(
      title: "The monitoring session has finished",
      details: "\(activity.rawValue)"
    )
  }
  
  //MARK: - Threshold
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    
    // Check if this is an interruption event
    if event == DeviceActivityEvent.Name.interruption {
      // First check if any existing block has expired and clean it up
      if let unlockTimestamp = SharedDataConstants.userDefaults?.object(forKey: "UnlockDate") as? Date,
         unlockTimestamp <= Date() {
        // Unlock date has passed, clear blocking state
        SharedDataConstants.userDefaults?.set(false, forKey: SharedDataConstants.Widget.isBlocked)
        SharedDataConstants.userDefaults?.removeObject(forKey: "UnlockDate")
        SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.AppBlocking.currentBlockingStartTimestamp)
        SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endHour)
        SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endMinutes)
        print("Cleared expired blocking state")
      }
      
      // Now check if we're in an active blocking state
      let isCurrentlyBlocked = SharedDataConstants.userDefaults?.bool(forKey: SharedDataConstants.Widget.isBlocked) ?? false
      if isCurrentlyBlocked {
        print("Currently in blocking state, skipping interruption trigger")
        return
      }
      
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
          hours: 0,
          minutes: 2,
          selection: selection,
          restrictionModel: MyRestrictionModel()
        )
      }
      
      // Restart monitoring for continuous tracking
      restartMonitoring(for: activity)
    }
    
    // Check if this is a screen alert event
    if event == DeviceActivityEvent.Name.screenAlert {
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
            LocalNotificationManager.scheduleExtensionNotification(
              title: "Hey! Time to take a break from this app",
              details: displayName
            )
          } else {
            LocalNotificationManager.scheduleExtensionNotification(
              title: "Phone Jail",
              details: "Hey! Time to take a break from this app"
            )
          }
        }
      }
      
      // Restart monitoring for continuous tracking
      restartMonitoring(for: activity)
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
  
  //MARK: - Restart Monitoring
  private func restartMonitoring(for activity: DeviceActivityName) {
    let center = DeviceActivityCenter()
    
    // Stop current monitoring
    center.stopMonitoring([activity])
    
    // Get the threshold time from UserDefaults
    let timeLimitMinutes: Int
    if activity == .appMonitoringInterruption {
      // Get stored FrequencyOption data
      if let data = SharedDataConstants.userDefaults?.data(forKey: "selectedFrequency"),
         let frequencyOption = try? JSONDecoder().decode(FrequencyOption.self, from: data) {
        timeLimitMinutes = frequencyOption.minutes
      } else {
        timeLimitMinutes = 15 // Default to "Often" (15 mins)
      }
    } else {
      // Get stored TimeIntervalOption data
      if let data = SharedDataConstants.userDefaults?.data(forKey: "selectedTime"),
         let timeOption = try? JSONDecoder().decode(TimeIntervalOption.self, from: data) {
        timeLimitMinutes = timeOption.minutes
      } else {
        timeLimitMinutes = 5 // Default to 5 mins
      }
    }
    
    print("Restarting monitoring for \(activity.rawValue) with threshold: \(timeLimitMinutes) minutes")
    
    // Get the appropriate selection and create event
    let selection: FamilyActivitySelection?
    let eventName: DeviceActivityEvent.Name
    
    if activity == .appMonitoringInterruption {
      selection = SharedData.selectedInterruptionsActivity
      eventName = DeviceActivityEvent.Name.interruption
    } else {
      selection = SharedData.selectedAlertActivity
      eventName = DeviceActivityEvent.Name.screenAlert
    }
    
    guard let selection = selection else {
      print("No selection found for restarting monitoring")
      return
    }
    
    let event = DeviceActivityEvent(
      applications: selection.applicationTokens,
      categories: selection.categoryTokens,
      webDomains: selection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes)
    )
    
    let events = [eventName: event]
    
    // Create 24h schedule
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
      repeats: true
    )
    
    // Restart monitoring
    do {
      try center.startMonitoring(activity, during: schedule, events: events)
      print("Successfully restarted monitoring for \(activity.rawValue)")
    } catch {
      print("Failed to restart monitoring: \(error)")
    }
  }
}
