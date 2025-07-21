//
//  SharedData.swift
//  ScreenTimeTestApp
//
//  Created by D C on 12.02.2025.
//

import Foundation
import FamilyControls


class SharedData {
  static let defaultsGroup: UserDefaults? = UserDefaults(suiteName: "group.com.app.antisocial.sharedData")
  
  enum Keys {
    static let disabledApps = "DisabledApps"
    static let allSelectedApps = "AllSelectedApps"
    
    static let selectedFamilyActivity = "FamilyActivitySelection"
    static let tokenToDisplayName = "AppTokenDisplayNames"
    
    static let selectedInterraptedTimePeriods = "SelectedInterraptedTimePeriods"
    static let SelectedScreenAlertTimePeriods = "SelectedScreenAlertTimePeriods"
  }
  
  static var selectedInterraptedTimePeriods: Int {
    get {
      let value = defaultsGroup?.integer(forKey: Keys.selectedInterraptedTimePeriods) ?? 0
      print("get selectedInterraptedTimePeriods \(value)")
      return value
    }
    
    set {
      print("set selectedInterraptedTimePeriods \(newValue)")
      defaultsGroup?.set(newValue, forKey: Keys.selectedInterraptedTimePeriods)
    }
  }
  
  static var selectedScreenAlertTimePeriods: Int {
    get {
      let value = defaultsGroup?.integer(forKey: Keys.SelectedScreenAlertTimePeriods) ?? 0
      print("get selectedScreenAlertTimePeriods \(value)")
      return value
    }
    
    set {
      print("set selectedScreenAlertTimePeriods \(newValue)")
      defaultsGroup?.set(newValue, forKey: Keys.SelectedScreenAlertTimePeriods)
    }
  }

  
  static var selectedFamilyActivity: FamilyActivitySelection? {
    get {
      guard let data = defaultsGroup?.data(forKey: Keys.selectedFamilyActivity) else { return nil }
      
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } set {
      defaultsGroup?.set(try? JSONEncoder().encode(newValue), forKey: Keys.selectedFamilyActivity)
    }
  }
  
  static var disabledFamilyActivity: FamilyActivitySelection? {
    get {
      guard let data = defaultsGroup?.data(forKey: Keys.disabledApps) else { return nil }
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } set {
      defaultsGroup?.set(try? JSONEncoder().encode(newValue), forKey: Keys.disabledApps)
    }
  }
  
  static var allSelectedFamilyActivity: FamilyActivitySelection? {
    get {
      guard let data = defaultsGroup?.data(forKey: Keys.allSelectedApps) else { return nil }
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } set {
      defaultsGroup?.set(try? JSONEncoder().encode(newValue), forKey: Keys.allSelectedApps)
    }
  }
  
  static var tokenDisplayNameMap: [String: String] {
    get {
      defaultsGroup?.dictionary(forKey: Keys.tokenToDisplayName) as? [String: String] ?? [:]
    }
    set {
      defaultsGroup?.set(newValue, forKey: Keys.tokenToDisplayName)
    }
  }
  
  static func appName(for token: String) -> String {
    tokenDisplayNameMap[token] ?? "Приложение"
  }
}

