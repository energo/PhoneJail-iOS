//
//  AppBlockingSession.swift
//  AntiSocial
//
//  Created by AI Assistant on 12.01.2025.
//

import Foundation
import GRDB
import ManagedSettings

struct AppBlockingSession: Identifiable, Codable, Hashable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "app_blocking_sessions"
    
    let id: String
    let userId: String
    let applicationToken: Data
    let appDisplayName: String
    let startDate: Date
    var endDate: Date?
    let plannedDuration: TimeInterval
    var actualDuration: TimeInterval?
    var wasCompleted: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId, applicationToken, appDisplayName
        case startDate, endDate, plannedDuration, actualDuration
        case wasCompleted, createdAt
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         applicationToken: Data,
         appDisplayName: String,
         startDate: Date,
         endDate: Date? = nil,
         plannedDuration: TimeInterval,
         actualDuration: TimeInterval? = nil,
         wasCompleted: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.applicationToken = applicationToken
        self.appDisplayName = appDisplayName
        self.startDate = startDate
        self.endDate = endDate
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.wasCompleted = wasCompleted
        self.createdAt = createdAt
    }
    
    // MARK: - Convenience Initializer with ApplicationToken
    init(id: String = UUID().uuidString,
         userId: String,
         applicationToken: ApplicationToken,
         appDisplayName: String,
         startDate: Date,
         plannedDuration: TimeInterval) throws {
        let tokenData = try JSONEncoder().encode(applicationToken)
        
        self.init(
            id: id,
            userId: userId,
            applicationToken: tokenData,
            appDisplayName: appDisplayName,
            startDate: startDate,
            endDate: nil,
            plannedDuration: plannedDuration,
            actualDuration: nil,
            wasCompleted: false,
            createdAt: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    /// Получить ApplicationToken из сохраненных данных
    func getApplicationToken() throws -> ApplicationToken {
        return try JSONDecoder().decode(ApplicationToken.self, from: applicationToken)
    }
    
    /// Завершить сессию блокировки
    mutating func complete(actualEndDate: Date) {
        self.endDate = actualEndDate
        self.actualDuration = actualEndDate.timeIntervalSince(startDate)
        self.wasCompleted = true
    }
    
    /// Прервать сессию блокировки (досрочно)
    mutating func interrupt(actualEndDate: Date) {
        self.endDate = actualEndDate
        self.actualDuration = actualEndDate.timeIntervalSince(startDate)
        self.wasCompleted = false
    }
    
    /// Проверить, активна ли сессия
    var isActive: Bool {
        return endDate == nil
    }
    
    /// Форматированное время запланированной длительности
    var plannedDurationString: String {
        return formatDuration(plannedDuration)
    }
    
    /// Форматированное время фактической длительности
    var actualDurationString: String {
        guard let actual = actualDuration else { return "--:--" }
        return formatDuration(actual)
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
    
    // MARK: - GRDB Conformance
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        applicationToken = try container.decode(Data.self, forKey: .applicationToken)
        appDisplayName = try container.decode(String.self, forKey: .appDisplayName)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        plannedDuration = try container.decode(TimeInterval.self, forKey: .plannedDuration)
        actualDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .actualDuration)
        wasCompleted = try container.decode(Bool.self, forKey: .wasCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(applicationToken, forKey: .applicationToken)
        try container.encode(appDisplayName, forKey: .appDisplayName)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(plannedDuration, forKey: .plannedDuration)
        try container.encodeIfPresent(actualDuration, forKey: .actualDuration)
        try container.encode(wasCompleted, forKey: .wasCompleted)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Hashable Conformance
extension AppBlockingSession {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppBlockingSession, rhs: AppBlockingSession) -> Bool {
        return lhs.id == rhs.id
    }
} 