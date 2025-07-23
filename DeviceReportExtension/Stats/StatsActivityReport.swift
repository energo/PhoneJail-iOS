import DeviceActivity
import SwiftUI

struct StatsActivityReport: DeviceActivityReportScene {
  let context: DeviceActivityReport.Context = .statsActivity
  let content: (StatsData) -> StatsSectionView
  
  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> StatsData {
    // Используем тот же корректный алгоритм что и в TotalActivityReport
    let totalDuration = await data.flatMap { $0.activitySegments }.reduce(0, {
      $0 + $1.totalActivityDuration
    })
    
    var (chartData, focusedDuration, distractedDuration, _, appUsageDict, _) = await processDeviceActivityData(data)
    calculateOfflineMinutes(for: &chartData)
    let top3AppUsages = Array(appUsageDict.values
      .sorted { $0.usage > $1.usage }
      .prefix(3))

    return StatsData(
      totalDuration: totalDuration, // Используем корректное значение
      chartData: chartData,
      focusedDuration: focusedDuration,
      distractedDuration: distractedDuration,
      appUsages: top3AppUsages
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
    let totalDuration: TimeInterval = 0 // Оставляем для совместимости, но не используем
    
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
            
            // Убираем неправильное суммирование - теперь используем segment-based подход
            // totalDuration += appDuration // ❌ УДАЛЕНО - это вызывало двойной подсчет
            
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
    
    return (chartData,
            focusedDuration,
            distractedDuration,
            totalDuration,
            appUsageDict,
            perAppHourlyUsage)
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
