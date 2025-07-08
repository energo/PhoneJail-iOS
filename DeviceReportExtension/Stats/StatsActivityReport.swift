import DeviceActivity
import SwiftUI

struct StatsActivityReport: DeviceActivityReportScene {
  let context: DeviceActivityReport.Context = .statsActivity
  let content: (StatsData) -> StatsSectionView
  
  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> StatsData {
    var (chartData, focusedDuration, distractedDuration, totalDuration, appUsageDict, _) = await processDeviceActivityData(data)
    calculateOfflineMinutes(for: &chartData)
    let appUsages = Array(appUsageDict.values).sorted { $0.usage > $1.usage }
    return StatsData(
      totalDuration: totalDuration,
      chartData: chartData,
      focusedDuration: focusedDuration,
      distractedDuration: distractedDuration,
      appUsages: appUsages
    )
  }
  
  // MARK: - Device Activity Data Processing
  private func processDeviceActivityData(_ data: DeviceActivityResults<DeviceActivityData>) async -> (
    chartData: [ChartBar],
    focusedDuration: TimeInterval,
    distractedDuration: TimeInterval,
    totalDuration: TimeInterval,
    appUsageDict: [String: AppUsage],
    perAppHourlyUsage: [String: [Int: TimeInterval]]
  ) {
    var chartDataRaw = (0..<24).map { _ in (focused: 0.0, distracted: 0.0) }
    var distractedDuration: TimeInterval = 0
    var focusedDuration: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    var appUsageDict: [String: AppUsage] = [:]
    var perAppHourlyUsage: [String: [Int: TimeInterval]] = [:]
    
    for await d in data {
      for await segment in d.activitySegments {
        let segmentStart = segment.dateInterval.start
        let segmentEnd = segment.dateInterval.end
        let segmentDuration = segmentEnd.timeIntervalSince(segmentStart)
        guard segmentDuration > 0 else { continue }
        
        for await category in segment.categories {
          for await app in category.applications {
            let appDuration = app.totalActivityDuration
            
            let key = app.application.bundleIdentifier ?? "Unknown"
            let appName = app.application.localizedDisplayName ?? "App"
            let token = app.application.token!
            
            // Пропорциональное распределение по часам
            var current = segmentStart
            let appDurationPerSecond = appDuration / segmentDuration
            
            while current < segmentEnd {
              guard let hourStart = Calendar.current.dateInterval(of: .hour, for: current)?.start else { break }
              let hour = Calendar.current.component(.hour, from: hourStart)
              let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: hourStart)!
              let intervalEnd = min(nextHour, segmentEnd)
              let secondsInThisHour = intervalEnd.timeIntervalSince(current)
              let usageInThisHour = appDurationPerSecond * secondsInThisHour
              
              // Здесь можно добавить свою логику для focused/distracted
              let distractedMinutes = usageInThisHour / 60.0
              let focusedMinutes = 0.0 // или randomFocusedMinutes()
              
              if hour >= 0 && hour < 24 {
                chartDataRaw[hour].distracted += distractedMinutes
                chartDataRaw[hour].focused += focusedMinutes
                
                distractedDuration += usageInThisHour
                focusedDuration += focusedMinutes * 60.0
                
                perAppHourlyUsage[key, default: [:]][hour, default: 0] += usageInThisHour
              }
              current = intervalEnd
            }
            
            totalDuration += appDuration
            
            if let existing = appUsageDict[key] {
              appUsageDict[key] = AppUsage(name: appName, token: token, usage: existing.usage + appDuration)
            } else {
              appUsageDict[key] = AppUsage(name: appName, token: token, usage: appDuration)
            }
          }
        }
      }
    }
    
    // Округление только на финальном этапе
    var chartData: [ChartBar] = []
    for hour in 0..<24 {
      let focused = Int(chartDataRaw[hour].focused.rounded())
      let distracted = Int(chartDataRaw[hour].distracted.rounded())
      chartData.append(ChartBar(hour: hour, focusedMinutes: focused, distractedMinutes: distracted))
    }
    
    return (chartData, focusedDuration, distractedDuration, totalDuration, appUsageDict, perAppHourlyUsage)
  }
  
  private func randomFocusedMinutes() -> Int {
    Int.random(in: 0...1)
  }
  
  // MARK: - Offline Minutes Calculation
  private func calculateOfflineMinutes(for chartData: inout [ChartBar]) {
    for hour in 0..<24 {
      let hourSeconds = 60.0 * 60.0
      let distracted = TimeInterval(chartData[hour].distractedMinutes * 60)
      let focused = TimeInterval(chartData[hour].focusedMinutes * 60)
      let totalOnline = focused + distracted
      let offline = max(0, hourSeconds - totalOnline)
      chartData[hour].offlineMinutes = Int(offline / 60)
    }
  }
}




//struct StatsActivityReport: DeviceActivityReportScene {
//  let context: DeviceActivityReport.Context = .statsActivity
//  let content: (StatsData) -> StatsSectionView
//
//  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> StatsData {
//    var chartData = (0..<24).map { ChartBar(hour: $0, focusedMinutes: 0, distractedMinutes: 0) }
//    var distractedDuration: TimeInterval = 0
//    var focusedDuration: TimeInterval = 0
//    var totalDuration: TimeInterval = 0
//    var appUsageDict: [String: AppUsage] = [:]
//
//    func appIsFocused() -> Int {
//      // Рандомно возвращает число от 0 до 10 включительно
//      return Int.random(in: 0...10)
//    }
//
//    for await d in data {
//      for await segment in d.activitySegments {
//        let hour = Calendar.current.component(.hour, from: segment.dateInterval.start)
//
//        for await category in segment.categories {
//          for await app in category.applications {
//
//            let duration = app.totalActivityDuration
//
//            let minutes = Int(duration / 60)
//            let focusedMinutes = appIsFocused()
//
//            if hour >= 0 && hour < 24 {
//              chartData[hour].distractedMinutes += minutes
//              chartData[hour].focusedMinutes += focusedMinutes
//              distractedDuration += duration
//              // Для корректности статистики можно добавить:
//              focusedDuration += TimeInterval(focusedMinutes * 60)
//            }
//
//            totalDuration += duration
//
//            let key = app.application.bundleIdentifier ?? "Unknown"
//            let appName = app.application.localizedDisplayName ?? "App"
//            let token = app.application.token!
//
//            guard duration >= 60 else {
//              continue
//            }
//
//            if let existing = appUsageDict[key] {
//              appUsageDict[key] = AppUsage(name: appName, token: token, usage: existing.usage + duration)
//            } else {
//              appUsageDict[key] = AppUsage(name: appName, token: token, usage: duration)
//            }
//          }
//        }
//      }
//    }
//
//    // Расчёт offlineMinutes для каждого часа
//    for hour in 0..<24 {
//      let hourSeconds = 60.0 * 60.0
//      let distracted = TimeInterval(chartData[hour].distractedMinutes * 60)
//      let focused = TimeInterval(chartData[hour].focusedMinutes * 60)
//      let totalOnline = focused + distracted
//      let offline = max(0, hourSeconds - totalOnline)
//      chartData[hour].offlineMinutes = Int(offline / 60)
//    }
//
//    let appUsages = Array(appUsageDict.values).sorted { $0.usage > $1.usage }
//
//    for usage in appUsages {
//      print("  \(usage.name): \(Int(usage.usage/60)) мин")
//    }
//
//    return StatsData(
//      totalDuration: totalDuration,
//      chartData: chartData,
//      focusedDuration: focusedDuration,
//      distractedDuration: distractedDuration,
//      appUsages: appUsages
//    )
//  }
//}
