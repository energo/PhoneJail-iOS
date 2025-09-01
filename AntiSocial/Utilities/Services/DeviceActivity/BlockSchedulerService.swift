//
//  BlockSchedulerService.swift
//  AntiSocial
//
//  Created by Claude on 19.01.2025.
//

import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings
import UserNotifications

extension DeviceActivityName {
  static func scheduledBlock(id: String) -> Self {
    Self("scheduledBlock_\(id)")
  }
}

extension ManagedSettingsStore.Name {
  static func scheduledBlock(id: String) -> Self {
    Self("scheduledBlock_\(id)")
  }
}

class BlockSchedulerService: ObservableObject {
  static let shared = BlockSchedulerService()
  
  @Published var activeSchedules: [BlockSchedule] = []
  @Published var allSchedules: [BlockSchedule] = []
  private let center = DeviceActivityCenter()
  private var activeMonitors: Set<String> = []
  
  private init() {
    loadAllSchedules()
    setupSchedules()
    setupNotificationObservers()
  }
  
  // MARK: - Public Methods
  
  func activateSchedule(_ schedule: BlockSchedule) {
    guard schedule.isActive else { return }
    
    AppLogger.notice("=== ACTIVATING SCHEDULE ===")
    AppLogger.notice("Schedule ID: \(schedule.id)")
    AppLogger.notice("Schedule Name: \(schedule.name)")
    AppLogger.notice("Start Time: \(schedule.startTime.hour ?? 0):\(schedule.startTime.minute ?? 0)")
    AppLogger.notice("End Time: \(schedule.endTime.hour ?? 0):\(schedule.endTime.minute ?? 0)")
    AppLogger.notice("Days: \(schedule.daysOfWeek)")
    
    // Schedule is already saved to SharedData by BlockSchedule.add/update
    // No need to save again here
    
    // Create activity for this schedule
    let scheduleActivityName = DeviceActivityName("schedule_\(schedule.id)")
    
    // Check if schedule duration is at least 15 minutes (iOS requirement)
    let startMinutes = (schedule.startTime.hour ?? 0) * 60 + (schedule.startTime.minute ?? 0)
    let endMinutes = (schedule.endTime.hour ?? 0) * 60 + (schedule.endTime.minute ?? 0)
    
    // Handle overnight schedules
    let duration: Int
    if endMinutes >= startMinutes {
      duration = endMinutes - startMinutes
    } else {
      // Overnight schedule
      duration = (24 * 60 - startMinutes) + endMinutes
    }
    
    if duration < 15 {
      AppLogger.alert("Schedule duration too short: \(duration) minutes. iOS requires at least 15 minutes.")
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "⚠️ Schedule Too Short",
//        details: "Duration: \(duration) min\nMinimum required: 15 min\nPlease extend the schedule."
//      )
      return
    }
    
    // Create schedule that matches the blocking period exactly
    let blockingSchedule = DeviceActivitySchedule(
      intervalStart: schedule.startTime,
      intervalEnd: schedule.endTime,
      repeats: true
    )
    
    // Send notification BEFORE starting monitoring
//    LocalNotificationManager.scheduleExtensionNotification(
//      title: "📅 Schedule Created",
//      details: "ID: \(schedule.id)\n" +
//      "Name: \(schedule.name)\n" +
//      "Time: \(schedule.startTime.hour ?? 0):\(String(format: "%02d", schedule.startTime.minute ?? 0)) - " +
//      "\(schedule.endTime.hour ?? 0):\(String(format: "%02d", schedule.endTime.minute ?? 0))\n" +
//      "Days: \(schedule.shortDaysString)\n" +
//      "Apps: \(schedule.selection.applicationTokens.count)"
//    )
    
    // Start schedule monitoring
    do {
      // Stop any existing monitoring for this schedule
      center.stopMonitoring([scheduleActivityName])
      
      try center.startMonitoring(scheduleActivityName, during: blockingSchedule)
      activeMonitors.insert(schedule.id)
      
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "🎯 Schedule Activated",
//        details: "Activity: \(scheduleActivityName.rawValue)\nWill start at: \(schedule.startTime.hour ?? 0):\(String(format: "%02d", schedule.startTime.minute ?? 0))"
//      )
      
      // Apply restrictions ONLY if schedule is currently active
      applyRestrictions(schedule)
      
      // Update schedule status
      var updatedSchedule = schedule
      updatedSchedule.isActive = true
      BlockSchedule.update(updatedSchedule)
      
      // Reload all schedules
      loadAllSchedules()
      
      // Schedule notification
      scheduleNotification(for: schedule)
      
      AppLogger.notice("Activated schedule: \(schedule.name)")
    } catch {
      AppLogger.critical(error, details: "Failed to activate schedule: \(schedule.name)")
    }
  }
  
