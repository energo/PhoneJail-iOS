//
//  AppUsage.swift
//  AntiSocial
//
//  Created by D C on 04.07.2025.
//

import Foundation
import DeviceActivity
import ManagedSettings

struct AppUsageSession: Identifiable {
  let id = UUID()
  let token: ApplicationToken
  let appName: String
  let start: Date
  let end: Date
  let duration: TimeInterval
  let numberOfPickups: Int
  let firstPickupTime: Date?
  
  var durationString: String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
}

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

// MARK: - For AppsActivityReport
struct AppsReportData {
  let apps: [AppUsageInfo]
  let totalDuration: TimeInterval
  let reportDate: Date
  
  var totalDurationString: String {
    let hours = Int(totalDuration) / 3600
    let minutes = (Int(totalDuration) % 3600) / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
}

struct AppUsageInfo: Identifiable {
  let id = UUID()
  let token: ApplicationToken
  let name: String
  let duration: TimeInterval
  
  var durationString: String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else if minutes > 0 {
      return "\(minutes)m"
    } else {
      return "< 1m"
    }
  }
}



