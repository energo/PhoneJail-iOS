//
//  AppBlockingLogger.swift
//  AntiSocial
//
//  Created by AI Assistant on 12.01.2025.
//

import Foundation
import ManagedSettings



/// Структура для хранения статистики блокировок за день
struct TodayBlockingStats {
    let totalBlockingTime: TimeInterval
    let completedSessions: Int
    let totalSessions: Int
    
    static var empty: TodayBlockingStats {
        TodayBlockingStats(totalBlockingTime: 0, completedSessions: 0, totalSessions: 0)
    }
}

/// Сервис для логирования и управления блокировками приложений
@MainActor
final class AppBlockingLogger: ObservableObject {
    
    static let shared = AppBlockingLogger()
    
    @Published private(set) var activeSessions: [AppBlockingSession] = []
    @Published private(set) var todayStats: [DailyAppBlockingStats] = []
    
    private init() {
        // Загружаем статистику при инициализации
        Task {
            await loadActiveSessions()
            await loadTodayStats()
        }
    }
    
    // MARK: - Session Management
    
    /// Начать сессию блокировки приложения
    func startBlockingSession(
        applicationToken: ApplicationToken,
        appDisplayName: String,
        plannedDuration: TimeInterval
    ) async throws -> AppBlockingSession {
        guard let currentUser = Storage.shared.user else {
            throw AppBlockingError.userNotSet
        }
        
        let session = try AppBlockingSession(
            userId: currentUser.id,
            applicationToken: applicationToken,
            appDisplayName: appDisplayName,
            startDate: Date(),
            plannedDuration: plannedDuration
        )
        
        try await Storage.shared.saveBlockingSession(session)
        
        await loadActiveSessions()
        
        AppLogger.notice("Started blocking session for \(appDisplayName), duration: \(plannedDuration)s")
        
        return session
    }
    
    /// Завершить сессию блокировки (успешно)
    func completeBlockingSession(_ sessionId: String) async throws {
        guard let currentUser = Storage.shared.user else {
            throw AppBlockingError.userNotSet
        }
        
        var sessions = try await Storage.shared.getBlockingSessions(for: currentUser.id)
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
            throw AppBlockingError.sessionNotFound
        }
        
        var session = sessions[index]
        session.complete(actualEndDate: Date())
        
        try await Storage.shared.updateBlockingSession(session)
        try await Storage.shared.updateDailyStatsForSession(session)
        
        await loadActiveSessions()
        await loadTodayStats()
        
