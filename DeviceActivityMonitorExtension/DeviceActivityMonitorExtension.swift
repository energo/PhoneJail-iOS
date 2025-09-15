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
import Foundation


// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  
  // Track last trigger time to prevent rapid re-triggers
  private var lastInterruptionTrigger: Date?
  private var lastAlertTrigger: Date?
  private let minimumTriggerInterval: TimeInterval = 120 // 2 minutes minimum between triggers
  
  //MARK: - Interval Delegates Methods
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    
    //     Debug notification
    //    LocalNotificationManager.scheduleExtensionNotification(
    //      title: "🔄 Interval Did Start",
    //      details: "\(activity.rawValue)"
    //    )
    
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
    
    // Pomodoro start: apply restrictions using saved selection
    if activity == .pomodoro {
      // Mark that we're in focus phase
      SharedData.userDefaults?.set(false, forKey: "pomodoro.isBreakPhase")
      // Load selection saved by app
      var selection = FamilyActivitySelection()
      if let data = SharedData.userDefaults?.data(forKey: "pomodoroSelectedApps"),
         let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
        selection = decoded
      }
      
      // Apply shield restrictions to the dedicated Pomodoro store
      ShieldService.shared.setShieldRestrictions(for: selection, storeName: .pomodoro)
      
      // Strict mode: deny app removal if enabled
      let isStrict = SharedData.userDefaults?.bool(forKey: "pomodoroIsStrictBlock") ?? false
      if isStrict {
        let pomodoroStore = ManagedSettingsStore(named: .pomodoro)
        pomodoroStore.application.denyAppRemoval = true
      }
      
      // Start logging a blocking session for categories with expected duration if available
      if let ts = SharedData.userDefaults?.double(forKey: "pomodoro.unlockDate"), ts > 0 {
        let duration = max(0, ts - Date().timeIntervalSince1970)
        Task { @MainActor in
          _ = AppBlockingLogger.shared.startPomodoroSessionForCategories(duration: duration)
        }
      }
      return
    }
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    
    let activityName = "\(activity.rawValue)"
    
    // Debug notification
//        LocalNotificationManager.scheduleExtensionNotification(
//          title: "🔄 Interval Did End",
//          details: "\(activityName)"
//        )
    
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
      
      //          LocalNotificationManager.scheduleExtensionNotification(
      //            title: "✅ Apps Unblocked",
      //            details: "You can use your apps again"
      //          )
      
      // Clear regular blocking store
      ShieldService.shared.stopAppRestrictions()
      
      // Clear regular blocking state only if unlock date has passed
      DeviceActivityScheduleService.stopSchedule()
      SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
      SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
      SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endHour)
      SharedData.userDefaults?.removeObject(forKey: SharedData.Widget.endMinutes)
      SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.unlockDate)
      
    } else if activity == .appBlockingInterruption {
      // Interruption block ending
      LocalNotificationManager.scheduleExtensionNotification(
        title: "✅ Interruption Break Over",
        details: "You can use your apps again"
      )
      
      // Log interruption session end
      // Note: Interruption sessions are short (2 min) and handled locally
      
      // Clear shield restrictions for interruption store
      ShieldService.shared.stopAppRestrictions(storeName: .interruption)
      
      // Clear interruption state
      SharedData.userDefaults?.removeObject(forKey: SharedData.ScreenTime.isInterruptionBlock)
      
      // Restart interruption monitoring if enabled
      let isEnabled = SharedData.userDefaults?.bool(forKey: SharedData.ScreenTime.isInterruptionsEnabled) ?? false
      if isEnabled {
        // Перезапускаем мониторинг после окончания блокировки
        restartMonitoring(for: .appMonitoringInterruption)
      }
    }
    else if activity == .pomodoro {
      Task { @MainActor in
//        LocalNotificationManager.scheduleExtensionNotification(
//          title: "🔄 End Focus",
//          details: "\(activityName)"
//        )

        // End of Pomodoro focus session: clear restrictions and end logging
        ShieldService.shared.stopAppRestrictions(storeName: .pomodoro)
        AppBlockingLogger.shared.endSession(type: .pomodoro, completed: true)
        
        // Handle auto start of break phase even if the app is closed
        let autoStartBreak = SharedData.userDefaults?.bool(forKey: SharedData.Pomodoro.autoStartBreak) ?? true
        if autoStartBreak {
          // Determine break duration (short or long every N sessions)
          var totalSessions = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.totalSessions) ?? 1
          let currentSession = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.currentSession) ?? 1
          let longBreakDuration = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.longBreakDuration) ?? 15
          let breakDuration = SharedData.userDefaults?.integer(forKey: SharedData.Pomodoro.breakDuration) ?? 5
          let blockDuringBreak = SharedData.userDefaults?.bool(forKey: "pomodoroBlockDuringBreak") ?? false
          
          // Keep currentSession as is for break phase (increment happens when next focus starts)
        if totalSessions < 1  {
          totalSessions = 1
          SharedData.userDefaults?.set(1, forKey: SharedData.Pomodoro.totalSessions)
        }
          let isLongBreak = currentSession % totalSessions == 0
          let minutes = isLongBreak ? longBreakDuration : breakDuration
          let endDate = Date().addingTimeInterval(TimeInterval(max(1, minutes) * 60))
          
          // Persist break phase so UI can restore without the app running
          SharedData.userDefaults?.set(endDate.timeIntervalSince1970, forKey: "pomodoro.unlockDate")
          SharedData.userDefaults?.set("break", forKey: SharedData.Pomodoro.currentSessionType)
          SharedData.userDefaults?.set(blockDuringBreak, forKey: "pomodoro.isBlockingPhase")
          SharedData.userDefaults?.set(true, forKey: "pomodoro.isBreakPhase")
          SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked) // ensure AppBlocking UI stays off
          
