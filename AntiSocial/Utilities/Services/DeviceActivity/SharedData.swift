//
//  SharedData.swift
//  ScreenTimeTestApp
//
//  Created by D C on 12.02.2025.
//

import Foundation
import FamilyControls

/// Unified service for managing shared data between the main app and extensions
/// Combines functionality from SharedData and SharedData
public class SharedData {
  
  // MARK: - App Group
  
  /// App group identifier for data sharing between main app and extensions
  public static let appGroupSuiteName = "group.com.app.antisocial.sharedData"
  
  /// Shared UserDefaults instance
  public static let userDefaults: UserDefaults? = UserDefaults(suiteName: appGroupSuiteName)
  
  // MARK: - Keys
  
  /// Family activity selection keys
  public enum Keys {
    static let disabledApps = "DisabledApps"
    static let allSelectedApps = "AllSelectedApps"
    
    static let selectedFamilyActivity = "FamilyActivitySelection"
    static let tokenToDisplayName = "AppTokenDisplayNames"
        
    static let selectedAlertActivity = "SelectedAlertActivity"
    static let selectedInterruptionsActivity = "SelectedInterruptionsActivity"
    static let selectedBlockingActivity = "SelectedBlockingActivity"
    
    static let appDeviceActivityList = "AppDeviceActivityList"
  }
  
  /// App blocking statistics keys
  public enum AppBlocking {
    /// Total blocking time today (TimeInterval)
    public static let todayTotalBlockingTime = "todayTotalBlockingTime"
    
    /// Completed sessions today (Int)
    public static let todayCompletedSessions = "todayCompletedSessions"
    
    /// Total sessions today (Int)
    public static let todayTotalSessions = "todayTotalSessions"
    
    public static let currentBlockingStartTimestamp = "currentBlockingStartTimestamp"
    
    /// Unlock date (Date)
    public static let unlockDate = "UnlockDate"
    
    /// Last interruption block time (TimeInterval)
    public static let lastInterruptionBlockTime = "lastInterruptionBlockTime"
    
    /// Saved duration hours (Int)
    public static let savedDurationHours = "savedDurationHours"
    
    /// Saved duration minutes (Int)
    public static let savedDurationMinutes = "savedDurationMinutes"
    
    /// Lifetime total blocking time in seconds (Double)
    public static let lifetimeTotalBlockingTime = "lifetimeTotalBlockingTime"
    
    /// Hourly blocking data for chart (Data - JSON encoded [Double])
    public static let hourlyBlockingData = "hourlyBlockingData"
  }
  
  /// Widget data keys
  public enum Widget {
    /// Restriction mode active (Bool)
    public static let isBlocked = "isBlocked"
    
    public static let isStricted = "isStricted"
    
    /// End hour (Int)
    public static let endHour = "widgetEndHour"
    
    /// End minutes (Int)
    public static let endMinutes = "widgetEndMins"
  }
  
  /// Screen Time settings keys
  public enum ScreenTime {
    /// Selected interruption time (Int - minutes)
    public static let selectedInterruptionTime = "selectedInterruptionTime"
    
    /// Selected alert time (Int - minutes)
    public static let selectedTime = "selectedTime"
    
    /// Interruptions enabled (Bool)
    public static let isInterruptionsEnabled = "isInterruptionsEnabled"
    
    /// Alerts enabled (Bool)
    public static let isAlertEnabled = "isAlertEnabled"
    
    /// Interruption block flag (Bool)
    public static let isInterruptionBlock = "isInterruptionBlock"
    
    /// Cached screen time data (Data)
    public static let cachedScreenTimeData = "cachedScreenTimeData"
    
    /// Has loaded once flag (Bool)
    public static let screenTimeHasLoadedOnce = "screenTimeHasLoadedOnce"
    
    /// Last refresh timestamp (Double)
    public static let lastScreenTimeRefresh = "lastScreenTimeRefresh"
    
    /// App usage time tracking (Dictionary - [String: Double])
    public static let appUsageTimeToday = "appUsageTimeToday"
    
