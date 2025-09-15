//
//  AppBlockingLogger.swift
//  AntiSocial
//
//  Created by AI Assistant on 12.01.2025.
//

import Foundation
import ManagedSettings

// MARK: - Blocking Types

enum BlockingType: String, Codable {
    case appBlocking      // Focus Time - ручная блокировка пользователем
    case appInterruption  // Автоматическая блокировка при превышении лимита
    case scheduleBlocking // Автоматическая блокировка по расписанию
    case pomodoro         // Фокус сессия Помодоро
}

// MARK: - Data Models

struct BlockingSession: Codable {
    let id: String
    let type: BlockingType
    let startTime: Date
    var endTime: Date?
    let blockedApps: [String] // Application token strings
    var isCompleted: Bool
    var actualDuration: TimeInterval? // в секундах
    
    init(type: BlockingType, blockedApps: [String]) {
        self.id = UUID().uuidString
        self.type = type
        self.startTime = Date()
        self.endTime = nil
        self.blockedApps = blockedApps
        self.isCompleted = false
        self.actualDuration = nil
    }
    
    mutating func complete() {
        self.endTime = Date()
        self.isCompleted = true
        self.actualDuration = endTime?.timeIntervalSince(startTime)
    }
    
    mutating func interrupt() {
        self.endTime = Date()
        self.isCompleted = false
        self.actualDuration = endTime?.timeIntervalSince(startTime)
    }
}

struct DailyStats: Codable {
    let date: Date
    var totalBlockingTime: TimeInterval
    var completedSessions: Int
    var totalSessions: Int
    var appBlockingTime: TimeInterval
    var interruptionTime: TimeInterval
    var scheduleBlockingTime: TimeInterval
    
    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.totalBlockingTime = 0
        self.completedSessions = 0
        self.totalSessions = 0
        self.appBlockingTime = 0
        self.interruptionTime = 0
        self.scheduleBlockingTime = 0
    }
}

// MARK: - AppBlockingLogger

/// Унифицированный сервис для логирования всех типов блокировок приложений
/// Использует SharedData (App Group UserDefaults) для хранения данных, доступных всем расширениям
@MainActor
final class AppBlockingLogger: ObservableObject {
    
    static let shared = AppBlockingLogger()
    
    // Store multiple concurrent sessions
    // AppBlocking and AppInterruption can have only one active session
    // ScheduleBlocking can have multiple active sessions
    @Published private(set) var activeAppBlockingSession: BlockingSession?
    @Published private(set) var activeInterruptionSession: BlockingSession?
    @Published private(set) var activeScheduleSessions: [String: BlockingSession] = [:] // Key is session ID
    @Published private(set) var activePomodoroSession: BlockingSession?
    @Published private(set) var todayStats: DailyStats
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private init() {
        self.todayStats = DailyStats(date: Date())
        loadActiveSessions()
        loadTodayStats()
        
        // Простая проверка: если сегодня еще не было focus time, обнуляем
        checkAndResetIfNoFocusTimeToday()
    }
    
    /// Простая проверка: если сегодня еще не было focus time, обнуляем данные
    private func checkAndResetIfNoFocusTimeToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastFocusDate = SharedData.userDefaults?.object(forKey: "last_focus_date") as? Date
        
