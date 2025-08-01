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

    // Silent start - no notification needed
    
    // Interruption monitoring started silently
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    
    logger.log("intervalDidEnd called for activity: \(activity.rawValue)")
    
    // Interval ended silently
    
    DeviceActivityService.shared.stopAppRestrictions()
    
    // Clear blocking state when interruption blocking period ends
    if activity == .appBlocking {
      LocalNotificationManager.scheduleExtensionNotification(
        title: "✅ Apps Unblocked",
        details: "You can use your apps again"
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
        
        // Debug info removed
        
        if isEnabled {
          // Restart monitoring
          startInterruptionMonitoring()
        }
      }
    }
    
    // Monitoring finished silently
  }
  
  //MARK: - Threshold
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    
    // Threshold reached - handle silently
    
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
        // Already blocked, skip
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
      
      // Processing interruption
      
      if let selection = SharedData.selectedInterruptionsActivity {
        // Found selection with apps
        
        // Save the current time as last interruption time
        SharedDataConstants.userDefaults?.set(Date().timeIntervalSince1970, forKey: "lastInterruptionBlockTime")
        
        // Stop current interruption monitoring before starting block
        let center = DeviceActivityCenter()
        center.stopMonitoring([.appMonitoringInterruption])
        
        // Stopped monitoring for block
        
        // Start blocking with special flag to indicate it's from interruption
        SharedDataConstants.userDefaults?.set(true, forKey: "isInterruptionBlock")
        
        LocalNotificationManager.scheduleExtensionNotification(
          title: "⏸️ Take a Break",
          details: "Apps blocked for 2 minutes"
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
              title: "⏰ Screen Time Alert",
              details: "Time to take a break from \(displayName)"
            )
          } else {
            LocalNotificationManager.scheduleExtensionNotification(
              title: "⏰ Screen Time Alert",
              details: "Time to take a break from your apps"
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
    // Starting interruption monitoring
    
    let center = DeviceActivityCenter()
    
    // Get the threshold time from UserDefaults
    let timeLimitMinutes: Int
    
    // Read frequency from UserDefaults
    
    // Read from shared group UserDefaults
    // @AppStorage saves RawRepresentable types as their rawValue (Int in this case)
    if let rawMinutes = SharedDataConstants.userDefaults?.integer(forKey: "selectedFrequency"),
       rawMinutes > 0 {
      timeLimitMinutes = rawMinutes
      // Using saved frequency
    } else {
      timeLimitMinutes = 15 // Default to "Often" (15 mins)
      // Using default frequency
    }
    
    // Get the saved selection
    guard let selection = SharedData.selectedInterruptionsActivity else {
      // No apps selected
      return
    }
    
    if selection.applicationTokens.isEmpty {
      // No apps to monitor
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
      // Starting monitoring
      
      try center.startMonitoring(.appMonitoringInterruption, during: schedule, events: events)
      
      // Monitoring started successfully
    } catch {
      logger.log("Failed to start monitoring: \(error.localizedDescription)")
    }
  }
  
  //MARK: - Restart Monitoring
  private func restartMonitoring(for activity: DeviceActivityName) {
    // Restarting monitoring after threshold
    
    let center = DeviceActivityCenter()
    
    // Stop current monitoring
    center.stopMonitoring([activity])
    // Stopped current monitoring
    
    // Get the threshold time from UserDefaults (all data is in shared group)
    let timeLimitMinutes: Int
    if activity == .appMonitoringInterruption {
      // Get stored FrequencyOption data (stored as Int rawValue)
      if let rawMinutes = SharedDataConstants.userDefaults?.integer(forKey: "selectedFrequency"),
         rawMinutes > 0 {
        timeLimitMinutes = rawMinutes
        // Using saved frequency
      } else {
        timeLimitMinutes = 15 // Default to "Often" (15 mins)
        // Using default frequency
      }
    } else {
      // For alerts - read time from UserDefaults
      let storedValue = SharedDataConstants.userDefaults?.integer(forKey: "selectedTime")
      
      // Get stored TimeIntervalOption data (stored as Int rawValue)
      // Note: @AppStorage might not save default values until changed
      if let rawMinutes = storedValue, rawMinutes > 0 {
        timeLimitMinutes = rawMinutes
        // Using saved time
      } else {
        // If no value stored, use the default from TimeIntervalOption.timeOptions[0]
        // This matches the default in AppMonitorViewModel line 32
        timeLimitMinutes = TimeIntervalOption.timeOptions[0].minutes
        // Using default time
      }
    }
    
    // Threshold configured
    
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
      // No selection available
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
      // Restarting monitor
      
      try center.startMonitoring(activity, during: schedule, events: events)
      
      // Monitor restarted successfully
    } catch {
      logger.log("Failed to restart monitoring: \(error.localizedDescription)")
    }
  }
}
