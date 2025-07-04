//
//  DeviceReportExtension.swift
//  DeviceReportExtension
//
//  Created by D C on 01.07.2025.
//

import DeviceActivity
import SwiftUI

@main
struct DeviceReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
//          TotalActivityView(activityReport: totalActivity)
          ScreenTimeSectionView(report: totalActivity)
        }
      
        // Новый отчёт для статистики
        StatsActivityReport { statsActivity in
          StatsSectionView(stats: statsActivity)
        }
    }
}
