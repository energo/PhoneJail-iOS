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
        // гарантируем, что всегда 24 элемента от 0 до 23
        let safeChartData: [ChartBar] = chartData.count == 24
            ? chartData
            : (0..<24).map { hour in
                chartData.first(where: { $0.hour == hour }) ?? ChartBar(hour: hour, focusedMinutes: 0, distractedMinutes: 0)
            }

        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(safeChartData) { bar in
                    let total = bar.focusedMinutes + bar.distractedMinutes

                    if total > 0 {
                        // Focused bar (нижняя часть)
                        BarMark(
                            x: .value("Hour", bar.hour),
                            yStart: .value("Start", 0),
                            yEnd: .value("Focused", bar.focusedMinutes)
                        )
                        .foregroundStyle(.green)

                        // Distracted bar (верхняя часть)
                        BarMark(
                            x: .value("Hour", bar.hour),
                            yStart: .value("Start", bar.focusedMinutes),
                            yEnd: .value("Total", total)
                        )
                        .foregroundStyle(.pink)
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
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 30, 60]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)m")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(hourLabel(for: hour))
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(.horizontal, 12)
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


#Preview {
    let sampleData = (0..<24).map { ChartBar(hour: $0,
                                             focusedMinutes: Int.random(in: 0...60),
                                             distractedMinutes: Int.random(in: 0...60)) }
    ChartView(chartData: sampleData)
        .previewLayout(.sizeThatFits)
        .padding()
}
