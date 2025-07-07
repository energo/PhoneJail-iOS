import SwiftUI
import DeviceActivity
import ManagedSettings
import Foundation

struct StatsSectionView: View {
  let stats: StatsData
  
  // Новый блок: загрузка Focused Time
  @State private var focusedTime: TimeInterval = 0
  
  var body: some View {
    VStack(alignment: .center, spacing: 16) {
      //      Text("Stats")
      //        .font(.title2).bold()
      //        .foregroundStyle(.white)
      Text(stats.totalDuration.formattedAsHoursMinutes())
        .font(.system(size: 32, weight: .bold))
        .foregroundStyle(.white)
      
      
        
        ChartView(chartData: stats.chartData)
        
        HStack {
          PercentageView(label: "FOCUSED", value: stats.focusedPercent, color: .green)
          Spacer()
          PercentageView(label: "DISTRACTED", value: stats.distractedPercent, color: .blue)
          Spacer()
          PercentageView(label: "OFFLINE", value: stats.offlinePercent, color: .blue)
        }
        
        // Новый блок: отображение Focused Time
        //TODO: FOR TESTING
        HStack {
          Text("Focused Time (all apps):")
            .foregroundStyle(.white)
          Spacer()
          Text(focusedTime.formattedAsHoursMinutes())
            .foregroundStyle(.green)
        }
        .padding(.vertical, 8)
        
      ScrollView() {
        ForEach(stats.appUsages) { app in
          HStack {
            Label(app.token)
              .labelStyle(.iconOnly)
              .frame(width: 30, height: 30)
            
            Text(app.name)
              .foregroundStyle(.white)
            
            Spacer()
            
            Text(app.usage.formattedAsHoursMinutes())
              .foregroundStyle(.white)
          }
        }
      }
    }
    .onAppear {
      focusedTime = FocusedTimeStatsStore.shared.getTotalFocusedTime(for: Date())
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