    /// Last alert time for each app (Dictionary - [String: Double])
    public static let appLastAlertTime = "appLastAlertTime"
    
    /// App usage session start times (Dictionary - [String: Double])
    public static let appSessionStartTimes = "appSessionStartTimes"
  }
  
  // MARK: - App Usage Time Methods
  
  /// Get today's usage time for an app
  public static func getAppUsageTime(for appName: String) -> TimeInterval {
    let dict = userDefaults?.dictionary(forKey: ScreenTime.appUsageTimeToday) as? [String: Double] ?? [:]
    return dict[appName] ?? 0
  }
  
  /// Update usage time for an app
  public static func updateAppUsageTime(for appName: String, additionalTime: TimeInterval) {
    var dict = userDefaults?.dictionary(forKey: ScreenTime.appUsageTimeToday) as? [String: Double] ?? [:]
    dict[appName] = (dict[appName] ?? 0) + additionalTime
    userDefaults?.set(dict, forKey: ScreenTime.appUsageTimeToday)
  }
  
  /// Reset all app usage times (for daily reset)
  public static func resetAppUsageTimes() {
    userDefaults?.removeObject(forKey: ScreenTime.appUsageTimeToday)
    userDefaults?.removeObject(forKey: ScreenTime.appLastAlertTime)
    userDefaults?.removeObject(forKey: ScreenTime.appSessionStartTimes)
  }
  
  /// Get last alert time for an app
  public static func getLastAlertTime(for appName: String) -> Date? {
    let dict = userDefaults?.dictionary(forKey: ScreenTime.appLastAlertTime) as? [String: Double] ?? [:]
    guard let timestamp = dict[appName] else { return nil }
    return Date(timeIntervalSince1970: timestamp)
  }
  
  /// Set last alert time for an app
  public static func setLastAlertTime(for appName: String, date: Date) {
    var dict = userDefaults?.dictionary(forKey: ScreenTime.appLastAlertTime) as? [String: Double] ?? [:]
    dict[appName] = date.timeIntervalSince1970
    userDefaults?.set(dict, forKey: ScreenTime.appLastAlertTime)
  }
  
  // MARK: - Bridge Methods for Extensions
  
  /// Get hourly blocking data from SharedData for a specific date
  public static func getHourlyBlockingData(for date: Date) -> [Double] {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let dateKey = formatter.string(from: date)
    
    // Получаем данные для конкретной даты
    if let jsonData = userDefaults?.data(forKey: "hourlyBlockingData_\(dateKey)"),
       let hourlyData = try? JSONDecoder().decode([Double].self, from: jsonData) {
      return hourlyData
    }
    
    return Array(repeating: 0.0, count: 24)
  }
  
  /// Get hourly blocking data from SharedData (for extensions) - для сегодняшнего дня
  public static func getHourlyBlockingData() -> [Double] {
    return getHourlyBlockingData(for: Date())
  }
  
  /// Новая структура сессии блокировки (из AppBlockingLogger)
  public struct BlockingSession: Codable {
    public let id: String
    public let type: String // BlockingType as string
    public let startTime: Date
    public var endTime: Date?
    public let blockedApps: [String]
    public var isCompleted: Bool
    public var actualDuration: TimeInterval?
  }
  
  /// Структура для хранения данных о сессиях блокировки (legacy)
  public struct BlockingSessionInfo: Codable {
    public let startTime: Date
    public let endTime: Date?
    public let appName: String
  }
  
