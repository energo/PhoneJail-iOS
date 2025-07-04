//
//  AppIcon.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import Foundation
import SwiftUI
import UIKit

struct AppIcon: Identifiable {
  let id = UUID()
  let name: String
  let icon: Image
}

enum AppCategory: String, CaseIterable, Identifiable {
  case allInternet = "All Internet"
  case socialMedia = "Social Media"
  case news = "New"
  
  var id: String { rawValue }
  var title: String { rawValue }
  // Можно добавить иконку, если нужно
}

enum AlertCategory: String, CaseIterable, Identifiable {
  case allInternet = "All Internet"
  case socialMedia = "Social Media"
  case news = "New"
  
  var id: String { rawValue }
  var title: String { rawValue }
}

struct StatsData {
  let totalDuration: TimeInterval
  let chartData: [ChartBar]
  let focusedDuration: TimeInterval
  let distractedDuration: TimeInterval
  let appUsages: [AppUsage]
  var focusedPercent: Int {
    totalDuration > 0 ? Int((focusedDuration / totalDuration) * 100) : 0
  }
  var distractedPercent: Int {
    totalDuration > 0 ? Int((distractedDuration / totalDuration) * 100) : 0
  }
}

struct AppUsage: Identifiable {
  let id = UUID()
  let name: String
  let icon: UIImage
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
