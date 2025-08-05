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
    
    // Handle different activities differently
    if activity == .appBlocking {
      // Check if this was an interruption block
      let wasInterruptionBlock = SharedData.userDefaults?.bool(forKey: SharedData.ScreenTime.isInterruptionBlock) ?? false
      
      if wasInterruptionBlock {
        // This is interruption block ending
        LocalNotificationManager.scheduleExtensionNotification(
          title: "✅ Break Over",
          details: "You can use your apps again"
        )
        
        // Clear interruption store
        DeviceActivityService.shared.stopAppRestrictions(storeName: .interruption)
        
        // Clear interruption block flag
        SharedData.userDefaults?.removeObject(forKey: SharedData.ScreenTime.isInterruptionBlock)
        
        // Restart interruption monitoring if still enabled and no main block active
        let isEnabled = SharedData.userDefaults?.bool(forKey: SharedData.ScreenTime.isInterruptionsEnabled) ?? false
        let isMainBlockActive = SharedData.userDefaults?.bool(forKey: SharedData.Widget.isBlocked) ?? false
        if isEnabled && !isMainBlockActive {
          startInterruptionMonitoring()
        }
      } else {
        // This is regular What2Block ending
        LocalNotificationManager.scheduleExtensionNotification(
          title: "✅ Apps Unblocked",
          details: "You can use your apps again"
        )
        
        // Clear regular blocking store
        DeviceActivityService.shared.stopAppRestrictions()
        
        // Clear regular blocking state
        DeviceActivityScheduleService.stopSchedule()
        SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
        SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
        SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endHour)
        SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endMinutes)
        SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.unlockDate)
        
        // After main block ends, restart interruption monitoring if enabled
        let interruptionsEnabled = SharedData.userDefaults?.bool(forKey: SharedData.ScreenTime.isInterruptionsEnabled) ?? false
        if interruptionsEnabled {
          startInterruptionMonitoring()
        }
      }
      
    } else if activity == .appBlockingInterruption {
      // Interruption block ending
      LocalNotificationManager.scheduleExtensionNotification(
        title: "✅ Break Over",
        details: "You can use your apps again"
      )
      
      // Clear shield restrictions for interruption store
      DeviceActivityService.shared.stopAppRestrictions(storeName: .interruption)
      
      // Clear interruption state
      SharedData.userDefaults?.removeObject(forKey: SharedData.ScreenTime.isInterruptionBlock)
      // Interruption schedule is handled by the main schedule system now
      
      // Restart interruption monitoring if enabled
      let isEnabled = SharedData.userDefaults?.bool(forKey: SharedData.ScreenTime.isInterruptionsEnabled) ?? false
      if isEnabled {
        startInterruptionMonitoring()
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
      handleTresholdScreenInterruption(event)
    }
    
    // Check if this is a screen alert event
    if event == DeviceActivityEvent.Name.screenAlert {
      handleTresholdScreenAlert(event)
    }
    
    restartMonitoring(for: activity)
  }
  
  private func handleTresholdScreenAlert(_ event: DeviceActivityEvent.Name) {
    // Check if enough time has passed since last trigger
    let now = Date()
//    if let lastTrigger = lastAlertTrigger,
//       now.timeIntervalSince(lastTrigger) < minimumTriggerInterval {
//      logger.log("Alert triggered too soon, skipping. Last: \(lastTrigger), Now: \(now)")
//      return
//    }
    
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
  }
  
  private func handleTresholdScreenInterruption(_ event: DeviceActivityEvent.Name) {
    // Check if interruptions are enabled
    let interruptionsEnabled = SharedData.userDefaults?.bool(forKey: SharedData.ScreenTime.isInterruptionsEnabled) ?? false
    if !interruptionsEnabled {
      return
    }
    
    // Check if currently in interruption block
    let isInterruptionBlock = SharedData.userDefaults?.bool(forKey: SharedData.ScreenTime.isInterruptionBlock) ?? false
    if isInterruptionBlock {
      // Already in interruption block, skip
      return
    }
    
    // Check if What2Block is active
//      let isMainBlockActive = SharedData.userDefaults?.bool(forKey: SharedData.Widget.isBlocked) ?? false
//      if isMainBlockActive {
//        logger.log("What2Block is active, cannot start interruption block")
//        // Don't start interruption block when main block is active
//        // Just show notification
//        if let selection = SharedData.selectedInterruptionsActivity {
//          LocalNotificationManager.scheduleExtensionNotification(
//            title: "⏰ Time for a break",
//            details: "But apps are already blocked"
//          )
//        }
//        return
//      }
    
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
      SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedData.AppBlocking.lastInterruptionBlockTime)
      
      // Don't stop monitoring - we'll restart it after the interruption block ends
      
      LocalNotificationManager.scheduleExtensionNotification(
        title: "⏸️ Take a Break",
        details: "Apps blocked for 2 minutes"
      )
      
      BlockingNotificationServiceForInterruptions.shared.startBlocking(
        hours: 0,
        minutes: 2,
        selection: selection,
        restrictionModel: MyRestrictionModel()
      )
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
    if let rawMinutes = SharedData.userDefaults?.integer(forKey: SharedData.ScreenTime.selectedInterruptionTime),
       rawMinutes > 0 {
      timeLimitMinutes = rawMinutes
      // Using saved interruption time
    } else {
      timeLimitMinutes = TimeIntervalOption.timeOptions[1].minutes // Default to 5 mins
      // Using default interruption time
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
      // Get stored TimeIntervalOption data (stored as Int rawValue)
      if let rawMinutes = SharedData.userDefaults?.integer(forKey: SharedData.ScreenTime.selectedInterruptionTime),
         rawMinutes > 0 {
        timeLimitMinutes = rawMinutes
        // Using saved interruption time
      } else {
        timeLimitMinutes = TimeIntervalOption.timeOptions[1].minutes // Default to 5 mins
        // Using default interruption time
      }
    } else {
      // For alerts - read time from UserDefaults
      let storedValue = SharedData.userDefaults?.integer(forKey: SharedData.ScreenTime.selectedTime)
      
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
