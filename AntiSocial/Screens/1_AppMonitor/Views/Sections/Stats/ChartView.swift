//
//  ChartView.swift
//  AntiSocial
//
//  Created by D C on 04.07.2025.
//

import SwiftUI
import Charts

struct ChartView: View {
  let chartData: [ChartBar]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Chart {
        ForEach(safechartData()) { bar in
          let total = bar.focusedMinutes + bar.distractedMinutes
          
          if total > 0 {
            let cappedTotal = min(60, total)
            let cappedFocused = min(bar.focusedMinutes, cappedTotal)
            let cappedDistracted = max(0, cappedTotal - cappedFocused)
            
            // Distracted bar (нижняя часть)
            BarMark(
              x: .value("Hour", bar.hour),
              yStart: .value("Start", 0),
              yEnd: .value("Distracted", cappedDistracted)
            )
            .foregroundStyle(.pink)
            
            // Focused bar (верхняя часть)
            BarMark(
              x: .value("Hour", bar.hour),
              yStart: .value("Start", cappedDistracted),
              yEnd: .value("Total", cappedDistracted + cappedFocused)
            )
            .foregroundStyle(.green)
          } else {
            // Пустой бар
            BarMark(
              x: .value("Hour", bar.hour),
              y: .value("Empty", 1)
            )
            .foregroundStyle(.gray.opacity(0.15))
          }
        }
      }
      .chartXScale(domain: 0...23)
      .chartYScale(domain: 0...60)
      .chartYAxis {
        AxisMarks(position: .trailing, values: [0, 30, 60]) { value in
          AxisGridLine()
            .foregroundStyle(Color.white.opacity(0.2))
          AxisValueLabel {
            if let intValue = value.as(Int.self) {
              Text("\(intValue)m")
                .foregroundStyle(Color.as_gray)
            }
          }
        }
      }
      .chartXAxis {
        AxisMarks(values: [0, 6, 12, 18, 24]) { value in
          AxisValueLabel {
            if let hour = value.as(Int.self) {
              Text(hourLabel(for: hour))
                .foregroundStyle(Color.as_gray)
            }
          }
        }
      }
      .frame(height: 112)
      .animation(.easeInOut(duration: 0.8), value: chartData)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 12)
  }
  
  private func safechartData() -> [ChartBar] {
    let safeChartData: [ChartBar] = chartData.count == 24
    ? chartData
    : (0..<24).map { hour in
      chartData.first(where: { $0.hour == hour }) ?? ChartBar(hour: hour, focusedMinutes: 0, distractedMinutes: 0)
    }
    
    return safeChartData
  }
  
  private func hourLabel(for hour: Int) -> String {
    switch hour {
      case 0, 24: return "12am"
      case 6: return "6am"
      case 12: return "12pm"
      case 18: return "6pm"
      default: return ""
    }
  }
}

//#Preview {
//  let sampleData = (0..<24).map { ChartBar(hour: $0,
//                                           focusedMinutes: Int.random(in: 0...60),
//                                           distractedMinutes: Int.random(in: 0...60)) }
//  ChartView(chartData: sampleData)
//  //    .previewLayout(.sizeThatFits)
//    .padding()
//}
