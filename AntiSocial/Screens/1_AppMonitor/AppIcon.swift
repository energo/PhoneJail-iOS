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
  let focusedLifetime: TimeInterval
  let chartData: [ChartBar] // см. ниже
  let focusedPercent: Int
  let distractedPercent: Int
  let offlinePercent: Int
  let appUsages: [AppUsage]
  
  var focusedLifetimeString: String {
    let hours = Int(focusedLifetime) / 3600
    let minutes = (Int(focusedLifetime) % 3600) / 60
    return "\(hours)H \(minutes)M FOCUSED LIFETIME"
  }
}

struct ChartBar: Identifiable {
  let id = UUID()
  let hour: Int
  let focusedMinutes: Int
  let distractedMinutes: Int
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
