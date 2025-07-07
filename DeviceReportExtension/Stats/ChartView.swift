//
//  ChartView.swift
//  AntiSocial
//
//  Created by D C on 04.07.2025.
//

import SwiftUI

struct ChartView: View {
    let chartData: [ChartBar] // assumed to be 24 items, index == hour
    private let maxMinutes: CGFloat = 60
    private let barWidth: CGFloat = 8
    private let barSpacing: CGFloat = 2
    private let chartHeight: CGFloat = 100

    var body: some View {
        VStack(spacing: 6) {
            // Бары
            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(0..<24, id: \.self) { hour in
                    let bar = chartData[hour]
                    let total = CGFloat(bar.focusedMinutes + bar.distractedMinutes)
                    let totalHeight = chartHeight * total / maxMinutes
                    let focusedHeight = totalHeight * CGFloat(bar.focusedMinutes) / max(total, 1)
                    let distractedHeight = totalHeight * CGFloat(bar.distractedMinutes) / max(total, 1)

                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color.green.opacity(bar.focusedMinutes > 0 ? 1 : 0.2))
                            .frame(height: focusedHeight)
                        Capsule()
                            .fill(Color.pink.opacity(bar.distractedMinutes > 0 ? 1 : 0.2))
                            .frame(height: distractedHeight)
                        Spacer(minLength: chartHeight - totalHeight)
                    }
                    .frame(width: barWidth, height: chartHeight, alignment: .bottom)
                }
            }

            // Лейблы времени
            HStack {
                ForEach([0, 6, 12, 18, 24], id: \.self) { hour in
                    Text(timeLabel(for: hour))
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            // Y-ось
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    Text("1h").font(.caption2)
                    Spacer()
                    Text("30m").font(.caption2)
                    Spacer()
                    Text("0").font(.caption2)
                }
                .frame(height: chartHeight)
                .padding(.trailing, 4)
            }
        }
        .frame(height: chartHeight + 40)
    }

    private func timeLabel(for hour: Int) -> String {
        switch hour {
        case 0, 24: return "12am"
        case 6: return "6am"
        case 12: return "12pm"
        case 18: return "6pm"
        default: return ""
        }
    }
}

