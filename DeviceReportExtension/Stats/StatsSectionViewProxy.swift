//
//  ScreenTimeTodayView.swift
//  AntiSocial
//
//  Created by D C on 04.07.2025.
//


import SwiftUI
import DeviceActivity
// 1. Контекст
extension DeviceActivityReport.Context {
  static let statsActivity = Self("Stats Activity")
}

struct StatsSectionViewProxy: View {
  @State private var context: DeviceActivityReport.Context = .statsActivity
  
  @State private var filter = DeviceActivityFilter(
    segment: .daily(
      during: Calendar.current.dateInterval(of: .day, for: .distantPast)!
    ),
    users: .all,
    devices: .init([.iPhone])
  )
  
  var body: some View {
    VStack {
      DeviceActivityReport(context)
        .padding(0) // Убираем системные отступы
      //        .frame(height: 40)
      //        .frame(width: 70)
    }
  }
}
