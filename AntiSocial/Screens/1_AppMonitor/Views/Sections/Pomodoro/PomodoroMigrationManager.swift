//
//  PomodoroMigrationManager.swift
//  AntiSocialApp
//

import Foundation

// TODO: - Remove in feature versions when all users get updated pomodoro settings
enum PomodoroMigrationKeys {
  static let notificationsEnabled = SharedData.Pomodoro.notificationsEnabled
  static let soundEnabled         = SharedData.Pomodoro.soundEnabled
  static let autoStartBreak       = SharedData.Pomodoro.autoStartBreak
}

enum PomodoroDefaults {
  static let allTrueKeys: [String] = [
    PomodoroMigrationKeys.notificationsEnabled,
    PomodoroMigrationKeys.soundEnabled,
    PomodoroMigrationKeys.autoStartBreak
  ]
  
  static func forceEnableEveryLaunch(_ ud: UserDefaults) {
    for key in allTrueKeys {
      if (ud.object(forKey: key) as? Bool) != true {
        ud.set(true, forKey: key)
      }
    }
  }
  
  private static let flag = "pomodoro.migration.v1.forceAllTrue"
  
  static func oneTimeMigration(_ ud: UserDefaults) {
    guard ud.bool(forKey: flag) == false else {
      return
    }
    
    PomodoroDefaults.allTrueKeys.forEach { ud.set(true, forKey: $0) }
    
    ud.set(true, forKey: flag)
    
  }
}