        // Если сегодня еще не было focus time, обнуляем данные
        if lastFocusDate == nil || !calendar.isDate(lastFocusDate!, inSameDayAs: today) {
            resetTodayData()
            SharedData.userDefaults?.set(today, forKey: "last_focus_date")
            print("📊 AppBlockingLogger: Reset data - no focus time today yet")
        }
    }
    
    /// Обнуляет данные за сегодня
    private func resetTodayData() {
        // Обнуляем статистику за сегодня
        todayStats = DailyStats(date: Date())
        
        // Обнуляем legacy ключи
        SharedData.userDefaults?.set(0, forKey: SharedData.AppBlocking.todayTotalBlockingTime)
        SharedData.userDefaults?.set(0, forKey: SharedData.AppBlocking.todayCompletedSessions)
        SharedData.userDefaults?.set(0, forKey: SharedData.AppBlocking.todayTotalSessions)
        
        print("📊 AppBlockingLogger: Today's data reset completed")
    }
    
    // MARK: - Session Management
    
    /// Начать сессию блокировки приложений
    private func startSession(type: BlockingType, apps: [ApplicationToken]) -> String {
        // Преобразуем токены в строки для сохранения
        // ApplicationToken не может быть сериализован напрямую, сохраняем как String description
        let appTokenStrings = apps.map { token in
            // Используем description токена как уникальный идентификатор
            String(describing: token)
        }
        
        let session = BlockingSession(type: type, blockedApps: appTokenStrings)
        
        // Сохраняем сессию в зависимости от типа
        switch type {
        case .appBlocking:
            self.activeAppBlockingSession = session
            saveActiveSession(session, key: "active_app_blocking_session")
        case .appInterruption:
            self.activeInterruptionSession = session
            saveActiveSession(session, key: "active_interruption_session")
        case .scheduleBlocking:
            self.activeScheduleSessions[session.id] = session
            saveScheduleSessions()
        case .pomodoro:
            self.activePomodoroSession = session
            saveActiveSession(session, key: "active_pomodoro_session")
        }
        
        // Обновляем статистику
        updateHourlyData()
        
        // Обновляем дату последнего focus time
        SharedData.userDefaults?.set(Date(), forKey: "last_focus_date")
        
        print("AppBlockingLogger: Started \(type.rawValue) session with ID: \(session.id), apps: \(appTokenStrings.count)")
        if !appTokenStrings.isEmpty {
            print("AppBlockingLogger: App tokens: \(appTokenStrings.prefix(3))...") // Показываем первые 3 для отладки
        }
        
        return session.id
    }
    
    /// Начать сессию App Blocking (Focus Time)
    func startAppBlockingSession(apps: [ApplicationToken], duration: TimeInterval) -> String {
        let sessionId = startSession(type: .appBlocking, apps: apps)
        
        // Сохраняем запланированное время окончания
        let unlockDate = Date().addingTimeInterval(duration)
        SharedData.userDefaults?.set(unlockDate, forKey: SharedData.AppBlocking.unlockDate)
        SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
        
        return sessionId
    }
    
    /// Начать сессию App Blocking без конкретных токенов (для категорий)
    func startAppBlockingSessionForCategories(duration: TimeInterval) -> String {
        // Создаем сессию без конкретных токенов приложений
        let session = BlockingSession(type: .appBlocking, blockedApps: ["Categories"])
        
        // Сохраняем сессию
        self.activeAppBlockingSession = session
        saveActiveSession(session, key: "active_app_blocking_session")
        
        // Обновляем статистику
        updateHourlyData()
        
        // Обновляем дату последнего focus time
        SharedData.userDefaults?.set(Date(), forKey: "last_focus_date")
        
        // Сохраняем запланированное время окончания
        let unlockDate = Date().addingTimeInterval(duration)
        SharedData.userDefaults?.set(unlockDate, forKey: SharedData.AppBlocking.unlockDate)
        SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
        
        print("AppBlockingLogger: Started appBlocking session for categories with ID: \(session.id)")
        
        return session.id
    }

    /// Начать сессию Pomodoro (для категорий). Не трогает SharedData.AppBlocking.* ключи, чтобы не загрязнять App Blocking UI
    func startPomodoroSessionForCategories(duration: TimeInterval) -> String {
        let session = BlockingSession(type: .pomodoro, blockedApps: ["Categories"])
        self.activePomodoroSession = session
        saveActiveSession(session, key: "active_pomodoro_session")
        updateHourlyData()
        print("AppBlockingLogger: Started pomodoro session with ID: \(session.id)")
        return session.id
    }
    
    /// Начать сессию App Interruption (превышение лимита)
    func startInterruptionSession(app: ApplicationToken) -> String {
        let sessionId = startSession(type: .appInterruption, apps: [app])
        
        // Interruption всегда на 2 минуты
        let unlockDate = Date().addingTimeInterval(120)
        SharedData.userDefaults?.set(unlockDate, forKey: SharedData.AppBlocking.unlockDate)
        
        return sessionId
    }
    
    /// Начать сессию App Interruption для категорий
    func startInterruptionSessionForCategories() -> String {
        // Создаем сессию без конкретных токенов приложений
        let session = BlockingSession(type: .appInterruption, blockedApps: ["Categories"])
        
        // Сохраняем сессию
        self.activeInterruptionSession = session
        saveActiveSession(session, key: "active_interruption_session")
        
        // Обновляем статистику
        updateHourlyData()
        
        // Interruption всегда на 2 минуты
        let unlockDate = Date().addingTimeInterval(120)
        SharedData.userDefaults?.set(unlockDate, forKey: SharedData.AppBlocking.unlockDate)
        
        print("AppBlockingLogger: Started appInterruption session for categories with ID: \(session.id)")
        
        return session.id
    }
    
    /// Начать сессию Schedule Blocking (по расписанию)
    func startScheduleSession(apps: [ApplicationToken], scheduleName: String) -> String {
        let sessionId = startSession(type: .scheduleBlocking, apps: apps)
        
        // Для schedule блокировок время окончания определяется расписанием
        // Сохраняем имя расписания для отладки
        SharedData.userDefaults?.set(scheduleName, forKey: "current_schedule_name")
        
        return sessionId
    }
    
    /// Начать сессию Schedule Blocking для категорий
    func startScheduleSessionForCategories(scheduleName: String) -> String {
        // Создаем сессию без конкретных токенов приложений
        let session = BlockingSession(type: .scheduleBlocking, blockedApps: ["Categories"])
        
        // Сохраняем сессию (может быть несколько одновременно)
        self.activeScheduleSessions[session.id] = session
        saveScheduleSessions()
        
        // Обновляем статистику
        updateHourlyData()
        
        // Сохраняем имя расписания для отладки
        SharedData.userDefaults?.set(scheduleName, forKey: "current_schedule_name")
        
        print("AppBlockingLogger: Started scheduleBlocking session for categories with ID: \(session.id), schedule: \(scheduleName)")
        
        return session.id
    }
    
    /// Завершить сессию блокировки по ID
    func endSession(sessionId: String, completed: Bool) {
        // Find session by ID
        var foundSession: BlockingSession? = nil
        var foundType: BlockingType? = nil
        
        // Check app blocking session
        if activeAppBlockingSession?.id == sessionId {
            foundSession = activeAppBlockingSession
            foundType = .appBlocking
        }
        // Check interruption session
        else if activeInterruptionSession?.id == sessionId {
            foundSession = activeInterruptionSession
            foundType = .appInterruption
        }
        // Check schedule sessions
        else if let scheduleSession = activeScheduleSessions[sessionId] {
            foundSession = scheduleSession
            foundType = .scheduleBlocking
        }
        else if activePomodoroSession?.id == sessionId {
            foundSession = activePomodoroSession
            foundType = .pomodoro
        }
        
        guard var session = foundSession, let type = foundType else {
            print("AppBlockingLogger: No active session with ID: \(sessionId)")
            return
        }
        
        if completed {
            session.complete()
        } else {
            session.interrupt()
        }
        
        let duration = session.actualDuration ?? 0
        print("AppBlockingLogger: Ending \(type.rawValue) session \(sessionId)")
        print("  - Completed: \(completed)")
        print("  - Duration: \(duration) seconds (\(duration/60) minutes)")
        print("  - Blocked apps: \(session.blockedApps)")
        
        // Сохраняем завершенную сессию
        saveCompletedSession(session)
        
        // Обновляем статистику
        updateDailyStats(with: session)
        updateHourlyData()
        
        // Удаляем сессию из активных
        switch type {
        case .appBlocking:
            self.activeAppBlockingSession = nil
            SharedData.userDefaults?.removeObject(forKey: "active_app_blocking_session")
            SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.unlockDate)
            SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
        case .appInterruption:
            self.activeInterruptionSession = nil
            SharedData.userDefaults?.removeObject(forKey: "active_interruption_session")
        case .scheduleBlocking:
            self.activeScheduleSessions.removeValue(forKey: sessionId)
            saveScheduleSessions()
        case .pomodoro:
            self.activePomodoroSession = nil
            SharedData.userDefaults?.removeObject(forKey: "active_pomodoro_session")
        }
    }
    
    /// Завершить сессию блокировки по типу (для AppBlocking и AppInterruption)
    func endSession(type: BlockingType, completed: Bool) {
        let session: BlockingSession?
        
        switch type {
        case .appBlocking:
            session = activeAppBlockingSession
        case .appInterruption:
            session = activeInterruptionSession
        case .scheduleBlocking:
            print("AppBlockingLogger: Cannot end schedule session by type - use sessionId")
            return
        case .pomodoro:
            session = activePomodoroSession
        }
        
        guard let activeSession = session else {
            print("AppBlockingLogger: No active session of type: \(type.rawValue)")
            return
        }
        
        endSession(sessionId: activeSession.id, completed: completed)
    }
    
    // MARK: - Data Access
    
    /// Получить активную сессию по типу
    func getCurrentSession(type: BlockingType) -> BlockingSession? {
        switch type {
        case .appBlocking:
            return activeAppBlockingSession
        case .appInterruption:
            return activeInterruptionSession
        case .scheduleBlocking:
            // Return first schedule session if any
            return activeScheduleSessions.values.first
        case .pomodoro:
            return activePomodoroSession
        }
    }
    
    /// Получить все активные schedule сессии
    func getActiveScheduleSessions() -> [BlockingSession] {
        return Array(activeScheduleSessions.values)
    }
    
    /// Получить все активные сессии
    func getAllActiveSessions() -> [BlockingSession] {
        var sessions: [BlockingSession] = []
        if let appSession = activeAppBlockingSession {
            sessions.append(appSession)
        }
        if let interruptionSession = activeInterruptionSession {
            sessions.append(interruptionSession)
        }
        if let pomodoroSession = activePomodoroSession {
            sessions.append(pomodoroSession)
        }
        sessions.append(contentsOf: activeScheduleSessions.values)
        return sessions
    }
    
    /// Получить почасовую статистику за указанную дату
    func getHourlyStats(for date: Date) -> [Int] {
        let dateKey = dateFormatter.string(from: date)
        let key = "hourly_stats_\(dateKey)"
        
        if let data = SharedData.userDefaults?.data(forKey: key),
           let stats = try? JSONDecoder().decode([Int].self, from: data) {
            return stats
        }
        
        return Array(repeating: 0, count: 24)
    }
    
    /// Получить дневную статистику за указанную дату
    func getDailyStats(for date: Date) -> DailyStats {
        let dateKey = dateFormatter.string(from: date)
        let key = "daily_stats_\(dateKey)"
        
        if let data = SharedData.userDefaults?.data(forKey: key),
           let stats = try? JSONDecoder().decode(DailyStats.self, from: data) {
            return stats
        }
        
        return DailyStats(date: date)
    }
    
    /// Получить все сессии блокировки за указанную дату
    func getBlockingSessions(for date: Date) -> [BlockingSession] {
        let dateKey = dateFormatter.string(from: date)
        let key = "blocking_sessions_\(dateKey)"
        
        if let data = SharedData.userDefaults?.data(forKey: key),
           let sessions = try? JSONDecoder().decode([BlockingSession].self, from: data) {
            return sessions
        }
        
        return []
    }
    
    // MARK: - Private Methods
    
    private func loadActiveSessions() {
        // Load app blocking session
        if let data = SharedData.userDefaults?.data(forKey: "active_app_blocking_session"),
           let session = try? JSONDecoder().decode(BlockingSession.self, from: data) {
            self.activeAppBlockingSession = session
        }
        
        // Load interruption session
        if let data = SharedData.userDefaults?.data(forKey: "active_interruption_session"),
           let session = try? JSONDecoder().decode(BlockingSession.self, from: data) {
            self.activeInterruptionSession = session
        }
        
        // Load schedule sessions
        if let data = SharedData.userDefaults?.data(forKey: "active_schedule_sessions"),
           let sessions = try? JSONDecoder().decode([String: BlockingSession].self, from: data) {
            self.activeScheduleSessions = sessions
        }
        
        // Load pomodoro session
        if let data = SharedData.userDefaults?.data(forKey: "active_pomodoro_session"),
           let session = try? JSONDecoder().decode(BlockingSession.self, from: data) {
            self.activePomodoroSession = session
        }
    }
    
    private func loadTodayStats() {
        self.todayStats = getDailyStats(for: Date())
    }
    
    private func saveActiveSession(_ session: BlockingSession, key: String) {
        if let data = try? JSONEncoder().encode(session) {
            SharedData.userDefaults?.set(data, forKey: key)
        }
    }
    
    private func saveScheduleSessions() {
        if let data = try? JSONEncoder().encode(activeScheduleSessions) {
            SharedData.userDefaults?.set(data, forKey: "active_schedule_sessions")
        }
    }
    
    private func saveCompletedSession(_ session: BlockingSession) {
        let dateKey = dateFormatter.string(from: session.startTime)
        let key = "blocking_sessions_\(dateKey)"
        
        // Загружаем существующие сессии
        var sessions = getBlockingSessions(for: session.startTime)
        sessions.append(session)
        
        // Сохраняем обновленный список
        if let data = try? JSONEncoder().encode(sessions) {
            SharedData.userDefaults?.set(data, forKey: key)
            
            print("AppBlockingLogger: Saved session to key '\(key)'. Total sessions: \(sessions.count)")
        }
    }
    
    private func updateDailyStats(with session: BlockingSession) {
        let dateKey = dateFormatter.string(from: session.startTime)
        let key = "daily_stats_\(dateKey)"
        
        var stats = getDailyStats(for: session.startTime)
        
        // Обновляем общую статистику
        stats.totalSessions += 1
        if session.isCompleted {
            stats.completedSessions += 1
        }
        
        let duration = session.actualDuration ?? 0
        stats.totalBlockingTime += duration
        
        // Обновляем статистику по типам
        switch session.type {
        case .appBlocking:
            stats.appBlockingTime += duration
        case .appInterruption:
            stats.interruptionTime += duration
        case .scheduleBlocking:
            stats.scheduleBlockingTime += duration
        case .pomodoro:
            // Учитываем помодоро как фокус-время (appBlockingTime)
            stats.appBlockingTime += duration
        }
        
        // Сохраняем обновленную статистику
        if let data = try? JSONEncoder().encode(stats) {
            SharedData.userDefaults?.set(data, forKey: key)
        }
        
        // Обновляем статистику для сегодня
        if calendar.isDateInToday(session.startTime) {
            self.todayStats = stats
            
            // Обновляем legacy ключи для обратной совместимости
            SharedData.userDefaults?.set(stats.totalBlockingTime, forKey: SharedData.AppBlocking.todayTotalBlockingTime)
            SharedData.userDefaults?.set(stats.completedSessions, forKey: SharedData.AppBlocking.todayCompletedSessions)
            SharedData.userDefaults?.set(stats.totalSessions, forKey: SharedData.AppBlocking.todayTotalSessions)
        }
        
        // Обновляем lifetime статистику
        updateLifetimeStats(addingDuration: duration)
    }
    
    private func updateLifetimeStats(addingDuration: TimeInterval) {
        // Получаем текущее lifetime время
        let currentLifetime = SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.lifetimeTotalBlockingTime) ?? 0
        let newLifetime = currentLifetime + addingDuration
        
        // Сохраняем обновленное значение
        SharedData.userDefaults?.set(newLifetime, forKey: SharedData.AppBlocking.lifetimeTotalBlockingTime)
        
        print("AppBlockingLogger: Updated lifetime stats from \(currentLifetime)s to \(newLifetime)s (added \(addingDuration)s)")
    }
    
    private func updateHourlyData() {
        let today = Date()
        let dateKey = dateFormatter.string(from: today)
        let key = "hourly_stats_\(dateKey)"
        
        // Создаем массив для 24 часов (в минутах)
        var hourlyStats = Array(repeating: 0, count: 24)
        
        // Обрабатываем все сессии за сегодня
        let sessions = getBlockingSessions(for: today)
        
        for session in sessions {
            guard let endTime = session.endTime else { continue }
            
            let startHour = calendar.component(.hour, from: session.startTime)
            let endHour = calendar.component(.hour, from: endTime)
            
            // Распределяем время по часам
            if startHour == endHour {
                // Сессия в пределах одного часа
                let minutes = Int(endTime.timeIntervalSince(session.startTime) / 60)
                hourlyStats[startHour] += minutes
            } else if startHour <= endHour {
                // Сессия охватывает несколько часов
                for hour in startHour...endHour {
                    if hour < 24 {
                        var minutesInHour = 60
                        
                        if hour == startHour {
                            // Первый час - считаем от начала сессии до конца часа
                            let startMinute = calendar.component(.minute, from: session.startTime)
                            minutesInHour = 60 - startMinute
                        } else if hour == endHour {
                            // Последний час - считаем от начала часа до конца сессии
                            let endMinute = calendar.component(.minute, from: endTime)
                            minutesInHour = endMinute
                        }
                        
                        hourlyStats[hour] += minutesInHour
                    }
                }
            }
        }
        
        // Добавляем все текущие активные сессии
        let allActiveSessions = getAllActiveSessions()
        for currentSession in allActiveSessions {
            let startHour = calendar.component(.hour, from: currentSession.startTime)
            let currentHour = calendar.component(.hour, from: Date())
            
            if startHour == currentHour {
                // Сессия в пределах текущего часа
                let minutes = Int(Date().timeIntervalSince(currentSession.startTime) / 60)
                hourlyStats[currentHour] += minutes
            } else if startHour <= currentHour {
                // Сессия охватывает несколько часов
                for hour in startHour...currentHour {
                    if hour < 24 {
                        var minutesInHour = 60
                        
                        if hour == startHour {
                            let startMinute = calendar.component(.minute, from: currentSession.startTime)
                            minutesInHour = 60 - startMinute
                        } else if hour == currentHour {
                            let currentMinute = calendar.component(.minute, from: Date())
                            minutesInHour = currentMinute
                        }
                        
                        hourlyStats[hour] += minutesInHour
                    }
                }
            }
        }
        
        // Сохраняем почасовую статистику
        if let data = try? JSONEncoder().encode(hourlyStats) {
            SharedData.userDefaults?.set(data, forKey: key)
            
            // Также сохраняем в legacy формате для обратной совместимости
            SharedData.userDefaults?.set(data, forKey: "hourlyBlockingData_\(dateKey)")
            
            let totalMinutes = hourlyStats.reduce(0, +)
            print("AppBlockingLogger: Updated hourly stats for '\(dateKey)'. Total minutes: \(totalMinutes)")
        }
    }
    
    // MARK: - Static Helper Methods
    
    /// Получить общее время блокировки за сегодня (для расширений)
    static func getTodayTotalBlockingTime() -> TimeInterval {
        return SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.todayTotalBlockingTime) ?? 0
    }
    
    /// Получить количество завершенных сессий за сегодня (для расширений)
    static func getTodayCompletedSessions() -> Int {
        return SharedData.userDefaults?.integer(forKey: SharedData.AppBlocking.todayCompletedSessions) ?? 0
    }
    
    /// Получить почасовую статистику за сегодня (для расширений)
    static func getTodayHourlyStats() -> [Int] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: Date())
        let key = "hourly_stats_\(dateKey)"
        
        if let data = SharedData.userDefaults?.data(forKey: key),
           let stats = try? JSONDecoder().decode([Int].self, from: data) {
            return stats
        }
        
        return Array(repeating: 0, count: 24)
    }
    
    /// Форматировать длительность для отображения
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)мин"
        } else {
            return "\(minutes)мин"
        }
    }
}

