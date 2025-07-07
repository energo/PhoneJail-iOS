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

      
      ScrollView() {
//        VStack(spacing: 8) {
//          Text(stats.totalDuration.formattedAsHoursMinutes())
//            .font(.system(size: 32, weight: .bold))
//            .foregroundStyle(.white)
          
//          Text("TODAY, " + Date().formatted(.dateTime.month(.wide).day().year()))
//            .font(.caption)
//            .foregroundStyle(.gray)
//        }
        
        ChartView(chartData: stats.chartData)
          .frame(height: 160)
        
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
//    .padding()
//    .background(bgBlur)
    .onAppear {
      focusedTime = FocusedTimeStatsStore.shared.getTotalFocusedTime(for: Date())
    }
  }
  
//  private var bgBlur: some View {
//    ZStack {
//      BackdropBlurView(isBlack: false, radius: 10)
//      RoundedRectangle(cornerRadius: 32)
//        .fill(
//          Color.white.opacity(0.07)
//        )
//    }
//  }
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
