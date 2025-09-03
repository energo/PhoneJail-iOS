import DeviceActivity
import SwiftUI

// Кеш для хранения результатов


struct StatsActivityReport: DeviceActivityReportScene {
  let context: DeviceActivityReport.Context = .statsActivity
  let content: (StatsData) -> StatsSectionView
  
  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> StatsData {
    
    var sessions: [AppUsageSession] = []
    var reportDate: Date? = nil
    
    // Calculate total duration correctly - same as TotalActivityReport
    let totalDuration = await data.flatMap { $0.activitySegments }.reduce(0) {
      $0 + $1.totalActivityDuration
    }
    
    var segmentCount = 0
    var totalApps = 0
    
    // Сначала получаем дату из первого сегмента
    for await d in data {
      for await segment in d.activitySegments {
        if reportDate == nil {
          reportDate = segment.dateInterval.start
        }
        break
      }
      break
    }
    
    // Проверяем кеш ПОСЛЕ получения правильной даты
//    if let reportDate = reportDate {
//      if let cachedData = await StatsCache.shared.get(for: reportDate) {
//        // Проверяем что кешированные данные соответствуют ожидаемому totalDuration
//        // Если данные не совпадают, не используем кеш
//        if abs(cachedData.totalDuration - totalDuration) < 60 { // допускаем разницу в 1 минуту
//          return cachedData
//        }
//      }
//    }
    
    // Теперь обрабатываем все сегменты
    for await d in data {
      for await segment in d.activitySegments {
        segmentCount += 1
        // Use segment's actual date interval if available
        let segmentInterval = segment.dateInterval
        
        for await category in segment.categories {
          for await app in category.applications {
            let duration = app.totalActivityDuration
            guard duration > 0 else { continue }
            guard let token = app.application.token else { continue }
            let appName = app.application.localizedDisplayName ?? "App"
            
            // Получаем количество запусков приложения
            let pickups = app.numberOfPickups
            
            // С hourly сегментами мы знаем ТОЧНЫЙ час использования!
            // Каждый сегмент = 1 час, так что все время приложения в этом сегменте
            // было использовано именно в этот час
            
            let session = AppUsageSession(
              token: token,
              appName: appName,
              start: segmentInterval.start,  // Начало часа
              end: segmentInterval.end,      // Конец часа
              duration: duration,
              numberOfPickups: pickups,
              firstPickupTime: nil
            )
            
            sessions.append(session)
            totalApps += 1
          }
        }
      }
    }
    
    // Processed segments and apps
    
    let chartData = generateChartBars(from: sessions, reportDate: reportDate ?? Date())
    
    // Calculate focused duration from chart data (convert minutes to seconds)
    let focusedDuration = chartData.reduce(0.0) { $0 + Double($1.focusedMinutes * 60) }
    
    // Calculate distracted duration from chart data (convert minutes to seconds)
    // Distracted time is independent from focused time!
    let distractedDuration = chartData.reduce(0.0) { $0 + Double($1.distractedMinutes * 60) }
    
    // Считаем проценты от 24 часов
    let totalSeconds: TimeInterval = 86400
    let focusedPercent = Int((focusedDuration / totalSeconds) * 100)
    let distractedPercent = Int((distractedDuration / totalSeconds) * 100)
//    let offlinePercent = 100 - focusedPercent - distractedPercent
    
    let top3AppUsages = topAppUsages(from: sessions, count: 3)
    
    var filledChartData = chartData
    for hour in 0..<filledChartData.count {
      let total = filledChartData[hour].totalMinutes
      filledChartData[hour].offlineMinutes = max(0, 60 - total)
    }
    
    let result = StatsData(
      totalDuration: totalDuration,  // Now using correct total from segments
      chartData: filledChartData,
      focusedDuration: focusedDuration,
      distractedDuration: distractedDuration,
      appUsages: top3AppUsages,
      appSessions: sessions
    )
    
    // Сохраняем в кеш
//    if let reportDate = reportDate {
//      await StatsCache.shared.set(result, for: reportDate)
//    }
    
    return result
  }
  
  func generateChartBars(from sessions: [AppUsageSession], reportDate: Date) -> [ChartBar] {
      var hourly = Array(repeating: (focused: 0.0, distracted: 0.0), count: 24)
      let calendar = Calendar.current
      
      // Используем переданную дату отчета
      let chartDate = calendar.startOfDay(for: reportDate)
      
      // Получаем сессии блокировки для конкретной даты
      let blockingSessions = SharedData.getBlockingSessions(for: chartDate)
      
      // С hourly сегментами каждая сессия уже привязана к конкретному часу
      for session in sessions {
          let hour = calendar.component(.hour, from: session.start)
          let totalMinutes = session.duration / 60.0
          
          if hour >= 0 && hour < 24 && totalMinutes > 0 {
              // Добавляем distracted время в соответствующий час
              hourly[hour].distracted += totalMinutes
          }
      }
      
      // Добавляем focused time из сессий блокировки
      for session in blockingSessions {
          let startTime = session.startTime
          let endTime = session.endTime ?? Date()
          
          // Проверяем, что сессия пересекается с выбранным днем
          let dayStart = calendar.startOfDay(for: chartDate)
          let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? chartDate
          
          // Если сессия закончилась до начала дня или началась после конца дня - пропускаем
          if endTime <= dayStart || startTime >= dayEnd {
              continue
          }
          
          // Ограничиваем время сессии рамками дня
          let sessionStart = max(startTime, dayStart)
          let sessionEnd = min(endTime, dayEnd)
          
          // Распределяем время сессии по часам
          var currentTime = sessionStart
          while currentTime < sessionEnd {
              let hour = calendar.component(.hour, from: currentTime)
              
              // Создаем границу следующего часа правильно
              var components = calendar.dateComponents([.year, .month, .day, .hour], from: currentTime)
              components.hour = hour + 1
              components.minute = 0
              components.second = 0
              let nextHour = calendar.date(from: components) ?? currentTime
              
              let intervalEnd = min(nextHour, sessionEnd)
              
              let minutes = intervalEnd.timeIntervalSince(currentTime) / 60.0
              
              if hour >= 0 && hour < 24 {
                  // Просто добавляем focused время
                  // НЕ вычитаем из distracted - они независимы друг от друга
                  hourly[hour].focused += minutes
              }
              
              currentTime = intervalEnd
          }
      }

      
      return (0..<24).map { hour in
          // ВАЖНО: В одном часе не может быть больше 60 минут!
          // Если focused и distracted пересекаются, их сумма не должна превышать 60
          let focusedMins = Int(hourly[hour].focused.rounded())
          let distractedMins = Int(hourly[hour].distracted.rounded())
          
          // Ограничиваем каждое значение максимум 60 минутами
          let finalFocused = min(focusedMins, 60)
          let finalDistracted = min(distractedMins, 60)
          
          // Если сумма больше 60, нужно пропорционально уменьшить
          // Это может произойти, если focused и distracted пересекаются
          let total = finalFocused + finalDistracted
          if total > 60 && total > 0 {
              // Пропорционально масштабируем
              let scale = 60.0 / Double(total)
              return ChartBar(
                  hour: hour,
                  focusedMinutes: Int(Double(finalFocused) * scale),
                  distractedMinutes: Int(Double(finalDistracted) * scale)
              )
          }
          
          return ChartBar(
              hour: hour,
              focusedMinutes: finalFocused,
              distractedMinutes: finalDistracted
          )
      }
  }
  
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
