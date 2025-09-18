//
//  TotalActivityReport.swift
//  DeviceReportExtension
//
//  Created by D C on 01.07.2025.
//

import DeviceActivity
import SwiftUI

struct TotalActivityReport: DeviceActivityReportScene {
  
  let context: DeviceActivityReport.Context = .totalActivity
  let content: (ActivityReport) -> ScreenTimeSectionView
  
  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
    var apps: [AppDeviceActivity] = []
    var top: [AppDeviceActivity] = []
    
    var totalDuration: TimeInterval = 0
    var totalPickups = 0
    var longestActivity: DateInterval?
    var firstPickup: Date?
    var categories: [String] = []
    
    
    for await device in data {
      for await segment in device.activitySegments {
        totalDuration += segment.totalActivityDuration
        totalPickups = segment.totalPickupsWithoutApplicationActivity
        if longestActivity == nil { longestActivity = segment.longestActivity }
        if firstPickup == nil { firstPickup = segment.firstPickup }
        
        for await cat in segment.categories {
          if let name = cat.category.localizedDisplayName {
            categories.append(name)
          }
          
          for await ap in cat.applications {
            // Без токена — пропускаем (иначе потом любая попытка отрисовать/обработать может упасть)
            guard let token = ap.application.token else {
              continue
            }
            
            let bundle = ap.application.bundleIdentifier
            let appName = ap.application.localizedDisplayName ?? bundle ?? "App"
            let durationInterval = ap.totalActivityDuration
            
            // Уникальный id: сначала bundle, если его нет — на основе хэша имени и токена
            let id: String = bundle ?? "tok-\(token.hashValue)-\(abs(appName.hashValue))"
            
            // Формат времени
            let totalSeconds = Int(durationInterval)
            let h = totalSeconds / 3600
            let m = (totalSeconds % 3600) / 60
            let formatted = (h > 0) ? "\(h)h \(m)m" : "\(m)m"
            
            let entry = AppDeviceActivity(
              id: id,
              token: token,
              displayName: appName,
              duration: formatted,
              durationInterval: durationInterval,
              numberOfPickups: ap.numberOfPickups,
              category: cat.category.localizedDisplayName ?? "Other",
              numberOfNotifs: ap.numberOfNotifications
            )
            apps.append(entry)
          }
        }
      }
    }
    
    top = Array(apps.sorted { $0.durationInterval > $1.durationInterval }.prefix(3))
    
    let report = ActivityReport(
      totalDuration: totalDuration,
      totalPickupsWithoutApplicationActivity: totalPickups,
      longestActivity: longestActivity,
      firstPickup: firstPickup,
      categories: categories,
      apps: apps,
      topApps: top
    )
    
    return report
  }
}
