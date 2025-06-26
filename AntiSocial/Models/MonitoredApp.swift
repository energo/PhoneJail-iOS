//
//  MonitoredApp.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import Foundation

struct MonitoredApp: Identifiable, Hashable {
  let id: String
  let token: ApplicationToken
  var isMonitored: Bool = true
  
  init(token: ApplicationToken, isMonitored: Bool = true) {
    self.token = token
    self.isMonitored = isMonitored
    // Используем описание токена для создания стабильного ID
    self.id = String(describing: token)
  }
  
  var displayName: String {
    return "App" // ApplicationToken не имеет displayName
  }
  
  var bundleIdentifier: String? {
    return nil // ApplicationToken не имеет bundleIdentifier
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func == (lhs: MonitoredApp, rhs: MonitoredApp) -> Bool {
    return lhs.id == rhs.id
  }
}