//          LocalNotificationManager.scheduleExtensionNotification(
//            title: "🔄 End Focus",
//            details: "\(minutes)"
//          )
        } else {
          // No break auto-start
          SharedData.userDefaults?.removeObject(forKey: "pomodoro.unlockDate")
          SharedData.userDefaults?.set(false, forKey: "pomodoro.isBreakPhase")
        }
      }
    }
  }
  
  //MARK: - Inrterval Threshold
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    
    // Debug notification to confirm threshold reached
    //    LocalNotificationManager.scheduleExtensionNotification(
    //      title: "📊 Threshold Reached!",
    //      details: "Event: \(event.rawValue)\nActivity: \(activity.rawValue)"
    //    )
    
    // Check if this is an interruption event
    if event == DeviceActivityEvent.Name.interruption {
      handleTresholdScreenInterruption(event)
      // НЕ перезапускаем мониторинг для interruption - он перезапустится после окончания блокировки
      return
    }
    
    // Check if this is a screen alert event
    if event == DeviceActivityEvent.Name.screenAlert {
      handleTresholdScreenAlert(event)
    }
    
    restartMonitoring(for: activity)
  }
  
  //MARK: - Screen Time Alert
  private func handleTresholdScreenAlert(_ event: DeviceActivityEvent.Name) {
    let now = Date()
    lastAlertTrigger = now
    
    //    checkAndResetDailyCounters()
    
    if let _ = SharedData.selectedAlertActivity {
      
      // Get personalized message
      let message = getPersonalizedMessage()
      
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
      print("Interruption triggered too soon, skipping. Last: \(lastTrigger), Now: \(now)")
      return
    }
    
    lastInterruptionTrigger = now
    
    // Processing interruption
    if let selection = SharedData.selectedInterruptionsActivity {
      
      // Save the current time as last interruption time
      SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedData.AppBlocking.lastInterruptionBlockTime)
      
      // Log interruption session start
      // Note: Interruption sessions are short (2 min) and handled locally
      
      LocalNotificationManager.scheduleExtensionNotification(
        title: "⏸️ Take a Break",
        details: "Monitored apps blocked for 2 minutes"
      )
      
      BlockingNotificationServiceForInterruptions.shared.startBlocking(
        hours: 0,
        minutes: 2,
        selection: selection,
        restrictionModel: MyRestrictionModel()
      )
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
      LocalNotificationManager.scheduleExtensionNotification(
        title: "❌ Failed to restart monitoring",
        details: "\(error.localizedDescription)"
      )
      
      print("Failed to restart monitoring: \(error.localizedDescription)")
    }
  }
  
  //MARK: - Schedule Blocks
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
    
    //    LocalNotificationManager.scheduleExtensionNotification(
    //      title: "📊 Schedule Data Check",
    //      details: "ID: \(schedule.id)\nName: \(schedule.name)\nApps: \(schedule.selection.applicationTokens.count)"
    //    )
    
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
  
  private func applyScheduledBlockRestrictions(schedule: BlockSchedule) {
    let scheduleId = schedule.id
    
    // Apply restrictions using ManagedSettingsStore
    let storeName = ManagedSettingsStore.Name("scheduledBlock_\(scheduleId)")
    let store = ManagedSettingsStore(named: storeName)
    
    // Clear any existing settings first
    store.clearAllSettings()
    
    // Apply shield for visual blocking
    store.shield.applications = schedule.selection.applicationTokens
    store.shield.applicationCategories = schedule.selection.categoryTokens.isEmpty
    ? nil
    : ShieldSettings.ActivityCategoryPolicy.specific(schedule.selection.categoryTokens)
    store.shield.webDomains = schedule.selection.webDomainTokens
    
    store.application.denyAppRemoval = schedule.isStrictBlock
    
    // Mark as active in SharedData
    SharedData.userDefaults?.set(true, forKey: "schedule_\(scheduleId)_active")
    SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: "schedule_\(scheduleId)_startTimestamp")
    SharedData.userDefaults?.set(true, forKey: SharedData.Widget.isBlocked)
    SharedData.userDefaults?.set(schedule.isStrictBlock, forKey: SharedData.Widget.isStricted)
    
    // Log schedule session start using AppBlockingLogger
    Task { @MainActor in
      let apps = Array(schedule.selection.applicationTokens)
      if !apps.isEmpty {
        _ = AppBlockingLogger.shared.startScheduleSession(apps: apps, scheduleName: schedule.name)
      } else if !schedule.selection.categoryTokens.isEmpty {
        _ = AppBlockingLogger.shared.startScheduleSessionForCategories(scheduleName: schedule.name)
      }
    }
  }
  
  // Removed - duplicate method, using the one with BlockSchedule parameter
  
  private func removeScheduledBlockRestrictions(schedule: BlockSchedule) {
    let scheduleId = schedule.id
    
    // Log session end using AppBlockingLogger
    Task { @MainActor in
      // Since there can be multiple schedule sessions, we need to find the one for this schedule
      // For now, end all schedule sessions when a schedule ends
      // In the future, we should track session IDs per schedule
      let scheduleSessions = AppBlockingLogger.shared.getActiveScheduleSessions()
      for session in scheduleSessions {
        AppBlockingLogger.shared.endSession(sessionId: session.id, completed: true)
      }
    }
    
    // Remove restrictions using ManagedSettingsStore
    let storeName = ManagedSettingsStore.Name("scheduledBlock_\(scheduleId)")
    let store = ManagedSettingsStore(named: storeName)
    
    // Clear all restrictions
    store.clearAllSettings()
    
    // Mark as inactive in SharedData
    SharedData.userDefaults?.set(false, forKey: "schedule_\(scheduleId)_active")
    SharedData.userDefaults?.removeObject(forKey: "schedule_\(scheduleId)_startTimestamp")
    
    // Check if any other schedules are active
    let allScheduleIds = SharedData.userDefaults?.dictionaryRepresentation().keys
      .filter { $0.contains("schedule_") && $0.contains("_active") }
      .compactMap { key -> String? in
        guard let isActive = SharedData.userDefaults?.bool(forKey: key), isActive else { return nil }
        // Extract schedule ID from key like "schedule_UUID_active"
        let components = key.split(separator: "_")
        guard components.count >= 3 else { return nil }
        return String(components[1])
      } ?? []
    
    if allScheduleIds.isEmpty {
      SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
      SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isStricted)
    }
  }
  
  // Removed - duplicate method, using the one with BlockSchedule parameter
  
  private func logScheduleSessionStart(schedule: BlockSchedule) {
    let scheduleId = schedule.id
    let scheduleName = schedule.name
    let selection = schedule.selection
    
    let startTime = Date().timeIntervalSince1970
    
    // Calculate schedule duration in seconds
    let calendar = Calendar.current
    let now = Date()
    
    var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
    startComponents.hour = schedule.startTime.hour
    startComponents.minute = schedule.startTime.minute
    
    var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
    endComponents.hour = schedule.endTime.hour
    endComponents.minute = schedule.endTime.minute
    
    let duration: TimeInterval
    if let startDate = calendar.date(from: startComponents),
       let endDate = calendar.date(from: endComponents) {
      if endDate > startDate {
        duration = endDate.timeIntervalSince(startDate)
      } else {
        // Overnight schedule - add 24 hours to end date
        let nextDayEndDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        duration = nextDayEndDate.timeIntervalSince(startDate)
      }
    } else {
      duration = 3600 // Default to 1 hour if calculation fails
    }
    
    // Create individual app sessions for Focus Time tracking
    for appToken in selection.applicationTokens {
      let appTokenString = String(describing: appToken)
      let appSessionKey = "app_session_\(appTokenString)"
      
      // Create app session data
      let appSessionData: [String: Any] = [
        "appToken": appTokenString,
        "scheduleId": scheduleId,
        "scheduleName": scheduleName,
        "startDate": startTime,
        "endDate": 0, // Will be set when session ends
        "plannedDuration": duration,
        "actualDuration": 0,
        "wasCompleted": false
      ]
      
      // Save individual app session
      if let data = try? JSONSerialization.data(withJSONObject: appSessionData) {
        SharedData.userDefaults?.set(data, forKey: appSessionKey)
      }
    }
    
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
    
    print("Started Focus Time tracking for \(selection.applicationTokens.count) apps in schedule: \(scheduleName)")
  }
  
  // Removed - duplicate method, using the one with BlockSchedule parameter
  
  private func logScheduleSessionEnd(scheduleId: String) {
    // Calculate and log blocking time to Focus Time statistics
    if let sessionData = SharedData.userDefaults?.data(forKey: "schedule_session_\(scheduleId)"),
       let sessionInfo = try? JSONSerialization.jsonObject(with: sessionData) as? [String: Any],
       let startTime = sessionInfo["startTime"] as? TimeInterval {
      
      let endTime = Date().timeIntervalSince1970
      let duration = endTime - startTime
      
      // Complete blocking sessions for each app in the schedule
      if let appTokensData = sessionInfo["appTokens"] as? Data,
         let appTokenStrings = try? JSONDecoder().decode([String].self, from: appTokensData) {
        
        for appTokenString in appTokenStrings {
          // Mark app session as completed in SharedData
          let appSessionKey = "app_session_\(appTokenString)"
          if let appSessionData = SharedData.userDefaults?.data(forKey: appSessionKey),
             let appSession = try? JSONSerialization.jsonObject(with: appSessionData) as? [String: Any] {
            
            // Update session with completion data
            var updatedSession = appSession
            updatedSession["endDate"] = endTime
            updatedSession["actualDuration"] = duration
            updatedSession["wasCompleted"] = true
            
            // Save updated session
            if let updatedData = try? JSONSerialization.data(withJSONObject: updatedSession) {
              SharedData.userDefaults?.set(updatedData, forKey: "completed_\(appSessionKey)")
            }
            
            // Remove active session
            SharedData.userDefaults?.removeObject(forKey: appSessionKey)
          }
        }
      }
      
      // Statistics are already updated by AppBlockingLogger.endSession()
      // We don't need to update them here to avoid double counting
      
      // Just log for debugging
      print("DeviceActivityMonitor: Session ended with duration: \(duration) seconds")
      
      // Store detailed session info for statistics
      let calendar = Calendar.current
      let hour = calendar.component(.hour, from: Date())
      let hourlyKey = "hourlyBlockingTime_\(hour)"
      let hourlyTime = SharedData.userDefaults?.double(forKey: hourlyKey) ?? 0
      SharedData.userDefaults?.set(hourlyTime + duration, forKey: hourlyKey)
      
      // Log schedule name and app count for better tracking
      let scheduleName = sessionInfo["scheduleName"] as? String ?? "Schedule"
      let appCount = sessionInfo["appCount"] as? Int ?? 0
      
      print("Ended Focus Time tracking for \(appCount) apps in '\(scheduleName)', duration: \(Int(duration))s")
      
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
    
    //    LocalNotificationManager.scheduleExtensionNotification(
    //      title: "⏰ Time Check",
    //      details: "Now: \(currentHour):\(String(format: "%02d", currentMinute)) (\(currentMinutes)min)\n" +
    //               "Start: \(startHour):\(String(format: "%02d", startMinute)) (\(startMinutes)min)\n" +
    //               "End: \(endHour):\(String(format: "%02d", endMinute)) (\(endMinutes)min)"
    //    )
    
    // Handle overnight schedules
    if endMinutes < startMinutes {
      // Schedule crosses midnight
      let isActive = currentMinutes >= startMinutes || currentMinutes < endMinutes
      //      LocalNotificationManager.scheduleExtensionNotification(
      //        title: "🌙 Overnight Schedule",
      //        details: "Current >= Start: \(currentMinutes >= startMinutes)\n" +
      //                 "Current < End: \(currentMinutes < endMinutes)\n" +
      //                 "Result: \(isActive)"
      //      )
      return isActive
    } else {
      // Normal schedule
      let isActive = currentMinutes >= startMinutes && currentMinutes < endMinutes
      //      LocalNotificationManager.scheduleExtensionNotification(
      //        title: "☀️ Normal Schedule",
      //        details: "Current >= Start: \(currentMinutes >= startMinutes)\n" +
      //                 "Current < End: \(currentMinutes < endMinutes)\n" +
      //                 "Result: \(isActive)"
      //      )
      return isActive
    }
  }
  
  // Keep old version for compatibility
  private func isScheduleActiveNow(scheduleId: String) -> Bool {
    let calendar = Calendar.current
    let now = Date()
    
    // Check day first
    if !isTodayInSchedule(scheduleId: scheduleId) {
//      let weekday = calendar.component(.weekday, from: now)
      //      LocalNotificationManager.scheduleExtensionNotification(
      //        title: "❌ Wrong Day",
      //        details: "Today (\(weekday)) not in schedule days"
      //      )
      return false
    }
    
    // Get schedule times from SharedData
    guard let startHour = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_startHour") as? Int,
          let startMinute = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_startMinute") as? Int,
          let endHour = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_endHour") as? Int,
          let endMinute = SharedData.userDefaults?.object(forKey: "schedule_\(scheduleId)_endMinute") as? Int else {
      //      LocalNotificationManager.scheduleExtensionNotification(
      //        title: "❌ Missing Times",
      //        details: "Could not load schedule times from SharedData"
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
    
    //    LocalNotificationManager.scheduleExtensionNotification(
    //      title: "⏰ Time Check",
    //      details: "Now: \(currentHour):\(String(format: "%02d", currentMinute)) (\(currentMinutes)min)\n" +
    //               "Start: \(startHour):\(String(format: "%02d", startMinute)) (\(startMinutes)min)\n" +
    //               "End: \(endHour):\(String(format: "%02d", endMinute)) (\(endMinutes)min)"
    //    )
    
    // Handle overnight schedules
    if endMinutes < startMinutes {
      // Schedule crosses midnight
      let isActive = currentMinutes >= startMinutes || currentMinutes < endMinutes
      //      LocalNotificationManager.scheduleExtensionNotification(
      //        title: "🌙 Overnight Schedule",
      //        details: "Current >= Start: \(currentMinutes >= startMinutes)\n" +
      //                 "Current < End: \(currentMinutes < endMinutes)\n" +
      //                 "Result: \(isActive)"
      //      )
      return isActive
    } else {
      // Normal schedule
      let isActive = currentMinutes >= startMinutes && currentMinutes < endMinutes
      //      LocalNotificationManager.scheduleExtensionNotification(
      //        title: "☀️ Normal Schedule",
      //        details: "Current >= Start: \(currentMinutes >= startMinutes)\n" +
      //                 "Current < End: \(currentMinutes < endMinutes)\n" +
      //                 "Result: \(isActive)"
      //      )
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
      print("Failed to get schedule times for \(scheduleId)")
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
      
      print("Restarted schedule monitoring for \(scheduleId)")
    } catch {
      //      LocalNotificationManager.scheduleExtensionNotification(
      //        title: "❌ Restart Failed",
      //        details: "Error: \(error.localizedDescription)"
      //      )
      
      print("Failed to restart schedule monitoring: \(error)")
    }
  }
  
  private func getPersonalizedMessage() -> String {
    let messages = [
      "Your thumb needs a break. Put down your phone.",
      "Still scrolling? Time to stop.",
      "Screens won’t cuddle you back. Block your phone.",
      "Put down your phone. Go touch grass. Seriously.",
      "Your future self just rolled their eyes. Log off?",
      "Plot twist: nothing new on your feed.",
      "Why not get dopamine from the real world?",
      "This app thinks you’re cute offline.",
      "Congrats. You just beat your high score in procrastination.",
      "Spoiler: You won’t find meaning here.",
      "Breaking news: Your life is happening elsewhere.",
      "Your screen time is judging you.",
      "Achievement unlocked: Wasted time.",
      "Even your battery is tired of this. Block your phone.",
      "If scrolling burned calories, you’d be ripped.",
      "Real life has better graphics. Go live it.",
      "Stop scrolling. Start strolling. (Go take a walk, buddy)",
      "Go do literally anything cooler than this.",
      "Life > feed. Choose wisely.",
      "Go outside. The graphics are insane.",
      "You’re one scroll away from nothing. Stop.",
      "Endless feed. Endless waste. Stop.",
      "You’re in a loop. Break it.",
      "One more scroll and you officially qualify as furniture.",
      "Breaking news: Your thumb has filed a complaint.",
      "This feed is junk food. Go eat real life.",
      "Nothing new here. Even your feed is bored.",
      "Too much screen time shrinks your attention span to 8 seconds.",
      "Studies show phone use kills focus. But hey, you’re really focused on scrolling.",
      "Life expectancy = ~80 years. You’ll spend 9 of them staring at a rectangle.",
      "Phone addiction raises anxiety by 30%. Keep scrolling if you’re into that.",
      "Heavy phone users sleep an hour less. Worth it?",
      "Go live your life — your feed will still be here."
    ]
    
    return messages.randomElement() ?? "Go live your life — your feed will still be here."
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
