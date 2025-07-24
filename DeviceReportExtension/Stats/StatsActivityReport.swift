import DeviceActivity
import SwiftUI

struct StatsActivityReport: DeviceActivityReportScene {
  let context: DeviceActivityReport.Context = .statsActivity
  let content: (StatsData) -> StatsSectionView
  
  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> StatsData {
    var sessions: [AppUsageSession] = []
    
    for await d in data {
      for await segment in d.activitySegments {
        guard let baseStart = segment.longestActivity?.start else { continue }
        
        for await category in segment.categories {
          for await app in category.applications {
            let duration = app.totalActivityDuration
            guard duration > 0 else { continue }
            guard let token = app.application.token else { continue }
            let appName = app.application.localizedDisplayName ?? "App"
            
            let start = baseStart
            let end = start.addingTimeInterval(duration)
            
            let session = AppUsageSession(
              token: token,
              appName: appName,
              start: start,
              end: end,
              duration: duration
            )
            
            print("\(session.appName): \(session.start.formatted()) → \(session.end.formatted()), duration: \(session.duration / 60) min")

            sessions.append(session)
          }
        }
      }
    }
    
    let chartData = generateChartBars(from: sessions)
    let totalDuration = sessions.reduce(0) { $0 + $1.duration }
    
    let (focusedDuration, distractedDuration) = (0.0, totalDuration)
    let top3AppUsages = topAppUsages(from: sessions, count: 3)
    
    var filledChartData = chartData
    for hour in 0..<filledChartData.count {
      let total = filledChartData[hour].totalMinutes
      filledChartData[hour].offlineMinutes = max(0, 60 - total)
    }
    
    return StatsData(
      totalDuration: totalDuration,
      chartData: filledChartData,
      focusedDuration: focusedDuration,
      distractedDuration: distractedDuration,
      appUsages: top3AppUsages,
      appSessions: sessions
    )
  }
  
  func generateChartBars(from sessions: [AppUsageSession]) -> [ChartBar] {
      var hourly = Array(repeating: (focused: 0.0, distracted: 0.0), count: 24)
      let calendar = Calendar.current

      for session in sessions {
          var t1 = session.start
          let t2 = session.end

          while t1 < t2 {
              // Получаем локальный час
              let hour = calendar.dateComponents(in: TimeZone.current, from: t1).hour ?? 0
              guard hour >= 0 && hour < 24 else { break }

              // Граница текущего часа
              guard let hourStart = calendar.dateInterval(of: .hour, for: t1) else { break }
              let hourEnd = hourStart.end

              // Насколько usage залезает в этот час
              let intervalEnd = min(hourEnd, t2)
              let secondsInThisHour = intervalEnd.timeIntervalSince(t1)

              // Записываем usage
              hourly[hour].distracted += secondsInThisHour / 60.0

              // Продвигаем time pointer
              t1 = intervalEnd
          }
      }

      // Конвертируем в ChartBar
      return (0..<24).map { hour in
          ChartBar(
              hour: hour,
              focusedMinutes: Int(hourly[hour].focused.rounded()),
              distractedMinutes: Int(hourly[hour].distracted.rounded())
          )
      }
  }

//  func generateChartBars(from sessions: [AppUsageSession]) -> [ChartBar] {
//      var hourly = Array(repeating: (focused: 0.0, distracted: 0.0), count: 24)
//      let calendar = Calendar.current
//
//      for session in sessions {
//          var t1 = session.start
//          let t2 = session.end
//
//          while t1 < t2 {
//              let hour = calendar.component(.hour, from: t1)
//              guard hour >= 0 && hour < 24 else { break }
//
//              guard let hourStart = calendar.dateInterval(of: .hour, for: t1) else { break }
//              let hourEnd = hourStart.end
//              let intervalEnd = min(hourEnd, t2)
//              let secondsInThisHour = intervalEnd.timeIntervalSince(t1)
//
//              hourly[hour].distracted += secondsInThisHour / 60.0
//              t1 = intervalEnd
//          }
//      }
//
//      return (0..<24).map { hour in
//          ChartBar(
//              hour: hour,
//              focusedMinutes: Int(hourly[hour].focused.rounded()),
//              distractedMinutes: Int(hourly[hour].distracted.rounded())
//          )
//      }
//  }
  
  /// Генерация баров по usage по часам (локальное время)
  //    func generateChartBars(from sessions: [AppUsageSession]) -> [ChartBar] {
  //        var hourly = Array(repeating: (focused: 0.0, distracted: 0.0), count: 24)
  //        let calendar = Calendar.current
  //
  //        for session in sessions {
  //            var t1 = session.start
  //            let t2 = session.end
  //
  //            while t1 < t2 {
  //                let hour = calendar.dateComponents(in: TimeZone.current, from: t1).hour ?? 0
  //                guard let hourStart = calendar.dateInterval(of: .hour, for: t1) else { break }
  //                let nextHour = hourStart.end
  //                let intervalEnd = min(nextHour, t2)
  //                let secondsInThisHour = intervalEnd.timeIntervalSince(t1)
  //
  //                hourly[hour].distracted += secondsInThisHour / 60.0
  //                t1 = intervalEnd
  //            }
  //        }
  //
  //        return (0..<24).map { hour in
  //            ChartBar(
  //                hour: hour,
  //                focusedMinutes: Int(hourly[hour].focused.rounded()),
  //                distractedMinutes: Int(hourly[hour].distracted.rounded())
  //            )
  //        }
  //    }
  
  /// Top-N приложений по usage
  func topAppUsages(from sessions: [AppUsageSession], count: Int = 3) -> [AppUsage] {
    let grouped = Dictionary(grouping: sessions, by: { $0.token })
    return grouped
      .map { (token, sess) in
        AppUsage(
          name: sess.first?.appName ?? "App",
          token: token,
          usage: sess.reduce(0) { $0 + $1.duration }
        )
      }
      .sorted { $0.usage > $1.usage }
      .prefix(count)
      .map { $0 }
  }
  
  /// Расчёт offline минут (если вдруг понадобится отдельно)
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

