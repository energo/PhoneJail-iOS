//
//  DailyAppBlockingStats.swift
//  AntiSocial
//
//  Created by AI Assistant on 12.01.2025.
//

import Foundation
import GRDB
import ManagedSettings

struct DailyAppBlockingStats: Identifiable, Codable, Hashable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "daily_app_blocking_stats"
    
    let id: String
    let userId: String
    let date: String // yyyy-MM-dd format
    let applicationToken: Data
    let appDisplayName: String
    let totalBlockedDuration: TimeInterval
    let sessionsCount: Int
    let completedSessionsCount: Int
    let averageSessionDuration: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case id, userId, date, applicationToken, appDisplayName
        case totalBlockedDuration, sessionsCount, completedSessionsCount, averageSessionDuration
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         date: String,
         applicationToken: Data,
         appDisplayName: String,
         totalBlockedDuration: TimeInterval,
         sessionsCount: Int,
         completedSessionsCount: Int,
         averageSessionDuration: TimeInterval) {
        self.id = id
        self.userId = userId
        self.date = date
        self.applicationToken = applicationToken
        self.appDisplayName = appDisplayName
        self.totalBlockedDuration = totalBlockedDuration
        self.sessionsCount = sessionsCount
        self.completedSessionsCount = completedSessionsCount
        self.averageSessionDuration = averageSessionDuration
    }
    
    // MARK: - Convenience Initializer with ApplicationToken
    init(id: String = UUID().uuidString,
         userId: String,
         date: Date,
         applicationToken: ApplicationToken,
         appDisplayName: String,
         totalBlockedDuration: TimeInterval,
         sessionsCount: Int,
         completedSessionsCount: Int,
         averageSessionDuration: TimeInterval) throws {
        let tokenData = try JSONEncoder().encode(applicationToken)
        let dateString = Self.dateFormatter.string(from: date)
        
        self.init(
            id: id,
            userId: userId,
            date: dateString,
            applicationToken: tokenData,
            appDisplayName: appDisplayName,
            totalBlockedDuration: totalBlockedDuration,
            sessionsCount: sessionsCount,
            completedSessionsCount: completedSessionsCount,
            averageSessionDuration: averageSessionDuration
        )
    }
    
    // MARK: - Static Methods for Aggregation
    
    /// Создать статистику из списка сессий блокировки
    static func createFromSessions(_ sessions: [AppBlockingSession], 
                                 for date: Date, 
                                 userId: String, 
                                 applicationToken: ApplicationToken, 
                                 appDisplayName: String) throws -> DailyAppBlockingStats {
        let totalDuration = sessions.compactMap { $0.actualDuration }.reduce(0, +)
        let completedCount = sessions.filter { $0.wasCompleted }.count
        let averageDuration = totalDuration > 0 ? totalDuration / Double(sessions.count) : 0
        
        return try DailyAppBlockingStats(
            userId: userId,
            date: date,
            applicationToken: applicationToken,
            appDisplayName: appDisplayName,
            totalBlockedDuration: totalDuration,
            sessionsCount: sessions.count,
            completedSessionsCount: completedCount,
            averageSessionDuration: averageDuration
        )
    }
    
    // MARK: - Helper Methods
    
    /// Получить ApplicationToken из сохраненных данных
    func getApplicationToken() throws -> ApplicationToken {
        return try JSONDecoder().decode(ApplicationToken.self, from: applicationToken)
    }
    
    /// Получить дату как Date объект
    func getDate() -> Date? {
        return Self.dateFormatter.date(from: date)
    }
    
    /// Процент завершенных сессий
    var completionRate: Double {
        guard sessionsCount > 0 else { return 0 }
        return Double(completedSessionsCount) / Double(sessionsCount) * 100
    }
    
    /// Форматированное время общей блокировки
    var totalBlockedDurationString: String {
        return formatDuration(totalBlockedDuration)
    }
    
    /// Форматированное время средней сессии
    var averageSessionDurationString: String {
        return formatDuration(averageSessionDuration)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Date Formatter
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - GRDB Conformance
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        date = try container.decode(String.self, forKey: .date)
        applicationToken = try container.decode(Data.self, forKey: .applicationToken)
        appDisplayName = try container.decode(String.self, forKey: .appDisplayName)
        totalBlockedDuration = try container.decode(TimeInterval.self, forKey: .totalBlockedDuration)
        sessionsCount = try container.decode(Int.self, forKey: .sessionsCount)
        completedSessionsCount = try container.decode(Int.self, forKey: .completedSessionsCount)
        averageSessionDuration = try container.decode(TimeInterval.self, forKey: .averageSessionDuration)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(date, forKey: .date)
        try container.encode(applicationToken, forKey: .applicationToken)
        try container.encode(appDisplayName, forKey: .appDisplayName)
        try container.encode(totalBlockedDuration, forKey: .totalBlockedDuration)
        try container.encode(sessionsCount, forKey: .sessionsCount)
        try container.encode(completedSessionsCount, forKey: .completedSessionsCount)
        try container.encode(averageSessionDuration, forKey: .averageSessionDuration)
    }
}

// MARK: - Hashable Conformance
extension DailyAppBlockingStats {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DailyAppBlockingStats, rhs: DailyAppBlockingStats) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
} 