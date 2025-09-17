//
//  ScreenTimeTodayView.swift
//  AntiSocial
//
//  Created by D C on 01.07.2025.
//

import SwiftUI
import DeviceActivity

extension DeviceActivityReport.Context {
  static let totalActivity = Self("Total Activity")
}

struct ScreenTimeTodayView: View {
  @State private var context: DeviceActivityReport.Context = .totalActivity
  @State private var filter = DeviceActivityFilter(
    segment: .daily(during: Calendar.current.dateInterval(of: .day, for: .now)!),
    users: .all,
    devices: .init([.iPhone])
  )
  

  var body: some View {
    DeviceActivityReport(context, filter: filter)
  }

  //  @State private var showSpinner = true
  //  var minShowTime: Double = 0.5

//  var body: some View {
//    ZStack {
//      if showSpinner {
//        VStack(spacing: 32) {
//          ProgressView().scaleEffect(1.6)
//          Text("Loading Screen Time…")
//            .font(.caption)
//            .foregroundColor(.secondary)
//        }
//        .transition(.opacity)
//        .allowsHitTesting(false)
//      }
//      
//       сам отчёт
//      DeviceActivityReport(context, filter: filter)
//    }
//    .task {
//      // гарантированно показываем на minShowTime и прячем
//      showSpinner = true
//      try? await Task.sleep(nanoseconds: UInt64(minShowTime * 1_000_000_000))
//      withAnimation(.easeOut(duration: 0.25)) { showSpinner = false }
//    }
//  }
  
}
