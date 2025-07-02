//
//  TotalActivityView.swift
//  DeviceReportExtension
//
//  Created by D C on 01.07.2025.
//

import SwiftUI


struct AppIcon: Identifiable {
  var id: String { name }
  let name: String
  let icon: Image
}

struct TotalActivityView: View {
  var activityReport: ActivityReport

  var body: some View {
    ScreenTimeSectionView(report: activityReport)
  }
}


//struct TotalActivityView: View {
//  var activityReport: String
//
//  var body: some View {
//    VStack(spacing: 8) {
//      Text("Screen time")
//        .font(.system(size: 10, weight: .regular))
//        .foregroundColor(.white)
//        .padding(0) // Важно!
//
//      
//      Text("\(totalTimeFormatted)")
//        .font(.system(size: 16, weight: .bold))
//        .foregroundStyle(Color.white)
//        .padding(0) // Важно!
//
//    }
//    .padding(0) // Важно!
//  }
//  
//  private var totalTimeInSeconds: TimeInterval {
//    activityReport
//      .split(separator: "\n")
//      .compactMap { line in
//        let parts = line.split(separator: ",")
//        guard parts.count == 2 else { return nil }
//        let time = parts[1].replacingOccurrences(of: "Time:", with: "")
//        return timeStringToSeconds(time)
//      }
//      .reduce(0, +)
//  }
//
//  private var totalTimeFormatted: String {
//    let hours = Int(totalTimeInSeconds) / 3600
//    let minutes = (Int(totalTimeInSeconds) % 3600) / 60
//    return "\(hours)h \(minutes)m"
//  }
//
//  private func timeStringToSeconds(_ timeString: String) -> TimeInterval {
//    var totalSeconds: TimeInterval = 0
//    let components = timeString.split(separator: " ")
//    for component in components {
//      if component.hasSuffix("h"), let hours = Double(component.dropLast()) {
//        totalSeconds += hours * 3600
//      } else if component.hasSuffix("m"), let minutes = Double(component.dropLast()) {
//        totalSeconds += minutes * 60
//      } else if component.hasSuffix("s"), let seconds = Double(component.dropLast()) {
//        totalSeconds += seconds
//      }
//    }
//    return totalSeconds
//  }
//}
//
//// In order to support previews for your extension's custom views, make sure its source files are
//// members of your app's Xcode target as well as members of your extension's target. You can use
//// Xcode's File Inspector to modify a file's Target Membership.
//#Preview {
//  TotalActivityView(activityReport: "1h 23m")
//}