// MARK: - Convenience Extensions

extension AppBlockingLogger {
    
    /// Проверить, есть ли активная сессия блокировки
    var hasActiveSession: Bool {
        return activeAppBlockingSession != nil || 
               activeInterruptionSession != nil || 
               activePomodoroSession != nil ||
               !activeScheduleSessions.isEmpty
    }
    
    /// Проверить, есть ли активная сессия определенного типа
    func hasActiveSession(type: BlockingType) -> Bool {
        switch type {
        case .appBlocking:
            return activeAppBlockingSession != nil
        case .appInterruption:
            return activeInterruptionSession != nil
        case .scheduleBlocking:
            return !activeScheduleSessions.isEmpty
        case .pomodoro:
            return activePomodoroSession != nil
        }
    }
    
    /// Получить время до окончания текущей сессии
    var timeUntilUnlock: TimeInterval? {
        guard let unlockDate = SharedData.userDefaults?.object(forKey: SharedData.AppBlocking.unlockDate) as? Date else {
            return nil
        }
        return unlockDate.timeIntervalSinceNow
    }
    
    /// Получить процент завершенных сессий за сегодня
    var todayCompletionRate: Double {
        guard todayStats.totalSessions > 0 else { return 0 }
        return Double(todayStats.completedSessions) / Double(todayStats.totalSessions) * 100
    }
    
    /// Обновить все данные (для обратной совместимости)
    func refreshAllData() async {
        // В новой версии данные обновляются автоматически из SharedData
        // Этот метод оставлен для обратной совместимости
        await MainActor.run {
            loadActiveSessions()
            loadTodayStats()
            updateHourlyData()
        }
    }
}
