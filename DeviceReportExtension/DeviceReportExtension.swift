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
    
    TotalActivityReport { totalActivity in
      ScreenTimeSectionView(report: totalActivity)
    }
    
    // Новый отчёт для статистики
    StatsActivityReport { statsActivity in
      StatsSectionView(stats: statsActivity)
    }
  }
}
