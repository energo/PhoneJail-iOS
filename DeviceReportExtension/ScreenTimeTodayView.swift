//
//  ScreenTimeTodayView.swift
//  AntiSocial
//
//  Created by D C on 01.07.2025.
//


import SwiftUI
import DeviceActivity

struct ScreenTimeTodayView: View {
    @State private var context: DeviceActivityReport.Context = .init(rawValue: "Total Activity")
    @State private var filter = DeviceActivityFilter(
        segment: .daily(
            during: Calendar.current.dateInterval(of: .day, for: .now)!
        ),
        users: .all,
        devices: .init([.iPhone])
    )

    var body: some View {
      DeviceActivityReport(context, filter: filter)
        .padding(0) // Убираем системные отступы
//        .frame(height: 40)
//        .frame(width: 70)
    }
}
