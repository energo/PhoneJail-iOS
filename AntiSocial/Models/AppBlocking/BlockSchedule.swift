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
        let calendar = Calendar.current
        let now = Date()
        
        // Create start and end dates for today
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = startTime.hour
        startComponents.minute = startTime.minute
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = endTime.hour
        endComponents.minute = endTime.minute
        
        // Handle overnight schedules
        if let start = calendar.date(from: startComponents),
           let end = calendar.date(from: endComponents) {
            var finalEnd = end
            if end <= start {
                // Schedule goes past midnight
                finalEnd = calendar.date(byAdding: .day, value: 1, to: end) ?? end
            }
            
            return DeviceActivitySchedule(
                intervalStart: startTime,
                intervalEnd: endTime,
                repeats: true,
                warningTime: nil
            )
        }
        
        // Fallback
        return DeviceActivitySchedule(
            intervalStart: startTime,
            intervalEnd: endTime,
            repeats: true
        )
    }
}

// MARK: - Persistence
extension BlockSchedule {
    static let storageKey = "blockSchedules"
    
    static func loadAll() -> [BlockSchedule] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let schedules = try? JSONDecoder().decode([BlockSchedule].self, from: data) else {
            return []
        }
        return schedules
    }
    
    static func saveAll(_ schedules: [BlockSchedule]) {
        if let data = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    static func add(_ schedule: BlockSchedule) {
        var schedules = loadAll()
        schedules.append(schedule)
        saveAll(schedules)
    }
    
    static func update(_ schedule: BlockSchedule) {
        var schedules = loadAll()
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            saveAll(schedules)
        }
    }
    
    static func delete(id: String) {
        var schedules = loadAll()
        schedules.removeAll { $0.id == id }
        saveAll(schedules)
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