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
    private let center = DeviceActivityCenter()
    private var activeMonitors: Set<String> = []
    
    private init() {
        loadActiveSchedules()
        setupSchedules()
    }
    
    // MARK: - Public Methods
    
    func activateSchedule(_ schedule: BlockSchedule) {
        guard schedule.isActive else { return }
        
        // Create device activity schedule
        let activityName = DeviceActivityName.scheduledBlock(id: schedule.id)
        let deviceSchedule = schedule.createDeviceActivitySchedule()
        
        // Start monitoring
        do {
            try center.startMonitoring(activityName, during: deviceSchedule)
            activeMonitors.insert(schedule.id)
            
            // Apply restrictions if schedule is currently active
            if isScheduleActiveNow(schedule) {
                applyRestrictions(for: schedule)
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
    
    private func applyRestrictions(for schedule: BlockSchedule) {
        let storeName = ManagedSettingsStore.Name.scheduledBlock(id: schedule.id)
        let store = ManagedSettingsStore(named: storeName)
        
        // Apply app restrictions
        store.shield.applications = schedule.selection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(schedule.selection.categoryTokens)
        store.shield.webDomains = schedule.selection.webDomainTokens
        
        // Configure shield behavior
        if schedule.isStrictBlock {
            // Strict mode - no way to bypass
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all(except: Set())
        }
        
        // Save to SharedData for extensions
        SharedData.userDefaults?.set(true, forKey: "schedule_\(schedule.id)_active")
        SharedData.userDefaults?.set(schedule.isStrictBlock, forKey: "schedule_\(schedule.id)_strict")
        
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

