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
    .padding(.horizontal, 32)
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
        HStack(spacing: 0) {
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
    let minutes = (Int(interval) % 3600) / 60
    return String(format: "%02d", minutes)
  }
}