        AppLogger.notice("Completed blocking session for \(session.appDisplayName)")
    }
    
    /// Прервать сессию блокировки (досрочно)
    func interruptBlockingSession(_ sessionId: String) async throws {
        guard let currentUser = Storage.shared.user else {
            throw AppBlockingError.userNotSet
        }
        
        var sessions = try await Storage.shared.getBlockingSessions(for: currentUser.id)
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
            throw AppBlockingError.sessionNotFound
        }
        
        var session = sessions[index]
        session.interrupt(actualEndDate: Date())
        
        try await Storage.shared.updateBlockingSession(session)
        try await Storage.shared.updateDailyStatsForSession(session)
        
        await loadActiveSessions()
        await loadTodayStats()
        
        AppLogger.notice("Interrupted blocking session for \(session.appDisplayName)")
    }
    
    // MARK: - Data Loading
    
    /// Загрузить активные сессии
    func loadActiveSessions() async {
        do {
            guard let currentUser = Storage.shared.user else { return }
            
            let sessions = try await Storage.shared.getActiveBlockingSessions(for: currentUser.id)
            self.activeSessions = sessions
        } catch {
            AppLogger.critical(error, details: "Failed to load active blocking sessions")
        }
    }
    
    /// Загрузить статистику за сегодня
    func loadTodayStats() async {
        do {
            guard let currentUser = Storage.shared.user else { return }
            
            let stats = try await Storage.shared.getDailyBlockingStats(for: currentUser.id, date: Date())
            self.todayStats = stats
            
            // Сохраняем данные в SharedData для доступа из расширения
            await updateSharedStats()
        } catch {
            AppLogger.critical(error, details: "Failed to load today's blocking stats")
        }
    }
    
    /// Обновить статистику в SharedData для расширения
    @MainActor
    private func updateSharedStats() {
        let totalTime = getTodayTotalBlockingTime()
        let completedCount = getTodayCompletedSessions()
        let totalCount = getTodayTotalSessions()
        
        SharedDataConstants.userDefaults?.set(totalTime, forKey: SharedDataConstants.AppBlocking.todayTotalBlockingTime)
        SharedDataConstants.userDefaults?.set(completedCount, forKey: SharedDataConstants.AppBlocking.todayCompletedSessions)
        SharedDataConstants.userDefaults?.set(totalCount, forKey: SharedDataConstants.AppBlocking.todayTotalSessions)
        
        AppLogger.notice("Updated shared blocking stats: \(totalTime)s total, \(completedCount)/\(totalCount) sessions")
    }
    
    // MARK: - Statistics
    
    /// Получить общее время блокировки за сегодня
    func getTodayTotalBlockingTime() -> TimeInterval {
        return todayStats.reduce(0) { $0 + $1.totalBlockedDuration }
    }
    
    /// Получить количество завершенных сессий за сегодня
    func getTodayCompletedSessions() -> Int {
        return todayStats.reduce(0) { $0 + $1.completedSessionsCount }
    }
    
    /// Получить общее количество сессий за сегодня
    func getTodayTotalSessions() -> Int {
        return todayStats.reduce(0) { $0 + $1.sessionsCount }
    }
    
    /// Получить процент завершенных сессий за сегодня
    func getTodayCompletionRate() -> Double {
        let total = getTodayTotalSessions()
        guard total > 0 else { return 0 }
        
        let completed = getTodayCompletedSessions()
        return Double(completed) / Double(total) * 100
    }
    
    /// Получить топ заблокированных приложений
    func getTopBlockedApps(limit: Int = 5) async throws -> [(appName: String, totalDuration: TimeInterval)] {
        guard let currentUser = Storage.shared.user else {
            throw AppBlockingError.userNotSet
        }
        
        return try await Storage.shared.getTopBlockedApps(for: currentUser.id, limit: limit)
    }
    
    // MARK: - Cleanup
    
    /// Очистить старые данные (старше указанной даты)
    func cleanupOldData(olderThan date: Date) async throws {
        try await Storage.shared.deleteOldBlockingData(olderThan: date)
        AppLogger.notice("Cleaned up blocking data older than \(date)")
    }
    
    /// Очистить данные старше 30 дней
    func cleanupOldData() async throws {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        try await cleanupOldData(olderThan: thirtyDaysAgo)
    }
    
    // MARK: - Helpers
    
    /// Найти активную сессию для приложения
    func findActiveSession(for applicationToken: ApplicationToken) -> AppBlockingSession? {
        return activeSessions.first { session in
            do {
                let sessionToken = try session.getApplicationToken()
                return sessionToken == applicationToken
            } catch {
                return false
            }
        }
    }
    
    /// Проверить, заблокировано ли приложение сейчас
    func isAppCurrentlyBlocked(_ applicationToken: ApplicationToken) -> Bool {
        return findActiveSession(for: applicationToken) != nil
    }
    
    /// Принудительно обновить все данные и SharedData
    func refreshAllData() async {
        await loadActiveSessions()
        await loadTodayStats()
    }
    
    // MARK: - Static Methods for Extensions
    
    /// Получить статистику блокировок за сегодня из SharedData (для использования в расширениях)
    static func getTodayBlockingStatsFromSharedData() -> TodayBlockingStats {
        let totalBlockingTime = SharedDataConstants.userDefaults?.double(forKey: SharedDataConstants.AppBlocking.todayTotalBlockingTime) ?? 0
        let completedSessions = SharedDataConstants.userDefaults?.integer(forKey: SharedDataConstants.AppBlocking.todayCompletedSessions) ?? 0
        let totalSessions = SharedDataConstants.userDefaults?.integer(forKey: SharedDataConstants.AppBlocking.todayTotalSessions) ?? 0
        
        return TodayBlockingStats(
            totalBlockingTime: totalBlockingTime,
            completedSessions: completedSessions,
            totalSessions: totalSessions
        )
    }
    
    /// Получить суммарное время блокировок за сегодня (статический метод для расширений)
    static func getTodayTotalBlockingTimeFromSharedData() -> TimeInterval {
        return SharedDataConstants.userDefaults?.double(forKey: SharedDataConstants.AppBlocking.todayTotalBlockingTime) ?? 0
    }
    
    /// Получить количество завершенных сессий за сегодня (статический метод для расширений)
    static func getTodayCompletedSessionsFromSharedData() -> Int {
        return SharedDataConstants.userDefaults?.integer(forKey: SharedDataConstants.AppBlocking.todayCompletedSessions) ?? 0
    }
}

// MARK: - Error Types

enum AppBlockingError: LocalizedError {
    case userNotSet
    case sessionNotFound
    case invalidToken
    
    var errorDescription: String? {
        switch self {
        case .userNotSet:
            return "User not set in Storage"
        case .sessionNotFound:
            return "Blocking session not found"
        case .invalidToken:
            return "Invalid application token"
        }
    }
}

// MARK: - Convenience Extensions

extension AppBlockingLogger {
    
    /// Начать блокировку с данными приложения из MonitoredApp
    func startBlockingSession(
        for monitoredApp: MonitoredApp,
        plannedDuration: TimeInterval
    ) async throws -> AppBlockingSession {
        return try await startBlockingSession(
            applicationToken: monitoredApp.token,
            appDisplayName: monitoredApp.displayName,
            plannedDuration: plannedDuration
        )
    }
    
    /// Получить время форматированное для отображения
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)мин"
        } else {
            return "\(minutes)мин"
        }
    }
    
    /// Получить форматированное время блокировки за сегодня
    func getTodayFormattedBlockingTime() -> String {
        return formatDuration(getTodayTotalBlockingTime())
    }
} 
