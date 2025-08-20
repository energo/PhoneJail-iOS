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

extension DeviceActivityEvent.Name {
    static func scheduledBlockStart(id: String) -> Self {
        Self("scheduledBlockStart_\(id)")
    }
    
    static func scheduledBlockEnd(id: String) -> Self {
        Self("scheduledBlockEnd_\(id)")
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
    private let center = DeviceActivityCenter()
    private var activeMonitors: Set<String> = []
    
    private init() {
        loadActiveSchedules()
        setupSchedules()
    }
    
    // MARK: - Public Methods
    
    func activateSchedule(_ schedule: BlockSchedule) {
        guard schedule.isActive else { return }
        
        // Create unique activity name for this schedule
        let activityName = DeviceActivityName.scheduledBlock(id: schedule.id)
        
        // Create device activity schedule
        let deviceSchedule = schedule.createDeviceActivitySchedule()
        
        // Start monitoring WITHOUT events - we'll handle start/end in the extension
        do {
            try center.startMonitoring(activityName, during: deviceSchedule)
            activeMonitors.insert(schedule.id)
            
            // Save schedule data to SharedData for extension access
            saveScheduleToSharedData(schedule)
            
            // Apply restrictions ONLY if schedule is currently active
            if isScheduleActiveNow(schedule) {
                applyRestrictions(for: schedule)
            } else {
                // Make sure restrictions are removed if not in active time
                removeRestrictions(for: schedule)
            }
            
            // Update schedule status
            var updatedSchedule = schedule
            updatedSchedule.isActive = true
            BlockSchedule.update(updatedSchedule)
            
            // Reload active schedules
            loadActiveSchedules()
            
            // Schedule notification
            scheduleNotification(for: schedule)
            
            AppLogger.notice("Activated schedule: \(schedule.name)")
        } catch {
            AppLogger.critical(error, details: "Failed to activate schedule: \(schedule.name)")
        }
    }
    
    func deactivateSchedule(_ schedule: BlockSchedule) {
        let activityName = DeviceActivityName.scheduledBlock(id: schedule.id)
        
        // Stop monitoring
        center.stopMonitoring([activityName])
        activeMonitors.remove(schedule.id)
        
        // Remove restrictions
        removeRestrictions(for: schedule)
        
        // Update schedule status
        var updatedSchedule = schedule
        updatedSchedule.isActive = false
        BlockSchedule.update(updatedSchedule)
        
        // Reload active schedules
        loadActiveSchedules()
        
        // Cancel notifications
        cancelNotification(for: schedule)
        
        AppLogger.notice("Deactivated schedule: \(schedule.name)")
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
                applyRestrictions(for: schedule)
            } else {
                removeRestrictions(for: schedule)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadActiveSchedules() {
        activeSchedules = BlockSchedule.loadAll().filter { $0.isActive }
    }
    
    private func setupSchedules() {
        // Re-activate all active schedules on app launch
        for schedule in activeSchedules {
            activateSchedule(schedule)
        }
    }
    
    private func isScheduleActiveNow(_ schedule: BlockSchedule) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        
        // Check if today is in the schedule
        guard schedule.daysOfWeek.contains(weekday) else {
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
            return false
        }
        
        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        // Handle overnight schedules
        if endMinutes < startMinutes {
            // Schedule crosses midnight
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        } else {
            // Normal schedule
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
    }
    
    private func saveScheduleToSharedData(_ schedule: BlockSchedule) {
        // Save schedule data to SharedData for extension access
        let encoder = PropertyListEncoder()
        if let data = try? encoder.encode(schedule.selection) {
            SharedData.userDefaults?.set(data, forKey: "schedule_\(schedule.id)_selection")
        }
        SharedData.userDefaults?.set(schedule.name, forKey: "schedule_\(schedule.id)_name")
        SharedData.userDefaults?.set(schedule.isStrictBlock, forKey: "schedule_\(schedule.id)_strict")
        
        // Save days of week
        let daysArray = Array(schedule.daysOfWeek)
        SharedData.userDefaults?.set(daysArray, forKey: "schedule_\(schedule.id)_daysOfWeek")
        
        // Save schedule times
        if let startHour = schedule.startTime.hour,
           let startMinute = schedule.startTime.minute,
           let endHour = schedule.endTime.hour,
           let endMinute = schedule.endTime.minute {
            SharedData.userDefaults?.set(startHour, forKey: "schedule_\(schedule.id)_startHour")
            SharedData.userDefaults?.set(startMinute, forKey: "schedule_\(schedule.id)_startMinute")
            SharedData.userDefaults?.set(endHour, forKey: "schedule_\(schedule.id)_endHour")
            SharedData.userDefaults?.set(endMinute, forKey: "schedule_\(schedule.id)_endMinute")
        }
        
        // Also save the full schedule as JSON for the extension
        if let scheduleData = try? JSONEncoder().encode(schedule) {
            SharedData.userDefaults?.set(scheduleData, forKey: "schedule_\(schedule.id)_data")
        }
    }
    
    private func applyRestrictions(for schedule: BlockSchedule) {
        let storeName = ManagedSettingsStore.Name.scheduledBlock(id: schedule.id)
        let store = ManagedSettingsStore(named: storeName)
        
        // Clear existing settings first
        store.clearAllSettings()
        
        // Apply app restrictions
        store.shield.applications = schedule.selection.applicationTokens
        
        if schedule.isStrictBlock {
            // Strict mode - block all categories
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
        } else {
            // Normal mode - only block selected categories
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(schedule.selection.categoryTokens)
        }
        
        store.shield.webDomains = schedule.selection.webDomainTokens
        
        // Save to SharedData for extensions
        SharedData.userDefaults?.set(true, forKey: "schedule_\(schedule.id)_active")
        SharedData.userDefaults?.set(true, forKey: SharedData.Widget.isBlocked)
        SharedData.userDefaults?.set(schedule.isStrictBlock, forKey: SharedData.Widget.isStricted)
        
        // Set the blocking timestamp for this schedule
        SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: "schedule_\(schedule.id)_startTimestamp")
        
        AppLogger.trace("Applied restrictions for schedule: \(schedule.name)")
    }
    
    private func removeRestrictions(for schedule: BlockSchedule) {
        let storeName = ManagedSettingsStore.Name.scheduledBlock(id: schedule.id)
        let store = ManagedSettingsStore(named: storeName)
        
        // Clear all restrictions
        store.clearAllSettings()
        
        // Clear from SharedData
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_active")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_strict")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_selection")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_name")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_daysOfWeek")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_startHour")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_startMinute")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_endHour")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_endMinute")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_startTimestamp")
        SharedData.userDefaults?.removeObject(forKey: "schedule_\(schedule.id)_data")
        
        // Check if any other schedules are active, if not, clear global blocking state
        let activeSchedules = BlockSchedule.loadAll().filter { $0.isActive && $0.id != schedule.id }
        if activeSchedules.isEmpty {
            SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
            SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isStricted)
        }
        
        AppLogger.trace("Removed restrictions for schedule: \(schedule.name)")
    }
    
    // MARK: - Notifications
    
    private func scheduleNotification(for schedule: BlockSchedule) {
        let content = UNMutableNotificationContent()
        content.title = "Block Schedule Active"
        content.body = "\(schedule.name) is now active. Selected apps will be blocked."
        content.sound = .default
        
        // Create trigger based on schedule
        guard let startHour = schedule.startTime.hour,
              let startMinute = schedule.startTime.minute else { return }
        
        for weekday in schedule.daysOfWeek {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = startHour
            dateComponents.minute = startMinute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "schedule_\(schedule.id)_day_\(weekday)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    AppLogger.critical(error, details: "Failed to schedule notification")
                }
            }
        }
    }
    
    private func cancelNotification(for schedule: BlockSchedule) {
        var identifiers: [String] = []
        for weekday in 1...7 {
            identifiers.append("schedule_\(schedule.id)_day_\(weekday)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
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

