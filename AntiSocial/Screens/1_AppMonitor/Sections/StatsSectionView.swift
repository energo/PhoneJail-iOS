//
//  StatsSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct StatsSectionView: View {
  let stats: StatsData // структура с данными по времени, графиком, списком приложений
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Stats")
          .font(.headline)
          .foregroundStyle(Color.white)

        Spacer()
        
        Text(stats.focusedLifetimeString)
          .font(.subheadline)
          .foregroundColor(.green)
      }
      
      //            ActivityBarChartView(data: stats.chartData)
      //                .frame(height: 120)
      //            HStack {
      //                StatPercentView(title: "FOCUSED", percent: stats.focusedPercent, color: .green)
      //                StatPercentView(title: "DISTRACTED", percent: stats.distractedPercent, color: .pink)
      //                StatPercentView(title: "OFFLINE", percent: stats.offlinePercent, color: .gray)
      //            }
      ForEach(stats.appUsages) { app in
        HStack {
          Image(uiImage: app.icon)
            .resizable()
            .frame(width: 24, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 6))
          Text(app.name)
            .foregroundStyle(Color.white)
          Spacer()
          Text(app.usageString)
            .foregroundStyle(Color.white)
        }
      }
    }
    .padding()
    .background(bgBlur)
  }
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 20)
        .fill(
          Color.white.opacity(0.07)
        )
    }
  }
  
}
