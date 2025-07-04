import SwiftUI
import DeviceActivity
import ManagedSettings

struct StatsSectionView: View {
  let stats: StatsData
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Stats")
        .font(.title2).bold()
        .foregroundStyle(.white)
      
      ScrollView() {
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

struct StatsData {
  let totalDuration: TimeInterval
  let chartData: [ChartBar]
  let focusedDuration: TimeInterval
  let distractedDuration: TimeInterval
  let appUsages: [AppUsage]
  var focusedPercent: Int {
    totalDuration > 0 ? Int((focusedDuration / totalDuration) * 100) : 0
  }
  var distractedPercent: Int {
    totalDuration > 0 ? Int((distractedDuration / totalDuration) * 100) : 0
  }
}

struct AppUsage: Identifiable {
  let id = UUID()
  let name: String
  var token: ApplicationToken
  let usage: TimeInterval
  
  var usageString: String {
    let hours = Int(usage) / 3600
    let minutes = (Int(usage) % 3600) / 60
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
}

//struct ChartBar: Identifiable {
//  let id = UUID()
//  let hour: Int
//  var focusedMinutes: Int
//  var distractedMinutes: Int
//}

extension TimeInterval {
  func formattedAsHoursMinutes() -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .pad
    return formatter.string(from: self) ?? "0m"
  }
}
