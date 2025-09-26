import SwiftUI
import DeviceActivity
import ManagedSettings
import Foundation

struct StatsSectionView: View {
  
  let stats: StatsData
  private let adaptive = AdaptiveValues.current
  
  var body: some View {
    VStack(alignment: .center, spacing: adaptive.spacing.medium) {
      Text(stats.totalDuration.formattedAsHoursMinutes())
        .adaptiveFont(\.title1)
        .fontWeight(.bold)
        .foregroundStyle(.white)
      
      ChartView(chartData: stats.chartData)
      
      HStack {
        PercentageView(label: "FOCUSED", value: stats.focusedPercent, color: .green)
        Spacer()
        PercentageView(label: "DISTRACTED", value: stats.distractedPercent, color: .blue)
        Spacer()
        PercentageView(label: "OFFLINE", value: stats.offlinePercent, color: .blue)
      }
      
      ScrollView() {
        ForEach(stats.appUsages) { app in
          HStack {
            Label(app.token)
              .labelStyle(.iconOnly)
              .adaptiveFrame(width: \.appIconSize, height: \.appIconSize)
            
            Text(app.name)
              .adaptiveFont(\.body)
              .fontWeight(.medium)
              .foregroundStyle(.white)
            
            Spacer()
            
            Text(app.usage.formattedAsHoursMinutes())
              .adaptiveFont(\.body)
              .foregroundStyle(.white)
          }
        }
      }
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
