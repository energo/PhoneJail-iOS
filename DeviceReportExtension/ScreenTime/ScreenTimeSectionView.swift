////
////  ScreenTimeSectionView.swift
////  AntiSocial
////
////  Created by D C on 26.06.2025.
////
//
import SwiftUI
import Foundation
import ManagedSettings

private struct AppIconView: View {
  let token: ApplicationToken
  
  var body: some View {
    Label(token)
      .labelStyle(.iconOnly)
      .frame(width: 24, height: 24)
  }
}

struct ScreenTimeSectionView: View {
  let report: ActivityReport
  @State private var totalBlockingTime: TimeInterval = 0
  private let adaptive = AdaptiveValues.current
  
  var body: some View {
    VStack(spacing: 0) {
      Text("Screen Time Today")
        .adaptiveFont(\.title3)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .adaptivePadding(\.xSmall)
      
      screenTimeView
      bottomView
    }
    .task {
      loadBlockingStats()
    }
  }
  
  // MARK: - Data Loading
  
  private func loadBlockingStats() {
    // Загружаем статистику блокировок через единый API (временное решение)
    // TODO: Мигрировать на полноценный AppBlockingLogger когда расширение поддержит shared frameworks
    totalBlockingTime = Self.getTodayTotalBlockingTimeFromSharedData()
  }
  
  // MARK: - Temporary API (uses same keys as AppBlockingLogger)
  
  /// Временная функция для получения данных из SharedData (использует те же ключи что и AppBlockingLogger)
  private static func getTodayTotalBlockingTimeFromSharedData() -> TimeInterval {
    let groupDefaults = SharedData.userDefaults
    let completedTime = groupDefaults?.double(forKey: SharedData.AppBlocking.todayTotalBlockingTime) ?? 0
    
    // Добавляем время из активных сессий
    let activeTime = getActiveSessionsTime()
    
    return completedTime + activeTime
  }
  
  /// Получить время из активных сессий блокировки
  private static func getActiveSessionsTime() -> TimeInterval {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    // Получаем сессии за сегодня
    let sessions = SharedData.getBlockingSessions(for: today)
    
    // Считаем время только для активных сессий (где endTime == nil)
    var activeTime: TimeInterval = 0
    for session in sessions {
      if session.endTime == nil {
        // Активная сессия - считаем время от начала до текущего момента
        activeTime += Date().timeIntervalSince(session.startTime)
      }
    }
    
    return activeTime
  }
  
  private var bottomView: some View {
    HStack(spacing: adaptive.spacing.xLarge) {
      // Time Blocked (время в фокусе = время блокировок)
      VStack(spacing: adaptive.spacing.xxSmall) {
        Group {
          if totalBlockingTime > 0 {
            Text(totalBlockingTime.formatedDuration())
          } else {
            Text("—")
          }
        }
        .adaptiveFont(\.statsValue)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        
        Text("TIME IN FOCUS")
          .adaptiveFont(\.statsLabel)
          .foregroundColor(.as_gray_light)
      }
      
      VStack(spacing: adaptive.spacing.xxSmall) {
        if report.topApps.count > 0 {
          HStack(spacing: -adaptive.spacing.xSmall) {
            ForEach(report.topApps.prefix(AdaptiveValues.isCompactDevice ? 2 : 3)) { app in
              AppIconView(token: app.token)
                .adaptiveFrame(width: \.appIconSize, height: \.appIconSize)
            }
          }
        } else {
          Spacer()
            .adaptiveFrame(width: \.appIconSize, height: \.appIconSize)
        }
        
        Text("MOST USED")
          .adaptiveFont(\.statsLabel)
          .foregroundColor(.as_gray_light)
      }
      
      VStack(spacing: adaptive.spacing.xxSmall) {
        Text("\(report.totalPickupsWithoutApplicationActivity)")
          .adaptiveFont(\.statsValue)
          .fontWeight(.semibold)
          .foregroundColor(.white)
        
        Text("PICKUPS")
          .adaptiveFont(\.statsLabel)
          .foregroundColor(.as_gray_light)
      }
    }
  }
  
  private var screenTimeView: some View {
    HStack(spacing: adaptive.spacing.xSmall) {
      VStack(spacing: 0) {
        Text(hoursString(from: report.totalDuration))
          .font(.system(size: adaptive.typography.screenTimeDisplay,
                        weight: .heavy,
                        design: .rounded))
          .foregroundStyle(Color.as_gradietn_time_text)
          .minimumScaleFactor(0.8)
          .lineLimit(1)
        
        Text("HOURS")
          .adaptiveFont(\.caption2)
          .fontWeight(.medium)
          .foregroundColor(.white.opacity(0.5))
          .offset(y: AdaptiveValues.isCompactDevice ? -20 : -20)
      }
      
      VStack(spacing: 0) {
        Text(minutesString(from: report.totalDuration))
          .font(.system(size: adaptive.typography.screenTimeDisplay,
                        weight: .heavy,
                        design: .rounded))
          .foregroundStyle(Color.as_gradietn_time_text)
          .minimumScaleFactor(0.8)
          .lineLimit(1)
        
        Text("MINUTES")
          .adaptiveFont(\.caption2)
          .fontWeight(.medium)
          .foregroundColor(.white.opacity(0.5))
          .offset(y: AdaptiveValues.isCompactDevice ? -20 : -20)
      }
    }
  }
  
  // MARK: - Преобразования
  private func hoursString(from interval: TimeInterval) -> String {
    "\(Int(interval) / 3600)"
  }
  
  private func minutesString(from interval: TimeInterval) -> String {
    let minutes = (Int(interval) % 3600) / 60
    return String(format: "%02d", minutes)
  }
}
