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
    @Published private(set) var allTimeStats: [DailyAppBlockingStats] = []
    
    private init() {
        // Загружаем статистику при инициализации
        Task {
            await loadActiveSessions()
            await loadTodayStats()
            await loadAllTimeStats()
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
        await loadAllTimeStats()
        
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
        await loadAllTimeStats()
        
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
            updateSharedStats()
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
        
        SharedData.userDefaults?.set(totalTime, forKey: SharedData.AppBlocking.todayTotalBlockingTime)
        SharedData.userDefaults?.set(completedCount, forKey: SharedData.AppBlocking.todayCompletedSessions)
        SharedData.userDefaults?.set(totalCount, forKey: SharedData.AppBlocking.todayTotalSessions)
        
        // Сохраняем часовые данные
        Task {
            await saveHourlyBlockingDataToSharedData()
        }
        
        SharedData.userDefaults?.synchronize() // Форсируем синхронизацию
        
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        let remainingMinutes = Int(totalTime.truncatingRemainder(dividingBy: 3600) / 60)
        AppLogger.notice("Updated shared blocking stats: \(hours)h \(remainingMinutes)m (\(totalTime)s total), \(completedCount)/\(totalCount) sessions")
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
        await loadAllTimeStats()
    }
    
    /// Загрузить всю статистику
    func loadAllTimeStats() async {
        do {
            guard let currentUser = Storage.shared.user else { return }
            
            let stats = try await Storage.shared.getAllBlockingStats(for: currentUser.id)
            self.allTimeStats = stats
            
            // Обновляем lifetime статистику в SharedData
            await updateLifetimeStats()
        } catch {
            AppLogger.critical(error, details: "Failed to load all-time blocking stats")
        }
    }
    
    /// Получить общее время блокировки за все время
    func getAllTimeTotalBlockingTime() -> TimeInterval {
        // Суммируем время из всех DailyAppBlockingStats
        let totalFromStats = allTimeStats.reduce(0) { $0 + $1.totalBlockedDuration }
        
        // Добавляем время из активных сессий
        let activeTime = activeSessions.reduce(0) { total, session in
            if session.endDate == nil {
                // Активная сессия - считаем текущее время
                return total + Date().timeIntervalSince(session.startDate)
            }
            return total
        }
        
        return totalFromStats + activeTime
    }
    
    /// Обновить lifetime статистику
    private func updateLifetimeStats() async {
        let totalTime = getAllTimeTotalBlockingTime()
        
        SharedData.userDefaults?.set(totalTime, forKey: SharedData.AppBlocking.lifetimeTotalBlockingTime)
        SharedData.userDefaults?.synchronize() // Форсируем синхронизацию
        
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        AppLogger.notice("Updated lifetime blocking time: \(hours)h \(minutes)m")
    }
    
    // MARK: - Static Methods for Extensions
    
    /// Получить статистику блокировок за сегодня из SharedData (для использования в расширениях)
    static func getTodayBlockingStatsFromSharedData() -> TodayBlockingStats {
        let totalBlockingTime = SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.todayTotalBlockingTime) ?? 0
        let completedSessions = SharedData.userDefaults?.integer(forKey: SharedData.AppBlocking.todayCompletedSessions) ?? 0
        let totalSessions = SharedData.userDefaults?.integer(forKey: SharedData.AppBlocking.todayTotalSessions) ?? 0
        
        return TodayBlockingStats(
            totalBlockingTime: totalBlockingTime,
            completedSessions: completedSessions,
            totalSessions: totalSessions
        )
    }
    
    /// Получить суммарное время блокировок за сегодня (статический метод для расширений)
    static func getTodayTotalBlockingTimeFromSharedData() -> TimeInterval {
        return SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.todayTotalBlockingTime) ?? 0
    }
    
    /// Получить количество завершенных сессий за сегодня (статический метод для расширений)
    static func getTodayCompletedSessionsFromSharedData() -> Int {
        return SharedData.userDefaults?.integer(forKey: SharedData.AppBlocking.todayCompletedSessions) ?? 0
    }
    
    /// Получить суммарное время блокировок за все время (статический метод для расширений)
    static func getLifetimeTotalBlockingTimeFromSharedData() -> TimeInterval {
        return SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.lifetimeTotalBlockingTime) ?? 0
    }
    
    /// Получить часовые данные блокировок за сегодня и сохранить в SharedData
    func saveHourlyBlockingDataToSharedData() async {
        // Создаем массив для 24 часов
        var hourlyData = Array(repeating: 0.0, count: 24)
        let calendar = Calendar.current
        
        // Обрабатываем завершенные сессии из todayStats
        for stat in todayStats {
            // Каждая статистика может содержать несколько сессий
            // Распределяем общее время равномерно по дню (упрощенный подход)
            let hoursBlocked = stat.totalBlockedDuration / 3600.0
            let startHour = 0 // Можно улучшить, если хранить время начала в статистике
            let endHour = min(23, Int(hoursBlocked))
            
            if startHour <= endHour {
                for hour in startHour...endHour {
                    if hour < 24 {
                        hourlyData[hour] += min(3600, stat.totalBlockedDuration - Double(hour * 3600))
                    }
                }
            }
        }
        
        // Обрабатываем активные сессии
        for session in activeSessions {
            if session.endDate == nil {
                // Активная сессия
                let startHour = calendar.component(.hour, from: session.startDate)
                let currentHour = calendar.component(.hour, from: Date())
                let duration = Date().timeIntervalSince(session.startDate)
                
                // Распределяем время по часам
                // Проверяем, если сессия началась вчера
                if startHour > currentHour {
                    // Сессия началась вчера, обрабатываем только сегодняшние часы
                    for hour in 0...currentHour {
                        if hour < 24 {
                            let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
                            let hourEnd = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: Date()) ?? Date()
                            
                            let sessionEnd = min(Date(), hourEnd)
                            
                            if sessionEnd > hourStart {
                                hourlyData[hour] += sessionEnd.timeIntervalSince(hourStart)
                            }
                        }
                    }
                } else {
                    // Обычный случай - сессия началась сегодня
                    for hour in startHour...currentHour {
                        if hour < 24 {
                            let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: session.startDate) ?? session.startDate
                            let hourEnd = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: session.startDate) ?? Date()
                            
                            let sessionStart = max(session.startDate, hourStart)
                            let sessionEnd = min(Date(), hourEnd)
                            
                            if sessionEnd > sessionStart {
                                hourlyData[hour] += sessionEnd.timeIntervalSince(sessionStart)
                            }
                        }
                    }
                }
            }
        }
        
        // Сохраняем в SharedData
        if let jsonData = try? JSONEncoder().encode(hourlyData) {
            SharedData.userDefaults?.set(jsonData, forKey: SharedData.AppBlocking.hourlyBlockingData)
            SharedData.userDefaults?.synchronize()
        }
    }
    
    /// Получить часовые данные блокировок из SharedData (для расширений)
    static func getHourlyBlockingDataFromSharedData() -> [Double] {
        guard let jsonData = SharedData.userDefaults?.data(forKey: SharedData.AppBlocking.hourlyBlockingData),
              let hourlyData = try? JSONDecoder().decode([Double].self, from: jsonData) else {
            return Array(repeating: 0.0, count: 24)
        }
        return hourlyData
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
