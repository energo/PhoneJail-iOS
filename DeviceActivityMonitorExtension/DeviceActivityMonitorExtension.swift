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
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  
  // Track last trigger time to prevent rapid re-triggers
  private var lastInterruptionTrigger: Date?
  private var lastAlertTrigger: Date?
  private let minimumTriggerInterval: TimeInterval = 120 // 2 minutes minimum between triggers
  
  private let logger = Logger(subsystem: "com.app.antisocial", category: "DeviceActivityMonitor")
  
  // Helper to save debug info to file for later retrieval
  private func saveDebugInfo(_ info: String, filename: String = "extension_debug.txt") {
    if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.app.antisocial.sharedData") {
      let fileURL = containerURL.appendingPathComponent(filename)
      let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
      let content = "\n[\(timestamp)]\n\(info)\n"
      
      if FileManager.default.fileExists(atPath: fileURL.path) {
        if let handle = try? FileHandle(forWritingTo: fileURL) {
          handle.seekToEndOfFile()
          if let data = content.data(using: .utf8) {
            handle.write(data)
          }
          handle.closeFile()
        }
      } else {
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
      }
    }
  }
  
  
  //MARK: - Interval Start/End
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let timeString = formatter.string(from: Date())
    
    // Check if this is a schedule activity starting
    let activityName = "\(activity.rawValue)"
    if activityName.contains("schedule_") || activityName.contains("scheduledBlock_") {
      let scheduleId: String
      if activityName.contains("scheduledBlock_") {
        scheduleId = activityName.replacingOccurrences(of: "scheduledBlock_", with: "")
      } else {
        scheduleId = activityName.replacingOccurrences(of: "schedule_", with: "")
      }

      
      // Load schedule and apply restrictions
      handleScheduleStart(scheduleId: scheduleId)
      return
    }
    
    // Handle interruption monitoring start - just log, don't trigger anything
    if activity == .appMonitoringInterruption {
      // Only log for debugging, don't send user notifications or trigger blocking
      saveDebugInfo("Interruption monitoring interval started at \(timeString)")
      
      // Log selection info for debugging
      if let selection = SharedData.selectedInterruptionsActivity {
        saveDebugInfo("Monitoring \(selection.applicationTokens.count) apps for interruption threshold")
        logger.notice("Interruption monitoring active for \(selection.applicationTokens.count) apps")
      } else {
        saveDebugInfo("WARNING: Interruption monitoring started but no selection found!")
        logger.warning("Interruption monitoring started but no selection in SharedData")
      }
      // Don't trigger any blocking or notifications here - wait for threshold
      return
    }
    
    // Handle alert monitoring start - just log, don't trigger anything
    if activity == .appMonitoringAlert {
      // Only log for debugging, don't send user notifications
      saveDebugInfo("Alert monitoring interval started at \(timeString)")
      
      // Log selection info for debugging
      if let selection = SharedData.selectedAlertActivity {
        saveDebugInfo("Monitoring \(selection.applicationTokens.count) apps for screen time alerts")
        logger.notice("Alert monitoring active for \(selection.applicationTokens.count) apps")
        
        // Reset usage counters at interval start (new day)
        checkAndResetDailyCounters()
      } else {
        saveDebugInfo("WARNING: Alert monitoring started but no selection found!")
        logger.warning("Alert monitoring started but no selection in SharedData")
      }
      // Don't trigger any alerts here - wait for threshold
      return
    }
    
    // Log any other activities for debugging
    saveDebugInfo("intervalDidStart called for unknown activity: \(activity.rawValue)")
    logger.notice("intervalDidStart for activity: \(activity.rawValue)")
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    
    let activityName = "\(activity.rawValue)"
    
    // Check if this is a schedule activity ending
    if activityName.contains("schedule_") || activityName.contains("scheduledBlock_") {
      let scheduleId: String
      if activityName.contains("scheduledBlock_") {
        scheduleId = activityName.replacingOccurrences(of: "scheduledBlock_", with: "")
      } else {
        scheduleId = activityName.replacingOccurrences(of: "schedule_", with: "")
      }

      // Load schedule and remove restrictions
      handleScheduleEnd(scheduleId: scheduleId)
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
        }
      
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
    
    // Log threshold event
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let timeString = formatter.string(from: Date())
    
    saveDebugInfo("eventDidReachThreshold called - Event: \(event.rawValue), Activity: \(activity.rawValue) at \(timeString)")
    logger.notice("Threshold reached - Event: \(event.rawValue), Activity: \(activity.rawValue)")
    
    // Debug notification only - real notifications will be sent in handlers
    saveDebugInfo("Processing threshold for \(event.rawValue)")
    
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
  
  // MARK: - Screen Time Alert and App Interruption Handlers
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
  
  //MARK: - Schedule Block Handlers
  
  private func handleScheduleEnd(scheduleId: String) {
    // Load all schedules from SharedData
    guard let data = SharedData.userDefaults?.data(forKey: "blockSchedules"),
          let schedules = try? JSONDecoder().decode([BlockSchedule].self, from: data),
          let schedule = schedules.first(where: { $0.id == scheduleId }) else {
      
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "❌ Schedule Not Found End",
//        details: "Could not find schedule with ID: \(scheduleId)"
//      )
      return
    }
    
    // Remove restrictions
    removeScheduledBlockRestrictions(schedule: schedule)
  }
  
  private func handleScheduleStart(scheduleId: String) {
    // Load all schedules from SharedData
    guard let data = SharedData.userDefaults?.data(forKey: "blockSchedules"),
          let schedules = try? JSONDecoder().decode([BlockSchedule].self, from: data),
          let schedule = schedules.first(where: { $0.id == scheduleId }) else {
      
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "❌ Schedule Not Found Start",
//        details: "Could not find schedule with ID: \(scheduleId)"
//      )
      return
    }
    
    
    // Check if today is in the schedule's days
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())
    
    if !schedule.daysOfWeek.contains(weekday) {
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "📅 Not Today",
//        details: "Schedule \(schedule.name) not active on weekday \(weekday)"
//      )
      return
    }
    
    // Apply restrictions
    applyScheduledBlockRestrictions(schedule: schedule)
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
      threshold: DateComponents(minute: timeLimitMinutes),
      includesPastActivity: true  // Include past activity when starting fresh monitoring
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
    
    // When restarting after threshold, don't include past activity
    // This ensures we only count NEW usage from this point forward
    let event = DeviceActivityEvent(
      applications: selection.applicationTokens,
      categories: selection.categoryTokens,
      webDomains: selection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes),
      includesPastActivity: false  // Important: start fresh counting after each threshold
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
    }
  }
  
  // MARK: - Scheduled Block Handlers
  private func applyScheduledBlockRestrictions(schedule: BlockSchedule) {
    let scheduleId = schedule.id
    
    // Apply restrictions using ManagedSettingsStore
    let storeName = ManagedSettingsStore.Name("scheduledBlock_\(scheduleId)")
    let store = ManagedSettingsStore(named: storeName)
    
    // Clear any existing settings first
    store.clearAllSettings()
    
    // Apply shield for visual blocking
    store.shield.applications = schedule.selection.applicationTokens
    
    if schedule.isStrictBlock {
      // Strict mode - block all categories
      store.application.denyAppRemoval = true
    } else {
      // Normal mode - only block selected categories
      store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(schedule.selection.categoryTokens)
    }
    
    store.shield.webDomains = schedule.selection.webDomainTokens
    
    // Mark as active in SharedData
    SharedData.userDefaults?.set(true, forKey: "schedule_\(scheduleId)_active")
    SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: "schedule_\(scheduleId)_startTimestamp")
    
    // Log for Focus Time statistics
    logScheduleSessionStart(schedule: schedule)
  }
  
  private func removeScheduledBlockRestrictions(schedule: BlockSchedule) {
    let scheduleId = schedule.id
    
    // Log session end for statistics
    logScheduleSessionEnd(scheduleId: scheduleId)
    
    // Remove restrictions using ManagedSettingsStore
    let storeName = ManagedSettingsStore.Name("scheduledBlock_\(scheduleId)")
    let store = ManagedSettingsStore(named: storeName)
    
    // Clear all restrictions
    store.clearAllSettings()
    
    // Mark as inactive in SharedData
    SharedData.userDefaults?.set(false, forKey: "schedule_\(scheduleId)_active")
    SharedData.userDefaults?.removeObject(forKey: "schedule_\(scheduleId)_startTimestamp")
    }
  
  // Removed - duplicate method, using the one with BlockSchedule parameter
  private func logScheduleSessionStart(schedule: BlockSchedule) {
    let scheduleId = schedule.id
    let scheduleName = schedule.name
    let selection = schedule.selection
    
    let startTime = Date().timeIntervalSince1970
    
    // Store schedule blocking session start for statistics
    var sessionData: [String: Any] = [
      "scheduleId": scheduleId,
      "scheduleName": scheduleName,
      "startTime": startTime,
      "appCount": selection.applicationTokens.count
    ]
    
    // Store app tokens for session tracking
    let appTokenStrings = selection.applicationTokens.map { String(describing: $0) }
    if let tokensData = try? JSONEncoder().encode(appTokenStrings) {
      sessionData["appTokens"] = tokensData
    }
    
    // Save session data
    if let data = try? JSONSerialization.data(withJSONObject: sessionData) {
      SharedData.userDefaults?.set(data, forKey: "schedule_session_\(scheduleId)")
    }
  }
  
  // Removed - duplicate method, using the one with BlockSchedule parameter
  
  private func logScheduleSessionEnd(scheduleId: String) {
    // Calculate and log blocking time to Focus Time statistics
    if let sessionData = SharedData.userDefaults?.data(forKey: "schedule_session_\(scheduleId)"),
       let sessionInfo = try? JSONSerialization.jsonObject(with: sessionData) as? [String: Any],
       let startTime = sessionInfo["startTime"] as? TimeInterval {
      
      let endTime = Date().timeIntervalSince1970
      let duration = endTime - startTime
      
      // Update total blocking time for today
      let currentTotal = SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.todayTotalBlockingTime) ?? 0
      SharedData.userDefaults?.set(currentTotal + duration, forKey: SharedData.AppBlocking.todayTotalBlockingTime)
      
      // Update completed sessions count
      let currentCount = SharedData.userDefaults?.integer(forKey: SharedData.AppBlocking.todayCompletedSessions) ?? 0
      SharedData.userDefaults?.set(currentCount + 1, forKey: SharedData.AppBlocking.todayCompletedSessions)
      
      // Store detailed session info for statistics
      let calendar = Calendar.current
      let hour = calendar.component(.hour, from: Date())
      let hourlyKey = "hourlyBlockingTime_\(hour)"
      let hourlyTime = SharedData.userDefaults?.double(forKey: hourlyKey) ?? 0
      SharedData.userDefaults?.set(hourlyTime + duration, forKey: hourlyKey)
      
      // Log schedule name and app count for better tracking
      let scheduleName = sessionInfo["scheduleName"] as? String ?? "Schedule"
      let appCount = sessionInfo["appCount"] as? Int ?? 0
      
      
      // Clean up session data
      SharedData.userDefaults?.removeObject(forKey: "schedule_session_\(scheduleId)")
    }
  }
  
  
  private func isTodayInSchedule(scheduleId: String) -> Bool {
    // Check if we have days of week data
    guard let daysArray = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_daysOfWeek") as? [Int] else {
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "📆 No Days Data",
//        details: "Default to true (daily schedule)"
//      )
      return true // Default to true if no days specified (daily schedule)
    }
    
    // Check if today's weekday is in the schedule
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())
    
    let isToday = daysArray.contains(weekday)
    
