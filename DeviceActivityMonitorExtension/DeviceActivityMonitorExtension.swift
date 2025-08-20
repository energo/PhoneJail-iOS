//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Created by D C on 11.02.2025.
//

import DeviceActivity
import UserNotifications
import FamilyControls
import ManagedSettings
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
        return "Your thumb needs a break. Put down your phone."
      case 5..<10:
        return "Still scrolling? Time to stop."
      case 10..<15:
        return "Screens won’t cuddle you back. Block your phone."
      case 15..<20:
        return "Put down your phone. Go touch grass. Seriously."
      case 20..<25:
        return "Your future self just rolled their eyes. Log off?"
      case 25..<30:
        return "Plot twist: nothing new on your feed."
      case 30..<35:
        return "Why not get dopamine from the real world?"
      case 35..<40:
        return "This app thinks you’re cute offline."
      case 40..<45:
        return "Congrats. You just beat your high score in procrastination."
      case 45..<50:
        return "Spoiler: You won’t find meaning here."
      case 50..<55:
        return "Breaking news: Your life is happening elsewhere."
      case 55..<60:
        return "Your screen time is judging you."
      case 60..<70:
        return "Achievement unlocked: Wasted time."
      case 70..<80:
        return "Even your battery is tired of this. Block your phone."
      case 80..<90:
        return "If scrolling burned calories, you’d be ripped."
      case 90..<100:
        return "Real life has better graphics. Go live it."
      case 100..<110:
        return "Stop scrolling. Start strolling. (Go take a walk, buddy)"
      case 110..<120:
        return "Go do literally anything cooler than this."
      case 120..<130:
        return "Life > feed. Choose wisely."
      case 130..<140:
        return "Go outside. The graphics are insane."
      case 140..<150:
        return "You’re one scroll away from nothing. Stop."
      case 150..<160:
        return "Endless feed. Endless waste. Stop."
      case 160..<170:
        return "You’re in a loop. Break it."
      case 170..<180:
        return "One more scroll and you officially qualify as furniture."
      case 180..<190:
        return "Breaking news: Your thumb has filed a complaint."
      case 190..<200:
        return "This feed is junk food. Go eat real life."
      case 200..<210:
        return "Nothing new here. Even your feed is bored."
      case 210..<220:
        return "Too much screen time shrinks your attention span to 8 seconds."
      case 220..<230:
        return "Studies show phone use kills focus. But hey, you’re really focused on scrolling."
      case 230..<240:
        return "Life expectancy = ~80 years. You’ll spend 9 of them staring at a rectangle."
      case 240..<250:
        return "Phone addiction raises anxiety by 30%. Keep scrolling if you’re into that."
      case 250..<260:
        return "Heavy phone users sleep an hour less. Worth it?"
      default:
        return "Go live your life — your feed will still be here."
    }
  }
  
  //MARK: - Interval Start/End
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    
    // Check if this is a scheduled block activity
    let activityName = "\(activity.rawValue)"
    if activityName.contains("scheduledBlock_") {
      // Extract schedule ID from activity name
      let scheduleId = activityName.replacingOccurrences(of: "scheduledBlock_", with: "")
      handleScheduledBlockStart(scheduleId: scheduleId)
      return
    }
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    
    logger.log("intervalDidEnd called for activity: \(activity.rawValue)")
    
    // Check if this is a scheduled block activity
    let activityName = "\(activity.rawValue)"
    if activityName.contains("scheduledBlock_") {
      // Extract schedule ID from activity name
      let scheduleId = activityName.replacingOccurrences(of: "scheduledBlock_", with: "")
      handleScheduledBlockEnd(scheduleId: scheduleId)
      return
    }
    
    // Interval ended silently
    // Handle different activities differently
    if activity == .appBlocking {
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
    
    lastAlertTrigger = now
    
    // Check if we need to reset counters (new day)
    checkAndResetDailyCounters()
    
    // Get alert interval - force minimum of 1 minute
    let storedValue = SharedData.userDefaults?.integer(forKey: SharedData.ScreenTime.selectedTime) ?? 0
    let alertIntervalMinutes = max(storedValue, 1)
    
    if let selection = SharedData.selectedAlertActivity {
      
      // Simple approach - track total time for all monitored apps
      let appKey = "total_screen_time"
      
      // Try to get app name from tokenDisplayNameMap by checking all tokens
      var displayName = "your phone"
      for token in selection.applicationTokens {
        let tokenString = String(describing: token)
        if !SharedData.appName(for: tokenString).isEmpty && SharedData.appName(for: tokenString) != "Приложение" {
          displayName = SharedData.appName(for: tokenString)
          break
        }
      }
      
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
  
  // MARK: - Scheduled Block Handlers
  
  private func handleScheduledBlockStart(scheduleId: String) {
    logger.notice("Scheduled block interval started: \(scheduleId)")
    
    // Check if today is in the schedule's days
    if !isTodayInSchedule(scheduleId: scheduleId) {
      logger.notice("Today is not in schedule days for: \(scheduleId)")
      return
    }
    
    // Get schedule data from SharedData
    guard let isStrict = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_strict") as? Bool else {
      logger.error("Failed to get schedule data for: \(scheduleId)")
      return
    }
    
    // Load the selection data
    let decoder = PropertyListDecoder()
    var selection: FamilyActivitySelection?
    if let data = SharedData.userDefaults?.data(forKey: "schedule_\(scheduleId)_selection") {
      selection = try? decoder.decode(FamilyActivitySelection.self, from: data)
    }
    
    // Apply restrictions using ManagedSettingsStore
    let storeName = ManagedSettingsStore.Name("scheduledBlock_\(scheduleId)")
    let store = ManagedSettingsStore(named: storeName)
    
    // Clear any existing settings first
    store.clearAllSettings()
    
    // Apply the restrictions
    if let selection = selection {
      store.shield.applications = selection.applicationTokens
      
      if isStrict {
        // Strict mode - block all categories
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
      } else {
        // Normal mode - only block selected categories
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
      }
      
      store.shield.webDomains = selection.webDomainTokens
    }
    
    // Mark as active in SharedData
    SharedData.userDefaults?.set(true, forKey: "schedule_\(scheduleId)_active")
    SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: "schedule_\(scheduleId)_startTimestamp")
    
    // Send notification
    let scheduleName = SharedData.userDefaults?.string(forKey: "schedule_\(scheduleId)_name") ?? "Schedule"
    LocalNotificationManager.scheduleExtensionNotification(
      title: "📅 \(scheduleName) Active",
      details: "Scheduled apps are now blocked"
    )
  }
  
  private func handleScheduledBlockEnd(scheduleId: String) {
    logger.notice("Scheduled block ended: \(scheduleId)")
    
    // Remove restrictions using ManagedSettingsStore
    let storeName = ManagedSettingsStore.Name("scheduledBlock_\(scheduleId)")
    let store = ManagedSettingsStore(named: storeName)
    
    // Clear all restrictions
    store.clearAllSettings()
    
    // Mark as inactive in SharedData
    SharedData.userDefaults?.set(false, forKey: "schedule_\(scheduleId)_active")
    SharedData.userDefaults?.removeObject(forKey: "schedule_\(scheduleId)_startTimestamp")
    
    // Send notification
    let scheduleName = SharedData.userDefaults?.string(forKey: "schedule_\(scheduleId)_name") ?? "Schedule"
    LocalNotificationManager.scheduleExtensionNotification(
      title: "✅ \(scheduleName) Ended",
      details: "Scheduled apps are now accessible"
    )
  }
  
  private func isTodayInSchedule(scheduleId: String) -> Bool {
    // Check if we have days of week data
    guard let daysArray = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_daysOfWeek") as? [Int] else {
      logger.error("No days of week data for schedule: \(scheduleId)")
      return true // Default to true if no days specified (daily schedule)
    }
    
    // Check if today's weekday is in the schedule
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())
    
    let isInSchedule = daysArray.contains(weekday)
    logger.notice("Today (weekday \(weekday)) is \(isInSchedule ? "IN" : "NOT IN") schedule days: \(daysArray)")
    
    return isInSchedule
  }
}