  func applyRestrictions(_ schedule: BlockSchedule) {
    if isScheduleActiveNow(schedule) {
      AppLogger.notice("Schedule '\(schedule.name)' is active NOW - applying restrictions immediately")
      applyRestrictions(for: schedule)
      
      // Send debug notification that restrictions are applied immediately
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "🔒 Schedule Active NOW",
//        details: "ID: \(schedule.id)\n\(schedule.name) is active immediately\nRestrictions applied"
//      )
      
      // Also create a blocking schedule for the remaining time
      let calendar = Calendar.current
      let now = Date()
      
      // Calculate end time for today
      if let endHour = schedule.endTime.hour,
         let endMinute = schedule.endTime.minute {
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = endHour
        endComponents.minute = endMinute
        
        if let endDate = calendar.date(from: endComponents),
           endDate > now {
          // Create schedule from now until end time
          let intervalStart = calendar.dateComponents([.hour, .minute], from: now)
          let intervalEnd = calendar.dateComponents([.hour, .minute], from: endDate)
          
          let blockingSchedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: false
          )
          
          let blockingActivityName = DeviceActivityName.scheduledBlock(id: schedule.id)
          
          do {
            center.stopMonitoring([blockingActivityName])
            try center.startMonitoring(blockingActivityName, during: blockingSchedule)
            AppLogger.notice("Created immediate blocking schedule until \(endHour):\(endMinute)")
          } catch {
            AppLogger.critical(error, details: "Failed to create immediate blocking schedule")
          }
        }
      }
    } else {
      AppLogger.notice("Schedule '\(schedule.name)' is NOT active now - will start at scheduled time")
      // For schedules not active now, just ensure isBlocked is false without clearing everything
      var updatedSchedule = schedule
      updatedSchedule.isBlocked = false
      updatedSchedule.updatedAt = Date()
      BlockSchedule.update(updatedSchedule)
      
      // Reload all schedules to reflect the change
      loadAllSchedules()
      
      // Send debug notification that schedule will start later
//      LocalNotificationManager.scheduleExtensionNotification(
//        title: "⏰ Schedule Pending",
//        details: "ID: \(schedule.id)\n\(schedule.name) will start at \(schedule.startTime.hour ?? 0):\(String(format: "%02d", schedule.startTime.minute ?? 0))"
//      )
    }
  }
  
  func deactivateSchedule(_ schedule: BlockSchedule) {
    let scheduleActivityName = DeviceActivityName("schedule_\(schedule.id)")
    let blockingActivityName = DeviceActivityName.scheduledBlock(id: schedule.id)
    
    // Stop both regular schedule and immediate blocking monitoring
    center.stopMonitoring([scheduleActivityName, blockingActivityName])
    activeMonitors.remove(schedule.id)
    
    // Remove restrictions
    removeRestrictions(for: schedule)
    
    // Update schedule status
    var updatedSchedule = schedule
    updatedSchedule.isActive = false
    BlockSchedule.update(updatedSchedule)
    
    // Reload all schedules
    loadAllSchedules()
    
    // Cancel notifications
    cancelNotification(for: schedule)
    
    AppLogger.notice("Deactivated schedule: \(schedule.name)")
    
    // Send debug notification
//    LocalNotificationManager.scheduleExtensionNotification(
//      title: "🚫 Schedule Deactivated",
//      details: "\(schedule.name) has been deactivated"
//    )
  }
  
  func toggleSchedule(_ schedule: BlockSchedule) {
    if schedule.isActive {
      deactivateSchedule(schedule)
    } else {
      activateSchedule(schedule)
    }
  }
  
  func checkAndApplyActiveSchedules() {
    let schedules = BlockSchedule.loadAll()
    
    for schedule in schedules where schedule.isActive {
      if isScheduleActiveNow(schedule) {
        // Only apply restrictions if not already blocked
        if !schedule.isBlocked {
          applyRestrictions(for: schedule)
        }
      } else {
        // Only remove restrictions if currently blocked
        if schedule.isBlocked {
          removeRestrictions(for: schedule)
        }
      }
    }
  }
  
  // MARK: - Private Methods
  
  private func loadActiveSchedules() {
    activeSchedules = BlockSchedule.loadAll().filter { $0.isActive }
  }
  
  private func loadAllSchedules() {
    allSchedules = BlockSchedule.loadAll()
    activeSchedules = allSchedules.filter { $0.isActive }
  }
  
  private func setupSchedules() {
    // Re-activate all active schedules on app launch
    for schedule in activeSchedules {
      activateSchedule(schedule)
    }
  }
  
  func reloadSchedules() {
    let schedules = BlockSchedule.loadAll()
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      // Force UI update by sending objectWillChange
      self.objectWillChange.send()
      
      // Update the published properties
      self.allSchedules = schedules
      self.activeSchedules = schedules.filter { $0.isActive }
      
      AppLogger.notice("📊 Reloaded schedules: \(schedules.count) total, \(self.activeSchedules.count) active")
    }
  }
  
  // MARK: - Notification Observers
  
  private func setupNotificationObservers() {
    // We don't need to observe here - ScheduleNotificationHandler will handle notifications
    // and trigger updates through its delegate methods
  }
  
  private func isScheduleActiveNow(_ schedule: BlockSchedule) -> Bool {
    let calendar = Calendar.current
    let now = Date()
    let weekday = calendar.component(.weekday, from: now)
    
    AppLogger.trace("Checking if schedule '\(schedule.name)' is active now")
    AppLogger.trace("Current weekday: \(weekday), Schedule days: \(schedule.daysOfWeek)")
    
    // Check if today is in the schedule
    guard schedule.daysOfWeek.contains(weekday) else {
      AppLogger.trace("Today is not in schedule days")
      return false
    }
    
    // Check if current time is within schedule range
    let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
    guard let currentHour = currentComponents.hour,
          let currentMinute = currentComponents.minute,
          let startHour = schedule.startTime.hour,
          let startMinute = schedule.startTime.minute,
          let endHour = schedule.endTime.hour,
          let endMinute = schedule.endTime.minute else {
      AppLogger.trace("Failed to get time components")
      return false
    }
    
    let currentMinutes = currentHour * 60 + currentMinute
    let startMinutes = startHour * 60 + startMinute
    let endMinutes = endHour * 60 + endMinute
    
    AppLogger.trace("Current time: \(currentHour):\(currentMinute) (\(currentMinutes) min)")
    AppLogger.trace("Schedule time: \(startHour):\(startMinute) - \(endHour):\(endMinute) (\(startMinutes)-\(endMinutes) min)")
    
    // Handle overnight schedules
    if endMinutes < startMinutes {
      // Schedule crosses midnight
      let isActive = currentMinutes >= startMinutes || currentMinutes < endMinutes
      AppLogger.trace("Overnight schedule, active: \(isActive)")
      return isActive
    } else {
      // Normal schedule
      let isActive = currentMinutes >= startMinutes && currentMinutes < endMinutes
      AppLogger.trace("Regular schedule, active: \(isActive)")
      return isActive
    }
  }
  
  // Removed - now handled by BlockSchedule.add/update methods
  
  func applyRestrictions(for schedule: BlockSchedule) {
    let storeName = ManagedSettingsStore.Name.scheduledBlock(id: schedule.id)
    let store = ManagedSettingsStore(named: storeName)
    
    // Clear existing settings first
    store.clearAllSettings()
    
    // Apply shield for visual blocking
    store.shield.applications = schedule.selection.applicationTokens
    store.shield.applicationCategories = schedule.selection.categoryTokens.isEmpty
    ? nil
    : ShieldSettings.ActivityCategoryPolicy.specific(schedule.selection.categoryTokens)
    store.shield.webDomains = schedule.selection.webDomainTokens

    if schedule.isStrictBlock {
      store.application.denyAppRemoval = true
    }
    
    // Also set additional restrictions like in regular blocking
    store.media.denyExplicitContent = true
    store.dateAndTime.requireAutomaticDateAndTime = true
    
    // Update schedule to mark it as currently blocking
    var updatedSchedule = schedule
    updatedSchedule.isBlocked = true
    updatedSchedule.updatedAt = Date()
    BlockSchedule.update(updatedSchedule)
    
    // Reload all schedules to reflect the change
    loadAllSchedules()
    
    // Save to SharedData for extensions
    SharedData.userDefaults?.set(true, forKey: "schedule_\(schedule.id)_active")
    
    // Set the blocking timestamp for this schedule
    SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: "schedule_\(schedule.id)_startTimestamp")
    
    AppLogger.trace("Applied restrictions for schedule: \(schedule.name), isBlocked set to true")
  }
  
  func removeRestrictions(for schedule: BlockSchedule) {
    let storeName = ManagedSettingsStore.Name.scheduledBlock(id: schedule.id)
    let store = ManagedSettingsStore(named: storeName)
    
    // Clear all restrictions
    store.clearAllSettings()
    
    // Update schedule to mark it as not blocking
    var updatedSchedule = schedule
    updatedSchedule.isBlocked = false
    updatedSchedule.updatedAt = Date()
    BlockSchedule.update(updatedSchedule)
    
    // Reload all schedules to reflect the change
    loadAllSchedules()
    
    // Clear from SharedData
    SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)")
    SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_active")
    SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_startTimestamp")
    
    // Check if any other schedules are active, if not, clear global blocking state