//    LocalNotificationManager.scheduleExtensionNotification(
//      title: "📅 Day Check",
//      details: "Today: \(weekday), Schedule days: \(daysArray), Match: \(isToday)"
//    )
    
    return isToday
  }
  
  private func isScheduleActiveNow(schedule: BlockSchedule) -> Bool {
    let calendar = Calendar.current
    let now = Date()
    let weekday = calendar.component(.weekday, from: now)
    
    // Check day first
    if !schedule.daysOfWeek.contains(weekday) {
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "❌ Wrong Day",
//        details: "Today (\(weekday)) not in schedule days: \(schedule.daysOfWeek)"
//      )
      return false
    }
    
    // Get schedule times
    guard let startHour = schedule.startTime.hour,
          let startMinute = schedule.startTime.minute,
          let endHour = schedule.endTime.hour,
          let endMinute = schedule.endTime.minute else {
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "❌ Missing Times",
//        details: "Schedule has incomplete time data"
//      )
      return false
    }
    
    // Check if current time is within schedule range
    let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
    guard let currentHour = currentComponents.hour,
          let currentMinute = currentComponents.minute else {
      return false
    }
    
    let currentMinutes = currentHour * 60 + currentMinute
    let startMinutes = startHour * 60 + startMinute
    let endMinutes = endHour * 60 + endMinute
    
    // Handle overnight schedules
    if endMinutes < startMinutes {
      // Schedule crosses midnight
      let isActive = currentMinutes >= startMinutes || currentMinutes < endMinutes
      return isActive
    } else {
      // Normal schedule
      let isActive = currentMinutes >= startMinutes && currentMinutes < endMinutes
      return isActive
    }
  }
  
  // Keep old version for compatibility
  private func isScheduleActiveNow(scheduleId: String) -> Bool {
    let calendar = Calendar.current
    let now = Date()
    let weekday = calendar.component(.weekday, from: now)
    
    // Check day first
    if !isTodayInSchedule(scheduleId: scheduleId) {
      return false
    }
    
    // Get schedule times from SharedData
    guard let startHour = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_startHour") as? Int,
          let startMinute = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_startMinute") as? Int,
          let endHour = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_endHour") as? Int,
          let endMinute = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_endMinute") as? Int else {
      return false
    }
    
    // Check if current time is within schedule range
    let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
    guard let currentHour = currentComponents.hour,
          let currentMinute = currentComponents.minute else {
      return false
    }
    
    let currentMinutes = currentHour * 60 + currentMinute
    let startMinutes = startHour * 60 + startMinute
    let endMinutes = endHour * 60 + endMinute
        
    // Handle overnight schedules
    if endMinutes < startMinutes {
      // Schedule crosses midnight
      let isActive = currentMinutes >= startMinutes || currentMinutes < endMinutes
      return isActive
    } else {
      // Normal schedule
      let isActive = currentMinutes >= startMinutes && currentMinutes < endMinutes
      return isActive
    }
  }
    
  private func restartScheduleMonitoring(scheduleId: String) {
    let monitoringActivityName = DeviceActivityName("monitor_\(scheduleId)")
    let center = DeviceActivityCenter()
    
    // Stop current monitoring
    center.stopMonitoring([monitoringActivityName])
    
    // Get schedule times from SharedData to create proper monitoring window
    guard let startHour = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_startHour") as? Int,
          let startMinute = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_startMinute") as? Int,
          let endHour = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_endHour") as? Int,
          let endMinute = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_endMinute") as? Int else {
      return
    }
    
    // Calculate monitoring window (1 minute before start to 1 minute after end)
    var monitorStart = DateComponents()
    var adjustedStartMinute = startMinute - 1
    var adjustedStartHour = startHour
    if adjustedStartMinute < 0 {
      adjustedStartMinute = 59
      adjustedStartHour = (adjustedStartHour - 1 + 24) % 24
    }
    monitorStart.hour = adjustedStartHour
    monitorStart.minute = adjustedStartMinute
    
    var monitorEnd = DateComponents()
    var adjustedEndMinute = endMinute + 1
    var adjustedEndHour = endHour
    if adjustedEndMinute >= 60 {
      adjustedEndMinute = 0
      adjustedEndHour = (adjustedEndHour + 1) % 24
    }
    monitorEnd.hour = adjustedEndHour
    monitorEnd.minute = adjustedEndMinute
    
    // Create monitoring schedule
    let monitoringSchedule = DeviceActivitySchedule(
      intervalStart: monitorStart,
      intervalEnd: monitorEnd,
      repeats: true
    )
    
    // Create trigger event that fires every minute
    let triggerEvent = DeviceActivityEvent(
      applications: Set<ApplicationToken>(),
      threshold: DateComponents(minute: 1)
    )
    
    let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
      DeviceActivityEvent.Name("trigger_\(scheduleId)"): triggerEvent
    ]
    
    // Restart monitoring
    do {
      try center.startMonitoring(monitoringActivityName, during: monitoringSchedule, events: events)
      
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "🔄 Monitoring Restarted",
//        details: "Schedule \(scheduleId) monitoring restarted"
//      )
      
    } catch {
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "❌ Restart Failed",
//        details: "Error: \(error.localizedDescription)"
//      )
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
}
