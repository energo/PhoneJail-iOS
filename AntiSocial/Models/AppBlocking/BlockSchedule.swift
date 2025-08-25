//
//  BlockSchedule.swift
//  AntiSocial
//
//  Created by Claude on 19.01.2025.
//

import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

struct BlockSchedule: Identifiable, Codable {
    let id: String
    var name: String
    var startTime: DateComponents
    var endTime: DateComponents
    var daysOfWeek: Set<Int> // 1 = Sunday, 2 = Monday, etc.
    var selection: FamilyActivitySelection
    var isStrictBlock: Bool
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        startTime: DateComponents,
        endTime: DateComponents,
        daysOfWeek: Set<Int>,
        selection: FamilyActivitySelection,
        isStrictBlock: Bool = false,
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.daysOfWeek = daysOfWeek
        self.selection = selection
        self.isStrictBlock = isStrictBlock
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        let now = Date()
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = startTime.hour
        startComponents.minute = startTime.minute
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = endTime.hour
        endComponents.minute = endTime.minute
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return "Invalid time"
        }
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var daysOfWeekString: String {
        let dayAbbreviations = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = daysOfWeek.sorted()
        
        // Check for special cases
        if sortedDays.count == 7 {
            return "Every day"
        } else if sortedDays == [2, 3, 4, 5, 6] {
            return "Weekdays"
        } else if sortedDays == [1, 7] {
            return "Weekends"
        }
        
        // Return abbreviated days
        return sortedDays.compactMap { day in
            guard day >= 1 && day <= 7 else { return nil }
            return dayAbbreviations[day - 1]
        }.joined(separator: ", ")
    }
    
    var shortDaysString: String {
        let dayAbbreviations = ["S", "M", "T", "W", "T", "F", "S"]
        let sortedDays = daysOfWeek.sorted()
        
        if sortedDays.count >= 5 {
            return "\(sortedDays.count) days"
        }
        
        return sortedDays.compactMap { day in
            guard day >= 1 && day <= 7 else { return nil }
            return dayAbbreviations[day - 1]
        }.joined(separator: ", ")
    }
    
    func isScheduledForToday() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return daysOfWeek.contains(weekday)
    }
    
    func nextScheduledDate() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Check next 7 days
        for dayOffset in 0..<7 {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: checkDate)
            
            if daysOfWeek.contains(weekday) {
                var components = calendar.dateComponents([.year, .month, .day], from: checkDate)
                components.hour = startTime.hour
                components.minute = startTime.minute
                
                if let scheduledDate = calendar.date(from: components) {
                    // If it's today and the time has passed, skip to next occurrence
                    if dayOffset == 0 && scheduledDate <= now {
                        continue
                    }
                    return scheduledDate
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Device Activity Schedule
    
    func createDeviceActivitySchedule() -> DeviceActivitySchedule {
        // Create schedule components with weekdays
        var intervalStart = DateComponents()
        intervalStart.hour = startTime.hour
        intervalStart.minute = startTime.minute
        
        var intervalEnd = DateComponents()
        intervalEnd.hour = endTime.hour
        intervalEnd.minute = endTime.minute
        
        // The DeviceActivitySchedule will repeat daily, but we'll check days in the extension
        return DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: true,
            warningTime: nil
        )
    }
}

// MARK: - Persistence
extension BlockSchedule {
    // Removed storage key - each schedule is stored separately in SharedData
    
    static func loadAll() -> [BlockSchedule] {
        guard let userDefaults = SharedData.userDefaults else { return [] }
        
        var schedules: [BlockSchedule] = []
        
        // Find all schedule keys in SharedData
        for (key, value) in userDefaults.dictionaryRepresentation() {
            if key.hasPrefix("schedule_") && !key.contains("_active") && !key.contains("_startTimestamp") {
                // Try to decode the schedule
                if let data = value as? Data,
                   let schedule = try? JSONDecoder().decode(BlockSchedule.self, from: data) {
                    schedules.append(schedule)
                }
            }
        }
        
        return schedules.sorted { $0.createdAt < $1.createdAt }
    }
    
    static func saveAll(_ schedules: [BlockSchedule]) {
        guard let userDefaults = SharedData.userDefaults else { return }
        
        // First, remove all existing schedule keys
        for key in userDefaults.dictionaryRepresentation().keys {
            if key.hasPrefix("schedule_") && !key.contains("_active") && !key.contains("_startTimestamp") {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        // Save each schedule individually
        for schedule in schedules {
            if let data = try? JSONEncoder().encode(schedule) {
                userDefaults.set(data, forKey: "schedule_\(schedule.id)")
            }
        }
    }
    
    static func add(_ schedule: BlockSchedule) {
        guard let userDefaults = SharedData.userDefaults else { return }
        
        // Save schedule directly to SharedData
        if let data = try? JSONEncoder().encode(schedule) {
            userDefaults.set(data, forKey: "schedule_\(schedule.id)")
            
            // Debug notification
            LocalNotificationManager.scheduleExtensionNotification(
                title: "💾 Schedule Added to SharedData",
                details: "Key: schedule_\(schedule.id)\nSize: \(data.count) bytes"
            )
        }
    }
    
    static func update(_ schedule: BlockSchedule) {
        guard let userDefaults = SharedData.userDefaults else { return }
        
        // Update schedule directly in SharedData
        if let data = try? JSONEncoder().encode(schedule) {
            userDefaults.set(data, forKey: "schedule_\(schedule.id)")
            
            // Debug notification
            LocalNotificationManager.scheduleExtensionNotification(
                title: "📝 Schedule Updated in SharedData",
                details: "Key: schedule_\(schedule.id)\nSize: \(data.count) bytes"
            )
        }
    }
    
    static func delete(id: String) {
        guard let userDefaults = SharedData.userDefaults else { return }
        
        // Remove schedule and related keys from SharedData
        userDefaults.removeObject(forKey: "schedule_\(id)")
        userDefaults.removeObject(forKey: "schedule_\(id)_active")
        userDefaults.removeObject(forKey: "schedule_\(id)_startTimestamp")
    }
}

// MARK: - Hashable Conformance
extension BlockSchedule: Hashable {
    static func == (lhs: BlockSchedule, rhs: BlockSchedule) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}