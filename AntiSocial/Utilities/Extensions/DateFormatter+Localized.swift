//
//  DateFormatter+Localized.swift
//  AntiSocial
//
//  Created by Dev on 19.01.2025.
//

import Foundation

extension DateFormatter {
  
  /// Creates a localized time formatter that respects the user's locale settings
  /// - Returns: DateFormatter configured for localized time display
  static func localizedTimeFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    formatter.locale = Locale.autoupdatingCurrent
    formatter.timeZone = TimeZone.autoupdatingCurrent
    return formatter
  }
  
  /// Formats time components (hour, minute) using the user's locale
  /// - Parameters:
  ///   - hour: Hour (0-23)
  ///   - minute: Minute (0-59)
  /// - Returns: Localized time string (e.g., "2:30 PM" for US, "14:30" for 24-hour locales)
  static func localizedTimeString(hour: Int, minute: Int) -> String {
    let formatter = localizedTimeFormatter()
    
    let calendar = Calendar.current
    let now = Date()
    
    var components = calendar.dateComponents([.year, .month, .day], from: now)
    components.hour = hour
    components.minute = minute
    components.second = 0
    
    guard let date = calendar.date(from: components) else {
      // Fallback to simple format if date creation fails
      return String(format: "%02d:%02d", hour, minute)
    }
    
    return formatter.string(from: date)
  }
  
  /// Formats time components for notification body text
  /// - Parameters:
  ///   - hour: Hour (0-23)
  ///   - minute: Minute (0-59)
  /// - Returns: Localized time string suitable for notifications
  static func localizedTimeStringForNotification(hour: Int, minute: Int) -> String {
    let formatter = localizedTimeFormatter()
    
    let calendar = Calendar.current
    let now = Date()
    
    var components = calendar.dateComponents([.year, .month, .day], from: now)
    components.hour = hour
    components.minute = minute
    components.second = 0
    
    guard let date = calendar.date(from: components) else {
      // Fallback to simple format if date creation fails
      return String(format: "%02d:%02d", hour, minute)
    }
    
    return formatter.string(from: date)
  }
}
