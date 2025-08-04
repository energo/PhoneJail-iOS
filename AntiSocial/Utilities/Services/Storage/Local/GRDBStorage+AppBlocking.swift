//
//  GRDBStorage+AppBlocking.swift
//  AntiSocial
//
//  Created by AI Assistant on 12.01.2025.
//

import Foundation
import GRDB

extension GRDBStorage {
    
    // MARK: - Setup Blocking Tables
    
    func setupBlockingTables() throws {
        try writer?.write { db in
            // Таблица сессий блокировки
            try db.create(table: "app_blocking_sessions", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("userId", .text).notNull().references("users", onDelete: .cascade)
                t.column("applicationToken", .blob).notNull()
                t.column("appDisplayName", .text).notNull()
                t.column("startDate", .datetime).notNull()
                t.column("endDate", .datetime)
                t.column("plannedDuration", .double).notNull()
                t.column("actualDuration", .double)
                t.column("wasCompleted", .boolean).notNull()
                t.column("createdAt", .datetime).notNull()
            }
            
            // Таблица дневной статистики
            try db.create(table: "daily_app_blocking_stats", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("userId", .text).notNull().references("users", onDelete: .cascade)
                t.column("date", .text).notNull() // yyyy-MM-dd
                t.column("applicationToken", .blob).notNull()
                t.column("appDisplayName", .text).notNull()
                t.column("totalBlockedDuration", .double).notNull()
                t.column("sessionsCount", .integer).notNull()
                t.column("completedSessionsCount", .integer).notNull()
                t.column("averageSessionDuration", .double).notNull()
                
                // Составной уникальный индекс
                t.uniqueKey(["userId", "date", "applicationToken"])
            }
            
            // Индексы для быстрого поиска
            try db.create(index: "idx_blocking_sessions_user_date", 
                         on: "app_blocking_sessions", 
                         columns: ["userId", "startDate"], 
                         ifNotExists: true)
            
            try db.create(index: "idx_daily_stats_user_date", 
                         on: "daily_app_blocking_stats", 
                         columns: ["userId", "date"], 
                         ifNotExists: true)
            
            try db.create(index: "idx_blocking_sessions_active", 
                         on: "app_blocking_sessions", 
                         columns: ["userId", "endDate"], 
                         ifNotExists: true)
        }
    }
    
    // MARK: - Blocking Sessions CRUD
    
    func saveBlockingSession(_ session: AppBlockingSession) async throws {
        try await writer?.write { db in
            try session.save(db)
        }
    }
    
    func getBlockingSessions(for userId: String) async throws -> [AppBlockingSession] {
        return try await writer?.read { db in
            try AppBlockingSession
                .filter(Column("userId") == userId)
                .order(Column("startDate").desc)
                .fetchAll(db)
        } ?? []
    }
    
    func getActiveBlockingSessions(for userId: String) async throws -> [AppBlockingSession] {
        return try await writer?.read { db in
            try AppBlockingSession
                .filter(Column("userId") == userId && Column("endDate") == nil)
                .fetchAll(db)
        } ?? []
    }
    
    func getBlockingSession(by id: String) async throws -> AppBlockingSession? {
        return try await writer?.read { db in
            try AppBlockingSession
                .filter(Column("id") == id)
                .fetchOne(db)
        }
    }
    
    func updateBlockingSession(_ session: AppBlockingSession) async throws {
        try await writer?.write { db in
            try session.update(db)
        }
    }
    
    func deleteBlockingSession(id: String) async throws {
        try await writer?.write { db in
            _ = try AppBlockingSession
                .filter(Column("id") == id)
                .deleteAll(db)
        }
    }
    
    // MARK: - Daily Stats CRUD
    
    func saveDailyBlockingStats(_ stats: DailyAppBlockingStats) async throws {
        try await writer?.write { db in
            try stats.save(db)
        }
    }
    
