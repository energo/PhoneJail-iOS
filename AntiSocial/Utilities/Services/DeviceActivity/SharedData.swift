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
}

