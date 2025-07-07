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
  let appUsages: [AppUsage]

  var secondsSinceStartOfDay: TimeInterval {
    let startOfDay = Calendar.current.startOfDay(for: Date())
    return Date().timeIntervalSince(startOfDay)
  }

  var focusedPercent: Int {
    Int((focusedDuration / secondsSinceStartOfDay) * 100)
  }

  var distractedPercent: Int {
    Int((distractedDuration / secondsSinceStartOfDay) * 100)
  }

  var offlinePercent: Int {
    let online = focusedDuration + distractedDuration
    let offline = max(0, secondsSinceStartOfDay - online)
    return Int((offline / secondsSinceStartOfDay) * 100)
  }

  static let empty = StatsData(
    totalDuration: 0,
    chartData: (0..<24).map { ChartBar(hour: $0, focusedMinutes: 0, distractedMinutes: 0) },
    focusedDuration: 0,
    distractedDuration: 0,
    appUsages: []
  )
}

//struct StatsData {
//  let totalDuration: TimeInterval
//  let secondsInDay: TimeInterval = 24 * 60 * 60
//
//  let chartData: [ChartBar]
//  let focusedDuration: TimeInterval
//  let distractedDuration: TimeInterval
//  let appUsages: [AppUsage]
//  
//  var focusedPercent: Int {
//    totalDuration > 0 ? Int((focusedDuration / secondsInDay) * 100) : 0
//  }
//  
//  var distractedPercent: Int {
//    totalDuration > 0 ? Int((distractedDuration / secondsInDay) * 100) : 0
//  }
//  
//  var offlinePercent: Int {
//      let online = focusedDuration + distractedDuration
//      let offline = max(0, secondsInDay - online)
//      return Int((offline / secondsInDay) * 100)
//  }
//}

struct ChartBar: Identifiable {
  let id = UUID()
  let hour: Int
  var focusedMinutes: Int
  var distractedMinutes: Int
}
