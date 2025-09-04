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
    segment: .daily(
      during: Calendar.current.dateInterval(of: .day, for: .now)!
    ),
    users: .all,
    devices: .init([.iPhone])
  )
  
  // Cache management
  @AppStorage(SharedData.ScreenTime.lastScreenTimeRefresh, store: SharedData.userDefaults) private var lastRefreshTimestamp: Double = 0
  
  @State private var refreshID = UUID()
  @State private var isFirstLoad = true
  
  
  private var shouldRefreshCache: Bool {
    let fiveMinutes: TimeInterval = 300
    return Date().timeIntervalSince1970 - lastRefreshTimestamp > fiveMinutes
  }
  
  var body: some View {
    ZStack {
      
      // Show loading indicator only on first load without cache
      if isFirstLoad {
        VStack {
          ProgressView()
            .scaleEffect(1.5)
            .tint(.white)
          
          Text("Loading Screen Time...")
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      
      DeviceActivityReport(context, filter: filter)
        .padding(0)
        .id(refreshID)
        .onAppear {
          handleOnAppear()
        }

    }
  }
  
  private func handleOnAppear() {
    // Check if this is the first time loading
//    if !hasLoadedOnce {
//      isFirstLoad = true
//      hasLoadedOnce = true
//    } else {
//      isFirstLoad = false
//    }
    
    isFirstLoad = false

    // Refresh if needed
    if shouldRefreshCache {
      refreshReport()
    }
  }
  
  private func forceRefresh() {
    refreshReport()
  }
  
  private func refreshReport() {
    // Update the filter to ensure we're getting today's data
    filter = DeviceActivityFilter(
      segment: .daily(
        during: Calendar.current.dateInterval(of: .day, for: .now)!
      ),
      users: .all,
      devices: .init([.iPhone])
    )
    
    // Trigger report refresh
    refreshID = UUID()
    lastRefreshTimestamp = Date().timeIntervalSince1970
    
    // After a delay, mark as loaded
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      isFirstLoad = false
    }
  }
}
