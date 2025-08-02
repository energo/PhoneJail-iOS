//
//  ScreenTimeSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI



struct ScreenTimeSectionView: View {
  let report: ActivityReport
  @State private var totalBlockingTime: TimeInterval = 0
  
  var body: some View {
    VStack(spacing: 0) {
      Text("Screen Time Today")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(.white)
      
      screenTimeView
      bottomView
      
      Spacer()
    }
    .padding()
    .padding(.horizontal, 32)
    .onAppear {
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
    return groupDefaults?.double(forKey: SharedData.AppBlocking.todayTotalBlockingTime) ?? 0
  }
  
  private var bottomView: some View {
    HStack(spacing: 32) {
      // Time Blocked (время в фокусе = время блокировок)
      VStack {
        if totalBlockingTime > 0 {
          Text(totalBlockingTime.formatedDuration())
            .font(.title2)
            .foregroundColor(.white)
        } else {
          Text("—")
            .font(.title2)
            .foregroundColor(.white)
        }

        Text("TIME IN FOCUS")
          .font(.caption)
          .foregroundColor(.as_gray_light)
      }
      
      VStack {
        HStack(spacing: 0) {
          ForEach(report.topApps) { app in
            CardView(app: app, disablePopover: true)
          }
        }
        
        Text("MOST USED")
          .font(.system(size: 11, weight: .regular))
          .foregroundColor(.as_gray_light)
      }
      
      VStack {
        Text("\(report.totalPickupsWithoutApplicationActivity)")
          .font(.title2)
          .foregroundColor(.white)
        
        Text("PICKUPS")
          .font(.system(size: 11, weight: .regular))
          .foregroundColor(.as_gray_light)
      }
    }
  }
  
  private var screenTimeView: some View {
    HStack {
      VStack(spacing: 0) {
        Text(hoursString(from: report.totalDuration))
          .font(.system(size: 144, weight: .heavy, design: .rounded))
          .foregroundStyle(Color.as_gradietn_time_text)
        
        Text("HOURS")
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(.white.opacity(0.5))
          .offset(y: -30)
      }
      
      VStack(spacing: 0) {
        Text(minutesString(from: report.totalDuration))
          .font(.system(size: 144, weight: .heavy, design: .rounded))
          .foregroundStyle(Color.as_gradietn_time_text)
        
        Text("MINUTES")
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(.white.opacity(0.5))
          .offset(y: -30)
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
