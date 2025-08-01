//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Created by D C on 11.02.2025.
//

import DeviceActivity
import UserNotifications
import FamilyControls
import os.log


// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  
  // Track last trigger time to prevent rapid re-triggers
  private var lastInterruptionTrigger: Date?
  private var lastAlertTrigger: Date?
  private let minimumTriggerInterval: TimeInterval = 60 // 1 minute minimum between triggers
  
  private let logger = Logger(subsystem: "com.app.antisocial", category: "DeviceActivityMonitor")
  
  //MARK: - Interval Start/End
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    LocalNotificationManager.scheduleExtensionNotification(
      title: "📱 Monitoring Started",
      details: "Activity: \(activity.rawValue)"
    )
    
    if activity == .appMonitoringInterruption {
      LocalNotificationManager.scheduleExtensionNotification(
        title: "🔄 Interruption Monitoring Active",
        details: "Waiting for usage threshold..."
      )
    }
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    
    logger.log("intervalDidEnd called for activity: \(activity.rawValue)")
    
    LocalNotificationManager.scheduleExtensionNotification(
      title: "🏁 Interval Ended",
      details: "Activity: \(activity.rawValue)"
    )
    
    DeviceActivityService.shared.stopAppRestrictions()
    
    // Clear blocking state when interruption blocking period ends
    if activity == .appBlocking {
      LocalNotificationManager.scheduleExtensionNotification(
        title: "🚫 Blocking Period Ended",
        details: "Processing..."
      )
      
      // Check if this was an interruption block
      let wasInterruptionBlock = SharedDataConstants.userDefaults?.bool(forKey: "isInterruptionBlock") ?? false
      
      // Clear blocking state
      DeviceActivityScheduleService.stopSchedule()
      SharedDataConstants.userDefaults?.set(false, forKey: SharedDataConstants.Widget.isBlocked)
      SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.AppBlocking.currentBlockingStartTimestamp)
      SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endHour)
      SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endMinutes)
      SharedDataConstants.userDefaults?.removeObject(forKey: "UnlockDate")
      SharedDataConstants.userDefaults?.removeObject(forKey: "isInterruptionBlock")
      
      // If it was interruption block, check if interruptions are still enabled
      if wasInterruptionBlock {
        // Check if interruptions are enabled in shared group UserDefaults
        let isEnabled = SharedDataConstants.userDefaults?.bool(forKey: "isInterruptionsEnabled") ?? false
        
        LocalNotificationManager.scheduleExtensionNotification(
          title: "✅ Was Interruption Block",
          details: "Enabled: \(isEnabled)"
        )
        
        if isEnabled {
          // Restart monitoring
          startInterruptionMonitoring()
        } else {
          LocalNotificationManager.scheduleExtensionNotification(
            title: "⚠️ Interruptions Disabled",
            details: "User turned off interruptions"
          )
        }
      }
    }
    
    LocalNotificationManager.scheduleExtensionNotification(
      title: "The monitoring session has finished",
      details: "\(activity.rawValue)"
    )
  }
  
  //MARK: - Threshold
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    
    LocalNotificationManager.scheduleExtensionNotification(
      title: "⏰ Threshold Reached",
      details: "Event: \(event.rawValue), Activity: \(activity.rawValue)"
    )
    
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
        logger.log("Cleared expired blocking state")
      }
      
      // Now check if we're in an active blocking state
      let isCurrentlyBlocked = SharedDataConstants.userDefaults?.bool(forKey: SharedDataConstants.Widget.isBlocked) ?? false
      if isCurrentlyBlocked {
        LocalNotificationManager.scheduleExtensionNotification(
          title: "⚠️ Already Blocked",
          details: "Skipping interruption trigger"
        )
        return
      }
      
      // Check if enough time has passed since last trigger
      let now = Date()
      if let lastTrigger = lastInterruptionTrigger,
         now.timeIntervalSince(lastTrigger) < minimumTriggerInterval {
        logger.log("Interruption triggered too soon, skipping. Last: \(lastTrigger), Now: \(now)")
        return
      }
      
      lastInterruptionTrigger = now
      
      LocalNotificationManager.scheduleExtensionNotification(
        title: "🚨 Interruption Triggered",
        details: "Processing interruption..."
      )
      
      if let selection = SharedData.selectedInterruptionsActivity {
        LocalNotificationManager.scheduleExtensionNotification(
          title: "✅ Selection Found",
          details: "Apps: \(selection.applicationTokens.count)"
        )
        
        // Save the current time as last interruption time
        SharedDataConstants.userDefaults?.set(Date().timeIntervalSince1970, forKey: "lastInterruptionBlockTime")
        
        // Stop current interruption monitoring before starting block
        let center = DeviceActivityCenter()
        center.stopMonitoring([.appMonitoringInterruption])
        
        LocalNotificationManager.scheduleExtensionNotification(
          title: "🛑 Stopped Monitoring",
          details: "Interruption monitoring stopped"
        )
        
        // Start blocking with special flag to indicate it's from interruption
        SharedDataConstants.userDefaults?.set(true, forKey: "isInterruptionBlock")
        
        LocalNotificationManager.scheduleExtensionNotification(
          title: "🚀 Starting Block",
          details: "2-minute interruption block"
        )
        
        BlockingNotificationServiceWithoutSaving.shared.startBlocking(
          hours: 0,
          minutes: 2,
          selection: selection,
          restrictionModel: MyRestrictionModel()
        )
      }
    }
    
    // Check if this is a screen alert event
    if event == DeviceActivityEvent.Name.screenAlert {
      // Check if enough time has passed since last trigger
      let now = Date()
      if let lastTrigger = lastAlertTrigger,
         now.timeIntervalSince(lastTrigger) < minimumTriggerInterval {
        logger.log("Alert triggered too soon, skipping. Last: \(lastTrigger), Now: \(now)")
        return
      }
      
      lastAlertTrigger = now
      logger.log("Screen alert event triggered: \(event.rawValue)")
      
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
  
  //MARK: - Start Interruption Monitoring
  private func startInterruptionMonitoring() {
    LocalNotificationManager.scheduleExtensionNotification(
      title: "🔄 startInterruptionMonitoring",
      details: "Called"
    )
    
    let center = DeviceActivityCenter()
    
    // Get the threshold time from UserDefaults
    let timeLimitMinutes: Int
    
    // Debug: check what's stored and all keys
    let rawValue = SharedDataConstants.userDefaults?.object(forKey: "selectedFrequency")
    let allKeys = SharedDataConstants.userDefaults?.dictionaryRepresentation().keys.map { String($0) }.joined(separator: ", ") ?? "no keys"
    
    LocalNotificationManager.scheduleExtensionNotification(
      title: "🔍 Debug Frequency",
      details: "Type: \(type(of: rawValue)), Exists: \(rawValue != nil)"
    )
    
    LocalNotificationManager.scheduleExtensionNotification(
      title: "🔑 All Keys",
      details: String(allKeys.prefix(100)) // First 100 chars
    )
    
    // Read from shared group UserDefaults
    // @AppStorage saves RawRepresentable types as their rawValue (Int in this case)
    if let rawMinutes = SharedDataConstants.userDefaults?.integer(forKey: "selectedFrequency"),
       rawMinutes > 0 {
      timeLimitMinutes = rawMinutes
      LocalNotificationManager.scheduleExtensionNotification(
        title: "⏱️ Frequency Found",
        details: "\(timeLimitMinutes) minutes"
      )
    } else {
      timeLimitMinutes = 15 // Default to "Often" (15 mins)
      LocalNotificationManager.scheduleExtensionNotification(
        title: "⏱️ Using Default",
        details: "No saved frequency"
      )
    }
    
    // Get the saved selection
    guard let selection = SharedData.selectedInterruptionsActivity else {
      LocalNotificationManager.scheduleExtensionNotification(
        title: "❌ No Selection",
        details: "selectedInterruptionsActivity is nil"
      )
      return
    }
    
    if selection.applicationTokens.isEmpty {
      LocalNotificationManager.scheduleExtensionNotification(
        title: "❌ No Apps",
        details: "Selection has 0 apps"
      )
      return
    }
    
    let event = DeviceActivityEvent(
      applications: selection.applicationTokens,
      categories: selection.categoryTokens,
      webDomains: selection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes)
    )
    
    let events = [DeviceActivityEvent.Name.interruption: event]
    
    // Create 24h schedule
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
      repeats: true
    )
    
    // Start monitoring
    do {
      LocalNotificationManager.scheduleExtensionNotification(
        title: "🎯 Attempting Start",
        details: "Apps: \(selection.applicationTokens.count)"
      )
      
      try center.startMonitoring(.appMonitoringInterruption, during: schedule, events: events)
      
      LocalNotificationManager.scheduleExtensionNotification(
        title: "✅ Monitoring Started",
        details: "Next threshold: \(timeLimitMinutes) min"
      )
    } catch {
      LocalNotificationManager.scheduleExtensionNotification(
        title: "❌ Start Failed",
        details: error.localizedDescription
      )
    }
  }
  
  //MARK: - Restart Monitoring
  private func restartMonitoring(for activity: DeviceActivityName) {
    LocalNotificationManager.scheduleExtensionNotification(
      title: "🔄 Restart Monitoring",
      details: "Activity: \(activity.rawValue)"
    )
    
    let center = DeviceActivityCenter()
    
    // Stop current monitoring
    center.stopMonitoring([activity])
    LocalNotificationManager.scheduleExtensionNotification(
      title: "🛑 Stopped Monitoring",
      details: "Activity: \(activity.rawValue)"
    )
    
    // Get the threshold time from UserDefaults (all data is in shared group)
    let timeLimitMinutes: Int
    if activity == .appMonitoringInterruption {
      // Get stored FrequencyOption data (stored as Int rawValue)
      if let rawMinutes = SharedDataConstants.userDefaults?.integer(forKey: "selectedFrequency"),
         rawMinutes > 0 {
        timeLimitMinutes = rawMinutes
        LocalNotificationManager.scheduleExtensionNotification(
          title: "⏱️ Frequency Found (Restart)",
          details: "\(timeLimitMinutes) minutes"
        )
      } else {
        timeLimitMinutes = 15 // Default to "Often" (15 mins)
        LocalNotificationManager.scheduleExtensionNotification(
          title: "⏱️ Default Frequency (Restart)",
          details: "\(timeLimitMinutes) minutes"
        )
      }
    } else {
      // For alerts - debug what's stored
      let storedValue = SharedDataConstants.userDefaults?.integer(forKey: "selectedTime")
      let objectValue = SharedDataConstants.userDefaults?.object(forKey: "selectedTime")
      
      LocalNotificationManager.scheduleExtensionNotification(
        title: "🔍 Debug Alert Time",
        details: "Int: \(storedValue), Type: \(type(of: objectValue))"
      )
      
      // Additional debug - check if it might be stored as different type
      if let data = objectValue as? Data {
        LocalNotificationManager.scheduleExtensionNotification(
          title: "📦 Found Data",
          details: "Size: \(data.count) bytes"
        )
      }
      
      // Get stored TimeIntervalOption data (stored as Int rawValue)
      // Note: @AppStorage might not save default values until changed
      if let rawMinutes = storedValue, rawMinutes > 0 {
        timeLimitMinutes = rawMinutes
        LocalNotificationManager.scheduleExtensionNotification(
          title: "⏰ Time Found (Restart)",
          details: "\(timeLimitMinutes) minutes"
        )
      } else {
        // If no value stored, use the default from TimeIntervalOption.timeOptions[0]
        // This matches the default in AppMonitorViewModel line 32
        timeLimitMinutes = TimeIntervalOption.timeOptions[0].minutes
        LocalNotificationManager.scheduleExtensionNotification(
          title: "⏰ Using App Default (Restart)",
          details: "\(timeLimitMinutes) minutes - TimeIntervalOption.timeOptions[0]"
        )
      }
    }
    
    LocalNotificationManager.scheduleExtensionNotification(
      title: "🎯 Threshold Set (Restart)",
      details: "\(timeLimitMinutes) minutes for \(activity.rawValue)"
    )
    
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
      LocalNotificationManager.scheduleExtensionNotification(
        title: "❌ No Selection (Restart)",
        details: "Cannot restart \(activity.rawValue)"
      )
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
      LocalNotificationManager.scheduleExtensionNotification(
        title: "🚀 Starting Monitor (Restart)",
        details: "Apps: \(selection.applicationTokens.count)"
      )
      
      try center.startMonitoring(activity, during: schedule, events: events)
      
      LocalNotificationManager.scheduleExtensionNotification(
        title: "✅ Monitor Restarted",
        details: "\(activity.rawValue) - Next: \(timeLimitMinutes)min"
      )
    } catch {
      LocalNotificationManager.scheduleExtensionNotification(
        title: "❌ Restart Failed",
        details: error.localizedDescription
      )
    }
  }
}
