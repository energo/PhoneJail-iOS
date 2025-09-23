//
//  AppLogger.swift
//  DoThisNow
//
//  Created by D C on 12.03.2025.
//

import Foundation

struct DetailedError: LocalizedError {
  let underlyingError: Error
  let location: String

  var errorDescription: String? {
    return "\(underlyingError.localizedDescription) (\(location))"
  }
}


/// Log types, each associated with a specific symbol as a prefix
///
/// - critical: Log type for critical errors
/// - notice: Log type for informational notices
/// - trace: Log type for debugging traces
/// - alert: Log type for warning alerts
enum LogType: String {
    case critical = "Log[🚨]" // critical error
    case notice = "Log[📝]" // informational notice
    case trace = "Log[🐛]" // debugging trace
    case alert = "Log[⚠️]" // warning alert
}

func logMessage(_ message: Any) {
    // Only in DEBUG mode
    #if DEBUG
    Swift.print(message)
    #endif
}

class AppLogger {
    static var logDateFormat = "HH:mm:ss.SSS"
    static var logDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = logDateFormat
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeZone = TimeZone.autoupdatingCurrent
        return formatter
    }
    
    private static var isLogEnabled: Bool {
        #if DEBUG
        return true // DISABLED 
        #else
        return false
        #endif
    }
    
    // MARK: - Logging methods
    /// Logs critical errors with the prefix [🚨]
  class func critical( _ error: Error? = nil, details: String? = nil, file: String = #fileID, line: Int = #line, functionName: String = #function) {
    let location = "[\(file) \(functionName)] \(line)"

    if isLogEnabled {
      let context = error?.localizedDescription ?? "\(functionName) critical error"
      let message = (details ?? "") + context
      logMessage("\(Date().formattedString()) \(LogType.critical.rawValue) \(location) -> \(message)")
    } else {
      if let error = error {
        let detailedError = DetailedError(underlyingError: error, location: location)
        FirebaseReportService.sendNonCrashError(detailedError)
      }
    }
  }

    /// Logs informational messages with the prefix [📝]
    class func notice( _ message: Any, file: String = #fileID, line: Int = #line, functionName: String = #function) {
        if isLogEnabled {
          let location = "[\(file) \(functionName)] \(line)"
            logMessage("\(Date().formattedString()) \(LogType.notice.rawValue) \(location) -> \(message)")
        }
    }
    
    /// Logs debugging messages with the prefix [🐛]
    class func trace( _ message: Any, file: String = #fileID, line: Int = #line, functionName: String = #function) {
        if isLogEnabled {
          let location = "[\(file) \(functionName)] \(line)"
            logMessage("\(Date().formattedString()) \(LogType.trace.rawValue) \(location) -> \(message)")
        }
    }
    
    /// Logs warnings with the prefix [⚠️]
    class func alert( _ message: Any, file: String = #fileID, line: Int = #line, functionName: String = #function) {
        if isLogEnabled {
          let location = "[\(file) \(functionName)] \(line)"
            logMessage("\(Date().formattedString()) \(LogType.alert.rawValue) \(location) -> \(message)")
        }
    }

//    /// Extracts the file name from the full file path
//    ///
//    /// - Parameter filePath: Full file path in the bundle
//    /// - Returns: File name with extension
//    private class func fileName(from filePath: String) -> String {
//        let pathComponents = filePath.components(separatedBy: "/")
//        return pathComponents.isEmpty ? "" : pathComponents.last!
//    }
}

internal extension Date {
    func formattedString() -> String {
        return AppLogger.logDateFormatter.string(from: self)
    }
}