  /// Get blocking sessions for a specific date (legacy format)
  public static func getBlockingSessions(for date: Date) -> [BlockingSessionInfo] {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let dateKey = formatter.string(from: date)
    
    // Try to get new format first (from AppBlockingLogger)
    if let sessionData = userDefaults?.data(forKey: "blocking_sessions_\(dateKey)") {
      // Convert new BlockingSession format to BlockingSessionInfo
      if let sessions = try? JSONDecoder().decode([BlockingSession].self, from: sessionData) {
        return sessions.map { session in
          BlockingSessionInfo(
            startTime: session.startTime,
            endTime: session.endTime,
            appName: "Focus Time" // Generic name since we don't store app names in new format
          )
        }
      }
    }
    
    // Fallback to legacy format
    if let sessionData = userDefaults?.data(forKey: "blockingSessions_\(dateKey)"),
       let sessions = try? JSONDecoder().decode([BlockingSessionInfo].self, from: sessionData) {
      return sessions
    }
    
    return []
  }
  
  /// Get today's total blocking time from SharedData (for extensions)
  public static func getTodayTotalBlockingTime() -> TimeInterval {
    return userDefaults?.double(forKey: AppBlocking.todayTotalBlockingTime) ?? 0
  }
  
  /// Get lifetime total blocking time from SharedData (for extensions)
  public static func getLifetimeTotalBlockingTime() -> TimeInterval {
    return userDefaults?.double(forKey: AppBlocking.lifetimeTotalBlockingTime) ?? 0
  }
  
  /// Get today's blocking statistics from SharedData (for extensions)
  public static func getTodayBlockingStats() -> (totalTime: TimeInterval, completedSessions: Int, totalSessions: Int) {
    let totalTime = userDefaults?.double(forKey: AppBlocking.todayTotalBlockingTime) ?? 0
    let completed = userDefaults?.integer(forKey: AppBlocking.todayCompletedSessions) ?? 0
    let total = userDefaults?.integer(forKey: AppBlocking.todayTotalSessions) ?? 0
    return (totalTime, completed, total)
  }
    
  static var selectedFamilyActivity: FamilyActivitySelection? {
    get {
      guard let data = userDefaults?.data(forKey: Keys.selectedFamilyActivity) else { return nil }
      
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } set {
      userDefaults?.set(try? JSONEncoder().encode(newValue), forKey: Keys.selectedFamilyActivity)
    }
  }
  
  static var disabledFamilyActivity: FamilyActivitySelection? {
    get {
      guard let data = userDefaults?.data(forKey: Keys.disabledApps) else { return nil }
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } set {
      userDefaults?.set(try? JSONEncoder().encode(newValue), forKey: Keys.disabledApps)
    }
  }
  
  static var allSelectedFamilyActivity: FamilyActivitySelection? {
    get {
      guard let data = userDefaults?.data(forKey: Keys.allSelectedApps) else { return nil }
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } set {
      userDefaults?.set(try? JSONEncoder().encode(newValue), forKey: Keys.allSelectedApps)
    }
  }
  
  static var tokenDisplayNameMap: [String: String] {
    get {
      userDefaults?.dictionary(forKey: Keys.tokenToDisplayName) as? [String: String] ?? [:]
    }
    set {
      userDefaults?.set(newValue, forKey: Keys.tokenToDisplayName)
    }
  }
  
  static func appName(for token: String) -> String {
    tokenDisplayNameMap[token] ?? "Приложение"
  }

  static var selectedAlertActivity: FamilyActivitySelection? {
    get {
      guard let data = userDefaults?.data(forKey: Keys.selectedAlertActivity) else { return nil }
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    set {
      userDefaults?.set(try? JSONEncoder().encode(newValue), forKey: Keys.selectedAlertActivity)
    }
  }

  static var selectedInterruptionsActivity: FamilyActivitySelection? {
    get {
      guard let data = userDefaults?.data(forKey: Keys.selectedInterruptionsActivity) else { return nil }
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    set {
      userDefaults?.set(try? JSONEncoder().encode(newValue), forKey: Keys.selectedInterruptionsActivity)
    }
  }

  static var selectedBlockingActivity: FamilyActivitySelection? {
    get {
      guard let data = userDefaults?.data(forKey: Keys.selectedBlockingActivity) else { return nil }
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    set {
      userDefaults?.set(try? JSONEncoder().encode(newValue), forKey: Keys.selectedBlockingActivity)
    }
  }
}

