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
            Text("Stats")
                .font(.headline)
            Text(stats.focusedLifetimeString)
                .font(.subheadline)
                .foregroundColor(.green)
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
                    Spacer()
                    Text(app.usageString)
                }
            }
        }
        .padding()
    }
}
