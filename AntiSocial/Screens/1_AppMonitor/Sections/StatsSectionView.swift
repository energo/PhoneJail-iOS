//
//  StatsSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct StatsSectionView: View {
    let stats: StatsData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stats")
                .font(.title2).bold()
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text(stats.totalDuration.formattedAsHoursMinutes())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)

                Text("TODAY, " + Date().formatted(.dateTime.month(.wide).day().year()))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            ChartView(chartData: stats.chartData)
                .frame(height: 160)

            HStack {
                PercentageView(label: "FOCUSED", value: stats.focusedPercent, color: .green)
                Spacer()
                PercentageView(label: "DISTRACTED", value: stats.distractedPercent, color: .blue)
            }

            ForEach(stats.appUsages) { app in
                HStack {
                    Image(uiImage: app.icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(app.name)
                        .foregroundStyle(.white)

                    Spacer()

                    Text(app.usage.formattedAsHoursMinutes())
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
        .background(bgBlur)
    }
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 32)
        .fill(
          Color.white.opacity(0.07)
        )
    }
  }
}

// Supporting views
struct PercentageView: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)%")
                .foregroundStyle(color)
                .font(.headline)
            Text(label)
                .foregroundStyle(.gray)
                .font(.caption)
        }
    }
}

extension TimeInterval {
    func formattedAsHoursMinutes() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? "0m"
    }
}

// Stub ChartView
struct ChartView: View {
    let chartData: [ChartBar]

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(chartData) { bar in
                VStack {
                    Capsule()
                        .fill(Color.green)
                        .frame(height: CGFloat(bar.focusedMinutes))
                    Capsule()
                        .fill(Color.pink)
                        .frame(height: CGFloat(bar.distractedMinutes))
                }
                .frame(width: 6)
            }
        }
    }
}

//struct StatsSectionView: View {
//  let stats: StatsData // структура с данными по времени, графиком, списком приложений
//  
//  var body: some View {
//    VStack(alignment: .leading, spacing: 16) {
//      HStack {
//        Text("Stats")
//          .font(.headline)
//          .foregroundStyle(Color.white)
//
//        Spacer()
//        
//        Text(stats.focusedLifetimeString)
//          .font(.subheadline)
//          .foregroundColor(.green)
//      }
//      
//      //            ActivityBarChartView(data: stats.chartData)
//      //                .frame(height: 120)
//      //            HStack {
//      //                StatPercentView(title: "FOCUSED", percent: stats.focusedPercent, color: .green)
//      //                StatPercentView(title: "DISTRACTED", percent: stats.distractedPercent, color: .pink)
//      //                StatPercentView(title: "OFFLINE", percent: stats.offlinePercent, color: .gray)
//      //            }
//      ForEach(stats.appUsages) { app in
//        HStack {
//          Image(uiImage: app.icon)
//            .resizable()
//            .frame(width: 24, height: 24)
//            .clipShape(RoundedRectangle(cornerRadius: 6))
//          Text(app.name)
//            .foregroundStyle(Color.white)
//          Spacer()
//          Text(app.usageString)
//            .foregroundStyle(Color.white)
//        }
//      }
//    }
//    .padding()
//    .background(bgBlur)
//  }
//  
//  private var bgBlur: some View {
//    ZStack {
//      BackdropBlurView(isBlack: false, radius: 10)
//      RoundedRectangle(cornerRadius: 32)
//        .fill(
//          Color.white.opacity(0.07)
//        )
//    }
//  }
//  
//}
