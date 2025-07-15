//
//  SharedDataConstants.swift
//  AntiSocial
//
//  Created by AI Assistant on 12.01.2025.
//

import Foundation

/// Константы для работы с SharedData между основным приложением и расширениями
///
/// ВАЖНО: При изменении ключей обновить соответствующие строки в:
/// - AntiSocial/Utilities/Services/Logger/AppBlockingLogger.swift
/// - AntiSocial/Utilities/Services/DeviceActivity/BlockingNotificationService.swift
/// - DeviceReportExtension/ScreenTime/ScreenTimeSectionView.swift
///
/// В будущем планируется полная миграция на использование этих констант
public enum SharedDataConstants {
  
  // MARK: - App Group
  
  /// Идентификатор App Group для обмена данными между основным приложением и расширениями
  static let appGroupSuiteName = "group.com.app.antisocial.sharedData"
  
  // MARK: - App Blocking Keys
  
  /// Ключи для статистики блокировок приложений
  enum AppBlocking {
    /// Общее время блокировок за сегодня (TimeInterval)
    static let todayTotalBlockingTime = "todayTotalBlockingTime"
    
    /// Количество завершенных сессий за сегодня (Int)
    static let todayCompletedSessions = "todayCompletedSessions"
    
    /// Общее количество сессий за сегодня (Int)
    static let todayTotalSessions = "todayTotalSessions"
  }
  
  // MARK: - Widget Keys
  
  /// Ключи для данных виджетов
  enum Widget {
    /// Режим ограничения активен (Bool)
    static let isBlocked = "isBlocked"
    
    static let isStricted = "isStricted"
    
    /// Час окончания ограничения (Int)
    static let endHour = "widgetEndHour"
    
    /// Минуты окончания ограничения (Int)
    static let endMinutes = "widgetEndMins"
  }
  
  // MARK: - Legacy Keys (for compatibility)
  
  /// Устаревшие ключи для совместимости
  enum Legacy {
    /// Время начала ограничения (Double - timestamp)
    static let restrictionStartTime = "restrictionStartTime"
  }
  
  // MARK: - Helper Methods
  
  /// Получить UserDefaults для App Group
  static var userDefaults: UserDefaults? {
    return UserDefaults(suiteName: appGroupSuiteName)
  }
}
