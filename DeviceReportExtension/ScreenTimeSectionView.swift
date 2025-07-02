//
//  ScreenTimeSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct ScreenTimeSectionView: View {
  let report: ActivityReport

  var body: some View {
    VStack(spacing: 0) {
      Text("Screen Time Today")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(.white)

      screenTimeView
      bottomView
    }
    .padding()
  }

  private var bottomView: some View {
    HStack(spacing: 32) {
      // Focus Time (мы не выделяем фокус явно, используем самое долгое использование)
      VStack {
        if let interval = report.longestActivity?.duration {
          Text(Duration.seconds(interval).formatted(.units()))
            .font(.title2)
            .foregroundColor(.white)
        } else {
          Text("—")
            .font(.title2)
            .foregroundColor(.white)
        }

        Text("TIME IN FOCUS")
          .font(.caption)
          .foregroundColor(.white.opacity(0.5))
      }

      VStack {
        HStack(spacing: 8) {
//          ForEach(mostUsedApps.prefix(4)) { app in
//            app.icon
//              .resizable()
//              .frame(width: 24, height: 24)
//              .clipShape(RoundedRectangle(cornerRadius: 8))
//          }
          
          ForEach(report.topApps) { app in
              CardView(app: app, disablePopover: true)
          }
        }

        Text("MOST USED")
          .font(.caption)
          .foregroundColor(.white.opacity(0.5))
      }

      VStack {
        Text("\(report.totalPickupsWithoutApplicationActivity)")
          .font(.title2)
          .foregroundColor(.white)

        Text("PICKUPS")
          .font(.caption)
          .foregroundColor(.white.opacity(0.5))
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
    "\((Int(interval) % 3600) / 60)"
  }

//  private var mostUsedApps: [AppIcon] {
//    report.apps
//      .sorted { $0.durationInterval > $1.durationInterval }
//      .prefix(4)
//      .map { app in
//        AppIcon(name: app.displayName, icon: Image(systemName: "app.fill")) // TODO: заменить на реальные иконки при наличии
//      }
//  }
}


//struct ScreenTimeSectionView: View {
//  let totalTime: TimeInterval
//  let focusTime: TimeInterval
//  let pickups: Int
//  let mostUsedApps: [AppIcon] // AppIcon: структура с названием и иконкой
//  
//  var body: some View {
//    VStack(spacing: 0) {
//      Text("Screen Time Today")
//        .font(.system(size: 18, weight: .medium))
//        .foregroundColor(.white)
//      
//      screenTimeView
//      bottomView
//    }
//    .padding()
//  }
//  
//  private var bottomView: some View {
//    HStack(spacing: 32) {
//      VStack {
//        Text(timeString(from: focusTime))
//          .font(.title2)
//          .foregroundColor(.white)
//        
//        Text("TIME IN FOCUS")
//          .font(.caption)
//          .foregroundColor(.white.opacity(0.5))
//      }
//      
//      VStack {
//        HStack(spacing: 8) {
//          ForEach(mostUsedApps) { app in
//            app.icon
//              .resizable()
//              .frame(width: 24, height: 24)
//              .clipShape(RoundedRectangle(cornerRadius: 8))
//          }
//        }
//        .foregroundColor(.white)
//        
//        Text("MOST USED")
//          .font(.caption)
//          .foregroundColor(.white.opacity(0.5))
//      }
//      
//      
//      VStack {
//        Text("\(pickups)")
//          .font(.title2)
//          .foregroundColor(.white)
//        
//        Text("PICKUPS")
//          .font(.caption)
//          .foregroundColor(.white.opacity(0.5))
//      }
//    }
//  }
//  
//  private var screenTimeView: some View  {
//    HStack {
//      VStack(spacing: 0) {
//        Text(hoursString(from: totalTime))
//          .font(.system(size: 144, weight: .heavy, design: .rounded))
//          .foregroundStyle(Color.as_gradietn_time_text)
//        Text("HOURS")
//          .font(.system(size: 11, weight: .medium))
//          .foregroundColor(.white.opacity(0.5))
//          .offset(y: -30)
//      }
//      
//      VStack(spacing: 0) {
//        Text(minutesString(from: totalTime))
//          .font(.system(size: 144, weight: .heavy, design: .rounded))
//          .foregroundStyle(Color.as_gradietn_time_text)
//        Text("MINUTES")
//          .font(.system(size: 11, weight: .medium))
//          .foregroundColor(.white.opacity(0.5))
//          .offset(y: -30)
//      }
//    }
//  }
//  
//  private func hoursString(from interval: TimeInterval) -> String {
//    let hours = Int(interval) / 3600
//    return "\(hours)"
//  }
//  
//  private func minutesString(from interval: TimeInterval) -> String {
//    let minutes = (Int(interval) % 3600) / 60
//    return "\(minutes)"
//  }
//  
//  private func timeString(from interval: TimeInterval) -> String {
//    // Преобразование в часы и минуты
//    let hours = Int(interval) / 3600
//    let minutes = (Int(interval) % 3600) / 60
//    return "\(hours)h \(minutes)m"
//  }
//}
