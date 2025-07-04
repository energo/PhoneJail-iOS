//
//  AppUsage.swift
//  AntiSocial
//
//  Created by D C on 04.07.2025.
//

import Foundation
import DeviceActivity
import ManagedSettings

struct AppUsage: Identifiable {
  let id = UUID()
  let name: String
  var token: ApplicationToken
  let usage: TimeInterval
  
  var usageString: String {
    let hours = Int(usage) / 3600
    let minutes = (Int(usage) % 3600) / 60
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
}
