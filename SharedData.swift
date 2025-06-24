//
//  SharedData.swift
//  ScreenTimeTestApp
//
//  Created by D C on 12.02.2025.
//

import Foundation

import FamilyControls


class SharedData {
  static let defaultsGroup: UserDefaults? = UserDefaults(suiteName: "group.ScreenTimeTestApp.sharedData")
  //  let userDefaultsKey = "FamilyActivitySelection"
  
  enum Keys: String {
    case selectedFamilyActivity = "FamilyActivitySelection"
    
    var key: String {
      switch self {
        default: self.rawValue
      }
    }
  }
  
  static var selectedFamilyActivity: FamilyActivitySelection? {
    get {
      guard let data = defaultsGroup?.data(forKey: Keys.selectedFamilyActivity.key) else { return nil }
      
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } set {
      defaultsGroup?.set(try? JSONEncoder().encode(newValue), forKey: Keys.selectedFamilyActivity.key)
    }
  }
}

//  static var isUserPremium: Bool {
//      get {
//          defaultsGroup?.bool(forKey: Keys.selectedFamilyActivity.key) ?? false
//      } set {
//          defaultsGroup?.set(newValue, forKey: Keys.selectedFamilyActivity.key)
//      }
//  }

