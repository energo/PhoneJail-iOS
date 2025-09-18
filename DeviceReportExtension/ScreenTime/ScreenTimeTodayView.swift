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
  var refreshToken = UUID()
  @Environment(\.scenePhase) private var scenePhase

  @State private var context: DeviceActivityReport.Context = .totalActivity
  @State private var filter: DeviceActivityFilter = ScreenTimeTodayView.makeTodayFilter()

  var body: some View {
    DeviceActivityReport(context, filter: filter)
      .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .active {
          refreshToday()
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
        refreshToday()
      }
  }

  private func refreshToday() {
    filter = Self.makeTodayFilter()
    context = .totalActivity
  }

  static func makeTodayFilter() -> DeviceActivityFilter {
    let today = Calendar.current.dateInterval(of: .day, for: Date())!
    return DeviceActivityFilter(
      segment: .daily(during: today),
      users: .all,
      devices: .init([.iPhone])
    )
  }
}