//    let activeSchedules = BlockSchedule.loadAll().filter { $0.isActive && $0.id != schedule.id }
//    if activeSchedules.isEmpty {
//      SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
//      SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isStricted)
//    }
    
    AppLogger.trace("Removed restrictions for schedule: \(schedule.name), isBlocked set to false")
  }
  
  // MARK: - Notifications
  
  private func scheduleNotification(for schedule: BlockSchedule) {
    // Schedule both start and end notifications
    guard let startHour = schedule.startTime.hour,
          let startMinute = schedule.startTime.minute,
          let endHour = schedule.endTime.hour,
          let endMinute = schedule.endTime.minute else { return }
    
    for weekday in schedule.daysOfWeek {
      // Start notification
      var startComponents = DateComponents()
      startComponents.weekday = weekday
      startComponents.hour = startHour
      startComponents.minute = startMinute
      
      LocalNotificationManager.shared.scheduleNotification(
        title: "📅 \(schedule.name)",
        body: "Apps blocked until \(String(format: "%02d:%02d", endHour, endMinute))",
        identifier: "schedule_\(schedule.id)_day_\(weekday)_start",
        dateComponents: startComponents,
        repeats: true
      )
      
      // End notification
      var endComponents = DateComponents()
      endComponents.weekday = weekday
      endComponents.hour = endHour
      endComponents.minute = endMinute
      
      // Handle next day if schedule crosses midnight
      let nextWeekday = weekday == 7 ? 1 : weekday + 1
      if endHour < startHour || (endHour == startHour && endMinute < startMinute) {
        endComponents.weekday = nextWeekday
      }
      
      LocalNotificationManager.shared.scheduleNotification(
        title: "✅ \(schedule.name) Ended",
        body: "Apps are now unblocked",
        identifier: "schedule_\(schedule.id)_day_\(weekday)_end",
        dateComponents: endComponents,
        repeats: true
      )
    }
  }
  
  private func cancelNotification(for schedule: BlockSchedule) {
    var identifiers: [String] = []
    for weekday in 1...7 {
      identifiers.append("schedule_\(schedule.id)_day_\(weekday)_start")
      identifiers.append("schedule_\(schedule.id)_day_\(weekday)_end")
    }
    
    LocalNotificationManager.shared.cancelNotifications(identifiers: identifiers)
  }
}

