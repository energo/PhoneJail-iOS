import DeviceActivity
import SwiftUI

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
    
    for await d in data {
      for await segment in d.activitySegments {
        // Use segment's actual date interval if available
        let segmentInterval = segment.dateInterval
        
        // Сохраняем дату из первого сегмента
        if reportDate == nil {
          reportDate = segmentInterval.start
        }
        
        for await category in segment.categories {
          for await app in category.applications {
            let duration = app.totalActivityDuration
            guard duration > 0 else { continue }
            guard let token = app.application.token else { continue }
            let appName = app.application.localizedDisplayName ?? "App"
            
            // ВАЖНО: DeviceActivity API не предоставляет точное время использования каждого приложения
            // Только общую длительность за сегмент. Мы не можем знать точные часы использования.
            // Поэтому распределяем время равномерно по периоду сегмента для визуализации.
            
            // Вариант 1: Распределить пропорционально по всему сегменту
            // Это даст более реалистичное распределение по часам
            let segmentDuration = segmentInterval.duration
            let segmentHours = segmentDuration / 3600.0 // часы в сегменте
            
            // Создаем псевдо-сессию для отображения в чартах
            // Размазываем использование по всему интервалу сегмента пропорционально
            let session = AppUsageSession(
              token: token,
              appName: appName,
              start: segmentInterval.start,
              end: segmentInterval.end, // используем конец сегмента
              duration: duration
            )
            
            sessions.append(session)
          }
        }
      }
    }
    
    let chartData = generateChartBars(from: sessions, reportDate: reportDate ?? Date())
    
    // Calculate focused duration from chart data (convert minutes to seconds)
    let focusedDuration = chartData.reduce(0.0) { $0 + Double($1.focusedMinutes * 60) }
    
    // Calculate distracted duration from chart data (convert minutes to seconds)
    // Distracted time is independent from focused time!
    let distractedDuration = chartData.reduce(0.0) { $0 + Double($1.distractedMinutes * 60) }
    
    // DEBUG: Выводим значения для отладки процентов
    print("📊 Stats Debug: totalDuration=\(totalDuration)s (\(totalDuration/3600)h)")
    print("📊 Stats Debug: focusedDuration=\(focusedDuration)s (\(focusedDuration/3600)h)")
    print("📊 Stats Debug: distractedDuration=\(distractedDuration)s (\(distractedDuration/3600)h)")
    
    // Считаем проценты от 24 часов
    let totalSeconds: TimeInterval = 86400
    let focusedPercent = Int((focusedDuration / totalSeconds) * 100)
    let distractedPercent = Int((distractedDuration / totalSeconds) * 100)
    let offlinePercent = 100 - focusedPercent - distractedPercent
    
    print("📊 Stats Debug: Percentages from 24h:")
    print("📊 Stats Debug: focused=\(focusedPercent)%, distracted=\(distractedPercent)%, offline=\(offlinePercent)%")
    print("📊 Stats Debug: Total should be 100%: \(focusedPercent + distractedPercent + offlinePercent)%")
    
    let top3AppUsages = topAppUsages(from: sessions, count: 3)
    
    var filledChartData = chartData
    for hour in 0..<filledChartData.count {
      let total = filledChartData[hour].totalMinutes
      filledChartData[hour].offlineMinutes = max(0, 60 - total)
    }
    
    return StatsData(
      totalDuration: totalDuration,  // Now using correct total from segments
      chartData: filledChartData,
      focusedDuration: focusedDuration,
      distractedDuration: distractedDuration,
      appUsages: top3AppUsages,
      appSessions: sessions
    )
  }
  
  func generateChartBars(from sessions: [AppUsageSession], reportDate: Date) -> [ChartBar] {
      var hourly = Array(repeating: (focused: 0.0, distracted: 0.0), count: 24)
      let calendar = Calendar.current
      
      // Используем переданную дату отчета
      let chartDate = calendar.startOfDay(for: reportDate)
      
      // Получаем сессии блокировки для конкретной даты
      let blockingSessions = SharedData.getBlockingSessions(for: chartDate)
      
      // DEBUG: Логируем количество сессий
      print("📊 Chart Debug: App usage sessions count: \(sessions.count)")
      print("📊 Chart Debug: Blocking sessions count: \(blockingSessions.count)")
      

      for session in sessions {
          // session.duration - реальное время использования
          // session.start и session.end - период сегмента (не реальное время использования)
          
          // Вычисляем сколько часов покрывает сегмент
          let segmentDuration = session.end.timeIntervalSince(session.start)
          let segmentHours = segmentDuration / 3600.0
          
          // Распределяем время использования пропорционально по часам сегмента
          var t1 = session.start
          let t2 = session.end
          var remainingDuration = session.duration

          while t1 < t2 && remainingDuration > 0 {
              // Получаем локальный час начала текущего фрагмента
              let hour = calendar.dateComponents(in: TimeZone.current, from: t1).hour ?? 0

              // Граница текущего часа
              guard let hourStart = calendar.dateInterval(of: .hour, for: t1) else { break }
              let hourEnd = hourStart.end

              // Обрезаем интервал, если он уходит за этот час
              let intervalEnd = min(hourEnd, t2)
              let intervalDuration = intervalEnd.timeIntervalSince(t1)
              
              // Вычисляем пропорциональную долю времени использования для этого интервала
              let proportionalMinutes: Double
              if segmentDuration > 0 {
                  // Доля этого интервала от общего сегмента
                  let proportion = intervalDuration / segmentDuration
                  // Соответствующая доля от общего времени использования
                  proportionalMinutes = (session.duration * proportion) / 60.0
              } else {
                  proportionalMinutes = 0
              }

              // Кладём в текущий бар
              if hour >= 0 && hour < 24 {
                  hourly[hour].distracted += proportionalMinutes
              }

              // Двигаемся дальше
              t1 = intervalEnd
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

      // DEBUG: Подсчитаем и выведем общее время
      let totalDistractedMinutes = hourly.reduce(0) { $0 + $1.distracted }
      let totalFocusedMinutes = hourly.reduce(0) { $0 + $1.focused }
      print("📊 Chart Debug: Total distracted minutes: \(totalDistractedMinutes) (\(totalDistractedMinutes/60)h \(Int(totalDistractedMinutes) % 60)m)")
      print("📊 Chart Debug: Total focused minutes: \(totalFocusedMinutes) (\(totalFocusedMinutes/60)h \(Int(totalFocusedMinutes) % 60)m)")
      
      // DEBUG: Покажем распределение по часам
      for hour in 0..<24 {
          if hourly[hour].distracted > 0 || hourly[hour].focused > 0 {
              print("📊 Hour \(hour): distracted=\(hourly[hour].distracted)m, focused=\(hourly[hour].focused)m")
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

