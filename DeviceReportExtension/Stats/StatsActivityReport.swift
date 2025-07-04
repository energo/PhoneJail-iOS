import DeviceActivity
import SwiftUI

//extension DeviceActivityReport.Context {
//  static let statsActivity = Self("Stats Activity")
//}
//
struct StatsActivityReport: DeviceActivityReportScene {
  let context: DeviceActivityReport.Context = .statsActivity
  let content: (StatsData) -> StatsSectionView
  
  //MARK: -
  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> StatsData {
    print("makeConfiguration called for StatsActivityReport")

    var chartData = Array(repeating: ChartBar(hour: 0, focusedMinutes: 0, distractedMinutes: 0), count: 24)
    for hour in 0..<24 {
      chartData[hour] = ChartBar(hour: hour, focusedMinutes: 0, distractedMinutes: 0)
    }

    var focusedDuration: TimeInterval = 0
    var distractedDuration: TimeInterval = 0
    var appUsages: [AppUsage] = []
    var totalDuration: TimeInterval = 0

    for await d in data {
      for await segment in d.activitySegments {
        let hour = Calendar.current.component(.hour, from: segment.dateInterval.start)

        for await category in segment.categories {
          for await app in category.applications {
            let duration = app.totalActivityDuration
            let minutes = Int(duration / 60)

            if hour >= 0 && hour < 24 {
//              if segment.isUserInitiated {
//                chartData[hour].focusedMinutes += minutes
//                focusedDuration += duration
//              } else {
                chartData[hour].distractedMinutes += minutes
                distractedDuration += duration
//              }
            }

            totalDuration += duration
            let appName = app.application.localizedDisplayName ?? "App"
            appUsages.append(AppUsage(name: appName, token: app.application.token!, usage: duration))
          }
        }
      }
    }

    return StatsData(
      totalDuration: totalDuration,
      chartData: chartData,
      focusedDuration: focusedDuration,
      distractedDuration: distractedDuration,
      appUsages: appUsages
    )
  }

}
