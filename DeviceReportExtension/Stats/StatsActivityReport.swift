import DeviceActivity
import SwiftUI


struct StatsActivityReport: DeviceActivityReportScene {
  let context: DeviceActivityReport.Context = .statsActivity
  let content: (StatsData) -> StatsSectionView
  
  func makeConfiguration(
    representing data: DeviceActivityResults<DeviceActivityData>
  ) async -> StatsData {
    var chartData = (0..<24).map { ChartBar(hour: $0, focusedMinutes: 0, distractedMinutes: 0) }
    var distractedDuration: TimeInterval = 0
    var appUsageDict: [String: AppUsage] = [:]
    var totalDuration: TimeInterval = 0

    for await d in data {
      for await segment in d.activitySegments {
        let hour = Calendar.current.component(.hour, from: segment.dateInterval.start)

        for await category in segment.categories {
          for await app in category.applications {
            let duration = app.totalActivityDuration
            guard duration >= 60 else { continue }

            let minutes = Int(duration / 60)

            if hour >= 0 && hour < 24 {
              chartData[hour].distractedMinutes += minutes
              distractedDuration += duration
            }

            totalDuration += duration

            let key = app.application.bundleIdentifier ?? "Unknown"
            let appName = app.application.localizedDisplayName ?? "App"
            let token = app.application.token!

            if let existing = appUsageDict[key] {
              appUsageDict[key] = AppUsage(name: appName, token: token, usage: existing.usage + duration)
            } else {
              appUsageDict[key] = AppUsage(name: appName, token: token, usage: duration)
            }
          }
        }
      }
    }

    let appUsages = Array(appUsageDict.values).sorted { $0.usage > $1.usage }
//    let displayArray = Array(appUsages.prefix(3))

    return StatsData(
      totalDuration: totalDuration,
      chartData: chartData,
      focusedDuration: 0, // будет подставлено отдельно
      distractedDuration: distractedDuration,
      appUsages: appUsages
    )
  }


//  func makeConfiguration(
//    representing data: DeviceActivityResults<DeviceActivityData>
//  ) async -> StatsData {
//    var chartData = (0..<24).map { ChartBar(hour: $0, focusedMinutes: 0, distractedMinutes: 0) }
//    var focusedDuration: TimeInterval = 0
//    var distractedDuration: TimeInterval = 0
//    var appUsageDict: [String: AppUsage] = [:]
//    var totalDuration: TimeInterval = 0
//    
//    for await d in data {
//      for await segment in d.activitySegments {
//        let hour = Calendar.current.component(.hour, from: segment.dateInterval.start)
//        
//        for await category in segment.categories {
//          for await app in category.applications {
//            let duration = app.totalActivityDuration
//            let minutes = Int(duration / 60)
//            if duration < 60 { continue }
//            
//            if hour >= 0 && hour < 24 {
//              chartData[hour].distractedMinutes += minutes
//              distractedDuration += duration
//            }
//            
//            totalDuration += duration
//            let key = app.application.bundleIdentifier ?? "Unknown"
//            let appName = app.application.localizedDisplayName ?? "App"
//            let token = app.application.token!
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
//    let appUsages = Array(appUsageDict.values).sorted { $0.usage > $1.usage }
//    let displayArray = Array(appUsages.prefix(3))
//
//    return StatsData(
//      totalDuration: totalDuration,
//      chartData: chartData,
//      focusedDuration: focusedDuration,
//      distractedDuration: distractedDuration,
//      appUsages: displayArray
//    )
//  }
}


//struct StatsActivityReport: DeviceActivityReportScene {
//  let context: DeviceActivityReport.Context = .statsActivity
//  let content: (StatsData) -> StatsSectionView
//
//  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> StatsData {
//    var chartData = (0..<24).map {
//      ChartBar(hour: $0, focusedMinutes: 0, distractedMinutes: 0)
//    }
//
//    var focusedDuration: TimeInterval = 0
//    var distractedDuration: TimeInterval = 0
//    var appUsageDict: [String: AppUsage] = [:]
//    var totalDuration: TimeInterval = 0
//
//    for await d in data {
//      for await segment in d.activitySegments {
//        guard Calendar.current.isDateInToday(segment.dateInterval.start) else { continue }
//
//        let hour = Calendar.current.component(.hour, from: segment.dateInterval.start)
//
//        for await category in segment.categories {
//          for await app in category.applications {
//            let duration = app.totalActivityDuration
//            let minutes = Int(duration / 60)
//            if duration < 60 { continue }
//
//            if hour >= 0 && hour < 24 {
//              chartData[hour].distractedMinutes += minutes
//              distractedDuration += duration
//            }
//
//            totalDuration += duration
//            let key = app.application.bundleIdentifier ?? "Unknown"
//            let appName = app.application.localizedDisplayName ?? "App"
//            let token = app.application.token!
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
//    let appUsages = Array(appUsageDict.values).sorted { $0.usage > $1.usage }
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

//struct StatsActivityReport: DeviceActivityReportScene {
//  let context: DeviceActivityReport.Context = .statsActivity
//  let content: (StatsData) -> StatsSectionView
//
//  //MARK: -
//  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> StatsData {
//    print("makeConfiguration called for StatsActivityReport")
//
//    var chartData = Array(repeating: ChartBar(hour: 0,
//                                              focusedMinutes: 0,
//                                              distractedMinutes: 0),
//                          count: 24)
//    for hour in 0..<24 {
//      chartData[hour] = ChartBar(hour: hour, focusedMinutes: 0, distractedMinutes: 0)
//    }
//
//    var focusedDuration: TimeInterval = 0
//    var distractedDuration: TimeInterval = 0
//
//    // Используем словарь для агрегации usage по приложению
//    var appUsageDict: [String: AppUsage] = [:]
//
//    var totalDuration: TimeInterval = 0
//
//    for await d in data {
//      for await segment in d.activitySegments {
//        // ✅ Фильтруем только на сегодня
//        guard Calendar.current.isDateInToday(segment.dateInterval.start) else { continue }
//
//        let hour = Calendar.current.component(.hour, from: segment.dateInterval.start)
//
//        for await category in segment.categories {
//          for await app in category.applications {
//            let duration = app.totalActivityDuration
//            let minutes = Int(duration / 60)
//
//            if duration < 60 { continue }
//
//            if hour >= 0 && hour < 24 {
//              chartData[hour].distractedMinutes += minutes
//              distractedDuration += duration
//            }
//
//            totalDuration += duration
//            let appName = app.application.localizedDisplayName ?? "App"
//            let token = app.application.token!
//            let key = app.application.bundleIdentifier ?? "Unknown"
//
//            if let existing = appUsageDict[key] {
//              appUsageDict[key] = AppUsage(
//                name: appName,
//                token: token,
//                usage: existing.usage + duration
//              )
//            } else {
//              appUsageDict[key] = AppUsage(
//                name: appName,
//                token: token,
//                usage: duration
//              )
//            }
//          }
//        }
//      }
//    }
//
//    let appUsages = Array(appUsageDict.values).sorted { $0.usage > $1.usage }
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


//import DeviceActivity