// MARK: - Device Activity Monitor Extension Support
extension BlockSchedulerService {
  
  static func handleScheduleStart(scheduleId: String) {
    // Called from DeviceActivityMonitorExtension when schedule starts
    guard let schedule = BlockSchedule.loadAll().first(where: { $0.id == scheduleId }) else { return }
    
    // Log the start
    let duration = calculateDuration(from: schedule)
    AppLogger.notice("Schedule started: \(schedule.name) for \(duration) seconds")
    
    // Update SharedData for extensions
    SharedData.userDefaults?.set(Date(), forKey: "schedule_\(scheduleId)_started")
    
    // Send Darwin notification
    DarwinNotificationManager.shared.postNotification(name: "com.app.antisocial.scheduleStarted")
  }
  
  static func handleScheduleEnd(scheduleId: String) {
    // Called from DeviceActivityMonitorExtension when schedule ends
    
    // Update SharedData
    SharedData.userDefaults?.removeObject(forKey: "schedule_\(scheduleId)_started")
    
    // Send Darwin notification
    DarwinNotificationManager.shared.postNotification(name: "com.app.antisocial.scheduleEnded")
  }
  
  private static func calculateDuration(from schedule: BlockSchedule) -> TimeInterval {
    guard let startHour = schedule.startTime.hour,
          let startMinute = schedule.startTime.minute,
          let endHour = schedule.endTime.hour,
          let endMinute = schedule.endTime.minute else {
      return 0
    }
    
    let startMinutes = startHour * 60 + startMinute
    let endMinutes = endHour * 60 + endMinute
    
    if endMinutes >= startMinutes {
      return TimeInterval((endMinutes - startMinutes) * 60)
    } else {
      // Overnight schedule
      return TimeInterval(((24 * 60 - startMinutes) + endMinutes) * 60)
    }
  }
}