    func getDailyBlockingStats(for userId: String, date: Date) async throws -> [DailyAppBlockingStats] {
        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        return try await writer?.read { db in
            try DailyAppBlockingStats
                .filter(Column("userId") == userId && Column("date") == dateString)
                .fetchAll(db)
        } ?? []
    }
    
    func getBlockingStatsForPeriod(for userId: String, from: Date, to: Date) async throws -> [DailyAppBlockingStats] {
        let fromString = DateFormatter.yyyyMMdd.string(from: from)
        let toString = DateFormatter.yyyyMMdd.string(from: to)
        
        return try await writer?.read { db in
            try DailyAppBlockingStats
                .filter(
                    Column("userId") == userId &&
                    Column("date") >= fromString &&
                    Column("date") <= toString
                )
                .order(Column("date").desc)
                .fetchAll(db)
        } ?? []
    }
    
    func getTopBlockedApps(for userId: String, limit: Int) async throws -> [(appName: String, totalDuration: TimeInterval)] {
        return try await writer?.read { db in
            let sql = """
                SELECT appDisplayName, SUM(totalBlockedDuration) as total
                FROM daily_app_blocking_stats 
                WHERE userId = ?
                GROUP BY appDisplayName, applicationToken
                ORDER BY total DESC
                LIMIT ?
                """
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: [userId, limit])
            return rows.map { row in
                (appName: row["appDisplayName"] as String, totalDuration: row["total"] as TimeInterval)
            }
        } ?? []
    }
    
    func deleteOldBlockingData(olderThan date: Date) async throws {
        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        
        try await writer?.write { db in
            // Удаляем старые сессии
            _ = try AppBlockingSession
                .filter(Column("startDate") < date)
                .deleteAll(db)
            
            // Удаляем старую статистику
            _ = try DailyAppBlockingStats
                .filter(Column("date") < dateString)
                .deleteAll(db)
        }
    }
    
    func getAllBlockingStats(for userId: String) async throws -> [DailyAppBlockingStats] {
        return try await writer?.read { db in
            try DailyAppBlockingStats
                .filter(Column("userId") == userId)
                .fetchAll(db)
        } ?? []
    }
    
    // MARK: - Aggregation Methods
    
    /// Создать или обновить дневную статистику на основе завершенной сессии
    func updateDailyStatsForSession(_ session: AppBlockingSession) async throws {
        guard session.endDate != nil else { return }
        
        let dateString = DateFormatter.yyyyMMdd.string(from: session.startDate)
        
        try await writer?.write { db in
            // Получаем все сессии для этого приложения в этот день
            // Сначала получаем все сессии для этого пользователя и приложения
            let allSessions = try AppBlockingSession
                .filter(
                    Column("userId") == session.userId &&
                    Column("appDisplayName") == session.appDisplayName &&
                    Column("applicationToken") == session.applicationToken
                )
                .fetchAll(db)
            
            // Фильтруем по дате на клиенте (поскольку SQLite date functions могут быть недоступны)
            let calendar = Calendar.current
            let sessionDate = calendar.startOfDay(for: session.startDate)
            let sessions = allSessions.filter { 
                calendar.isDate($0.startDate, inSameDayAs: sessionDate) 
            }
            
            // Вычисляем статистику
            let completedSessions = sessions.filter { $0.wasCompleted }
            let totalDuration = sessions.compactMap { $0.actualDuration }.reduce(0, +)
            let averageDuration = totalDuration > 0 ? totalDuration / Double(sessions.count) : 0
            
            // Создаем или обновляем запись статистики
            let statsId = "\(session.userId)_\(dateString)_\(session.appDisplayName)"
            
            let stats = DailyAppBlockingStats(
                id: statsId,
                userId: session.userId,
                date: dateString,
                applicationToken: session.applicationToken,
                appDisplayName: session.appDisplayName,
                totalBlockedDuration: totalDuration,
                sessionsCount: sessions.count,
                completedSessionsCount: completedSessions.count,
                averageSessionDuration: averageDuration
            )
            
            try stats.save(db)
        }
    }
} 
