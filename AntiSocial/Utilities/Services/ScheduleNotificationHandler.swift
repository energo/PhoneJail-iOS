//
//  ScheduleNotificationHandler.swift
//  AntiSocial
//
//  Created by Assistant on 26.01.2025.
//

import SwiftUI
import UserNotifications
import Combine

// MARK: - Global Schedule Notification Handler
class ScheduleNotificationHandler: NSObject, ObservableObject {
    static let shared = ScheduleNotificationHandler()
    
    // Published property to trigger UI updates
    @Published var lastUpdateTimestamp: Date = Date()
    
    // Subject for schedule updates
    private let scheduleUpdateSubject = PassthroughSubject<String, Never>()
    var scheduleUpdatePublisher: AnyPublisher<String, Never> {
        scheduleUpdateSubject.eraseToAnyPublisher()
    }
    
    private override init() {
        super.init()
        setupNotificationObservers()
    }
    
    // MARK: - Setup Observers
    private func setupNotificationObservers() {
        // We don't need NotificationCenter observers - we'll handle via UNUserNotificationCenterDelegate
        AppLogger.notice("📱 ScheduleNotificationHandler initialized as UNUserNotificationCenter delegate")
    }
    
    // MARK: - Schedule State Updates
    func handleScheduleStart(scheduleId: String) {
        AppLogger.notice("📅 Schedule Start: \(scheduleId)")
        
        // Check and update schedule state
        BlockSchedulerService.shared.checkAndApplyActiveSchedules()
        
        // Force reload schedules
        BlockSchedulerService.shared.reloadSchedules()
        
        // Trigger UI update
        triggerUpdate("schedule_start_\(scheduleId)")
    }
    
    func handleScheduleEnd(scheduleId: String) {
        AppLogger.notice("📅 Schedule End: \(scheduleId)")
        
        // Check and update schedule state
        BlockSchedulerService.shared.checkAndApplyActiveSchedules()
        
        // Force reload schedules
        BlockSchedulerService.shared.reloadSchedules()
        
        // Trigger UI update
        triggerUpdate("schedule_end_\(scheduleId)")
    }
    
    // MARK: - Trigger UI Updates
    func triggerUpdate(_ reason: String = "") {
        DispatchQueue.main.async { [weak self] in
            AppLogger.notice("🔄 Triggering UI update: \(reason)")
            self?.lastUpdateTimestamp = Date()
            self?.scheduleUpdateSubject.send(reason)
            
            // Also send objectWillChange to force UI refresh
            self?.objectWillChange.send()
        }
    }
    
    // MARK: - Manual Refresh
    func refreshSchedules() {
        AppLogger.notice("🔄 Manual refresh requested")
        BlockSchedulerService.shared.checkAndApplyActiveSchedules()
        BlockSchedulerService.shared.reloadSchedules()
        triggerUpdate("manual_refresh")
    }
}

// MARK: - UNUserNotificationCenterDelegate Extension
extension ScheduleNotificationHandler: UNUserNotificationCenterDelegate {
    
    // Called when notification is received while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let identifier = notification.request.identifier
        AppLogger.notice("📱 Notification received in foreground: \(identifier)")
        
        // Check if this is a schedule notification
        if identifier.contains("schedule_") {
            handleScheduleRelatedNotification(identifier: identifier)
        }
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Called when user taps on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let identifier = response.notification.request.identifier
        AppLogger.notice("📱 Notification tapped: \(identifier)")
        
        // Check if this is a schedule notification
        if identifier.contains("schedule_") {
            handleScheduleRelatedNotification(identifier: identifier)
        }
        
        completionHandler()
    }
    
    // MARK: - Handle Schedule Notifications
    private func handleScheduleRelatedNotification(identifier: String) {
        AppLogger.notice("📱 Processing schedule notification: \(identifier)")
        
        // Parse the notification identifier
        // New format: schedule_{id}_started or schedule_{id}_ended
        // Old format: schedule_{id}_day_{weekday}_{start|end}
        
        if identifier.contains("_started") {
            let scheduleId = identifier.replacingOccurrences(of: "schedule_", with: "")
                                      .replacingOccurrences(of: "_started", with: "")
            handleScheduleStart(scheduleId: scheduleId)
        } else if identifier.contains("_ended") {
            let scheduleId = identifier.replacingOccurrences(of: "schedule_", with: "")
                                      .replacingOccurrences(of: "_ended", with: "")
            handleScheduleEnd(scheduleId: scheduleId)
        } else {
            // Try old format for compatibility
            let components = identifier.split(separator: "_")
            if components.count >= 5 {
                let scheduleId = String(components[1])
                let eventType = String(components[4])
                
                if eventType == "start" {
                    handleScheduleStart(scheduleId: scheduleId)
                } else if eventType == "end" {
                    handleScheduleEnd(scheduleId: scheduleId)
                }
            }
        }
    }
}