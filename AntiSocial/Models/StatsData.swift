//
//  StatsData.swift
//  AntiSocial
//
//  Created by D C on 04.07.2025.
//

import Foundation

struct StatsData {
  let totalDuration: TimeInterval
  let secondsInDay: TimeInterval = 24 * 60 * 60

  let chartData: [ChartBar]
  let focusedDuration: TimeInterval
  let distractedDuration: TimeInterval
  let appUsages: [AppUsage]
  
  var focusedPercent: Int {
    totalDuration > 0 ? Int((focusedDuration / secondsInDay) * 100) : 0
  }
  
  var distractedPercent: Int {
    totalDuration > 0 ? Int((distractedDuration / secondsInDay) * 100) : 0
  }
  
  var offlinePercent: Int {
      let online = focusedDuration + distractedDuration
      let offline = max(0, secondsInDay - online)
      return Int((offline / secondsInDay) * 100)
  }
}
