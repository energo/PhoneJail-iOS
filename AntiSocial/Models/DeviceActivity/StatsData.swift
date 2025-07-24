//
//  StatsData.swift
//  AntiSocial
//
//  Created by D C on 04.07.2025.
//

import Foundation

struct StatsData {
  let totalDuration: TimeInterval
  let chartData: [ChartBar]
  let focusedDuration: TimeInterval
  let distractedDuration: TimeInterval
  let appUsages: [AppUsage]              // top-3 по времени
  let appSessions: [AppUsageSession]
  
  var secondsSinceStartOfDay: TimeInterval {
    let startOfDay = Calendar.current.startOfDay(for: Date())
    return Date().timeIntervalSince(startOfDay)
  }
  
  var focusedPercent: Int {
    guard secondsSinceStartOfDay > 0 else { return 0 }
    return Int((focusedDuration / secondsSinceStartOfDay) * 100)
  }
  
  var distractedPercent: Int {
    guard secondsSinceStartOfDay > 0 else { return 0 }
    return Int((distractedDuration / secondsSinceStartOfDay) * 100)
  }
  
  var offlinePercent: Int {
    guard secondsSinceStartOfDay > 0 else { return 0 }
    let online = focusedDuration + distractedDuration
    let offline = max(0, secondsSinceStartOfDay - online)
    return Int((offline / secondsSinceStartOfDay) * 100)
  }
  
}

extension StatsData {
  static let empty = StatsData(
    totalDuration: 0,
    chartData: (0..<24).map { ChartBar(hour: $0, focusedMinutes: 0, distractedMinutes: 0) },
    focusedDuration: 0,
    distractedDuration: 0,
    appUsages: [],
    appSessions: []
  )
}

//struct StatsData {
//  let totalDuration: TimeInterval
//  let chartData: [ChartBar]
//  let focusedDuration: TimeInterval
//  let distractedDuration: TimeInterval
//  let appUsages: [AppUsage]
//
//  var secondsSinceStartOfDay: TimeInterval {
//    let startOfDay = Calendar.current.startOfDay(for: Date())
//    return Date().timeIntervalSince(startOfDay)
//  }
//
//  var focusedPercent: Int {
//    Int((focusedDuration / secondsSinceStartOfDay) * 100)
//  }
//
//  var distractedPercent: Int {
//    Int((distractedDuration / secondsSinceStartOfDay) * 100)
//  }
//
//  var offlinePercent: Int {
//    let online = focusedDuration + distractedDuration
//    let offline = max(0, secondsSinceStartOfDay - online)
//    return Int((offline / secondsSinceStartOfDay) * 100)
//  }
//
//  static let empty = StatsData(
//    totalDuration: 0,
//    chartData: (0..<24).map { ChartBar(hour: $0, focusedMinutes: 0, distractedMinutes: 0) },
//    focusedDuration: 0,
//    distractedDuration: 0,
//    appUsages: []
//  )
//}


