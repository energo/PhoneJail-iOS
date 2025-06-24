//
//  FCUserDefaults.swift
//  DoThisNow
//
//  Created by D C on 13.03.2025.
//

import Foundation

class FCUserDefaults {
  enum DefaultsKey: String, CaseIterable {
    case lastUpdatedDateUser
    case lastUpdatedDateFolders
    case lastUpdatedDateBoards
    case lastUpdatedDateCards
    case lastUpdatedDateAll
    case isSubscribed
    case lastStudyDate
    case lastImportDate
    case usageCounters
  }

  static let shared = FCUserDefaults()
  private let defaults = UserDefaults.standard
  private let queue = DispatchQueue(label: "com.app.antiSocial.UserDefaultsQueue", attributes: .concurrent)

  private init() {}

    // to set value using pre-defined key
  func set(_ value: Any?, key: DefaultsKey) {
    queue.async(flags: .barrier) {
      self.defaults.setValue(value, forKey: key.rawValue)
    }
  }

    // get value using pre-defined key
  func get(key: DefaultsKey) -> Any? {
    return queue.sync {
      return defaults.value(forKey: key.rawValue)
    }
  }

    // check value if exist or nil
  func hasValue(key: DefaultsKey) -> Bool {
    return defaults.value(forKey: key.rawValue) != nil
  }

    // remove all stored values
  func removeAll() {
    for key in DefaultsKey.allCases {
      defaults.removeObject(forKey: key.rawValue)
    }
  }
}
