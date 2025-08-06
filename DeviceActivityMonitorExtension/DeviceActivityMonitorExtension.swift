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
  private let minimumTriggerInterval: TimeInterval = 120 // 2 minutes minimum between triggers
  
  private let logger = Logger(subsystem: "com.app.antisocial", category: "DeviceActivityMonitor")
  
  // MARK: - Helper Methods
  private func checkAndResetDailyCounters() {
    let calendar = Calendar.current
    let now = Date()
    
    // Get last reset date
    let lastResetTimestamp = SharedData.userDefaults?.double(forKey: "lastUsageCounterReset") ?? 0
    let lastResetDate = Date(timeIntervalSince1970: lastResetTimestamp)
    
    // Check if we're in a new day
    if !calendar.isDateInToday(lastResetDate) {
      // Reset counters
      SharedData.resetAppUsageTimes()
      
      // Save new reset timestamp
      SharedData.userDefaults?.set(now.timeIntervalSince1970, forKey: "lastUsageCounterReset")
      
    }
  }
  
  private func getPersonalizedMessage(for minutes: Int, appName: String) -> String {
    
    switch minutes {
      case 0..<5:
        return "You've spent \(minutes) minutes on \(appName) today. Just getting started?"
      case 5..<10:
        return "You've spent \(minutes) minutes on \(appName) today. Log off?"
      case 10..<15:
        return "You've spent \(minutes) minutes on \(appName) today. Time for a quick check-in."
      case 15..<20:
        return "You've spent \(minutes) minutes on \(appName) today. Quarter hour down!"
      case 20..<25:
        return "You've spent \(minutes) minutes on \(appName) today. Maybe stretch a bit?"
      case 25..<30:
        return "You've spent \(minutes) minutes on \(appName) today. Almost half an hour!"
      case 30..<35:
        return "You've spent \(minutes) minutes on \(appName) today. Break time?"
      case 35..<40:
        return "You've spent \(minutes) minutes on \(appName) today. Take a break?"
      case 40..<45:
        return "You've spent \(minutes) minutes on \(appName) today. Time to refocus?"
      case 45..<50:
        return "You've spent \(minutes) minutes on \(appName) today. Time to put the phone down."
      case 50..<55:
        return "You've spent \(minutes) minutes on \(appName) today. Almost an hour!"
      case 55..<60:
        return "You've spent \(minutes) minutes on \(appName) today. Final warning!"
      case 60..<90:
        return "You've spent \(minutes) minutes on \(appName) today. Time for a real break!"
      case 90..<120:
        return "You've spent \(minutes) minutes on \(appName) today. Seriously?"
      case 120..<180:
        return "You've spent \(minutes) minutes on \(appName) today. This is getting out of hand."
      default:
        return "You've spent \(minutes) minutes on \(appName) today. Time to take a long break!"
    }
  }
  
  //MARK: - Interval Start/End
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    
    logger.log("intervalDidEnd called for activity: \(activity.rawValue)")
    
    // Interval ended silently
    
    // Handle different activities differently
    if activity == .appBlocking {
      // Check if this was an interruption block
//      let wasInterruptionBlock = SharedData.userDefaults?.bool(forKey: SharedData.ScreenTime.isInterruptionBlock) ?? false
//      
//      if wasInterruptionBlock {
//        // This is interruption block ending
//        LocalNotificationManager.scheduleExtensionNotification(
//          title: "✅ Break Over",
//          details: "You can use your apps again"
//        )
//        
//        // Clear interruption store
//        DeviceActivityService.shared.stopAppRestrictions(storeName: .interruption)
//        
//        // Clear interruption block flag
//        SharedData.userDefaults?.removeObject(forKey: SharedData.ScreenTime.isInterruptionBlock)
//        
//        // Restart interruption monitoring if still enabled and no main block active
//        let isEnabled = SharedData.userDefaults?.bool(forKey: SharedData.ScreenTime.isInterruptionsEnabled) ?? false
//        let isMainBlockActive = SharedData.userDefaults?.bool(forKey: SharedData.Widget.isBlocked) ?? false
//        if isEnabled && !isMainBlockActive {
//          startInterruptionMonitoring()
//        }
//      } else {
        // This is regular What2Block ending
        
        // Check if blocking should really end (unlock date might be in the future still)
        let shouldClearState: Bool
        if let unlockDate = SharedData.userDefaults?.object(forKey: SharedData.AppBlocking.unlockDate) as? Date {
          shouldClearState = unlockDate <= Date()
        } else {
          shouldClearState = true
        }
        
        if shouldClearState {
          LocalNotificationManager.scheduleExtensionNotification(
            title: "✅ Apps Unblocked",
            details: "You can use your apps again"
          )
          
          // Clear regular blocking store
          DeviceActivityService.shared.stopAppRestrictions()

          // Clear regular blocking state only if unlock date has passed
          DeviceActivityScheduleService.stopSchedule()
          SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
          SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
          SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endHour)
          SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endMinutes)
          SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.unlockDate)
        } else {
          // Blocking should continue - don't clear timestamp
          logger.log("intervalDidEnd called but unlock date is in future, keeping blocking state")
        }
//      }
      
    } else if activity == .appBlockingInterruption {
      // Interruption block ending
      LocalNotificationManager.scheduleExtensionNotification(
        title: "✅ Interruption Break Over",
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
    let now = Date()
    
    // Check if enough time has passed since last alert
//    if let lastTrigger = lastAlertTrigger,
//       now.timeIntervalSince(lastTrigger) < minimumTriggerInterval {
//      return
//    }
    
    lastAlertTrigger = now
    
    // Check if we need to reset counters (new day)
    checkAndResetDailyCounters()
    
    // Get alert interval - force minimum of 1 minute
    let storedValue = SharedData.userDefaults?.integer(forKey: SharedData.ScreenTime.selectedTime) ?? 0
    let alertIntervalMinutes = max(storedValue, 1)
    
    if let selection = SharedData.selectedAlertActivity {
      // Simple approach - track total time for all monitored apps
      let appKey = "total_screen_time"
      let displayName = selection.applications.first?.localizedDisplayName ?? "your apps"
      
      // Get current usage
      let currentUsageSeconds = SharedData.getAppUsageTime(for: appKey)
      
      // Skip first trigger completely - don't add time, don't send notification
      if currentUsageSeconds == 0 {
        // Mark that we've seen the first trigger by setting a minimal value
        SharedData.updateAppUsageTime(for: appKey, additionalTime: 0.1)
        return
      }
      
      // For all subsequent triggers, add the actual interval time
      let additionalSeconds = Double(alertIntervalMinutes * 60)
      SharedData.updateAppUsageTime(for: appKey, additionalTime: additionalSeconds)
      
      // Get total usage time
      let totalUsageSeconds = SharedData.getAppUsageTime(for: appKey)
      let totalUsageMinutes = Int(totalUsageSeconds / 60)
      
      // Get personalized message
      let message = getPersonalizedMessage(for: totalUsageMinutes, appName: displayName)
      
      LocalNotificationManager.scheduleExtensionNotification(
        title: "⏰ Screen Time Alert",
        details: message
      )
      
      // If no specific apps, send generic message
//      if selection.applicationTokens.isEmpty {
//        LocalNotificationManager.scheduleExtensionNotification(
//          title: "⏰ Screen Time Alert",
//          details: "Time to take a break from your apps"
//        )
//      }
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
      // Don't reset lastAlertTrigger here - we want to maintain the timing
    } catch {
      logger.log("Failed to restart monitoring: \(error.localizedDescription)")
    }
  }
}
