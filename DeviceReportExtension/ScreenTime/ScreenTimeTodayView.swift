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
  
  @AppStorage(SharedData.ScreenTime.cachedScreenTimeData, store: SharedData.userDefaults) private var cachedDataRaw: Data?
  @AppStorage(SharedData.ScreenTime.screenTimeHasLoadedOnce, store: SharedData.userDefaults) private var hasLoadedOnce = false
  @AppStorage(SharedData.ScreenTime.lastScreenTimeRefresh, store: SharedData.userDefaults) private var lastRefreshTimestamp: Double = 0
  
  @State private var isLoadingFreshData = false
  @State private var refreshID = UUID()
  @State private var showCachedView = false
  
  var id: UUID // внешний идентификатор для сброса
  
  private var cachedData: ScreenTimeCache.CachedData? {
    guard let data = cachedDataRaw,
          let decoded = try? JSONDecoder().decode(ScreenTimeCache.CachedData.self, from: data) else {
      return nil
    }
    return decoded
  }
  
  private var shouldRefreshCache: Bool {
    let fiveMinutes: TimeInterval = 300
    return Date().timeIntervalSince1970 - lastRefreshTimestamp > fiveMinutes
  }
  
  var body: some View {
    ZStack {
      // Always render DeviceActivityReport
      DeviceActivityReport(context, filter: filter)
        .padding(0)
        .id(refreshID)
        .opacity(showCachedView ? 0 : 1)
        .allowsHitTesting(!showCachedView)
        .overlay(
          // Show loading indicator in corner when refreshing
          Group {
            if isLoadingFreshData && cachedData != nil {
              VStack {
                HStack {
                  Spacer()
                  ProgressView()
                    .scaleEffect(0.8)
                    .padding(8)
                }
                Spacer()
              }
            }
          }
        )
      
      // Show cached view on top if needed
      if showCachedView, let cached = cachedData {
        CachedScreenTimeView(cachedData: cached)
      }
      
      // Show loading only if no data at all
      if !hasLoadedOnce && cachedData == nil {
        VStack {
          ProgressView()
            .scaleEffect(1.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
      }
    }
    .onAppear {
      loadCachedData()
      refreshDataInBackground()
    }
    .onChange(of: id) { _ in
      refreshDataInBackground()
    }
  }
  
  private func loadCachedData() {
    // Show cached view if we have data
    if cachedData != nil {
      showCachedView = true
    }
  }
  
  private func refreshDataInBackground() {
    // Check if we should refresh
    let shouldRefresh = cachedData == nil || shouldRefreshCache
    
    if shouldRefresh {
      isLoadingFreshData = true
      refreshID = UUID()
      
      // Update filter to current day
      filter = DeviceActivityFilter(
        segment: .daily(
          during: Calendar.current.dateInterval(of: .day, for: .now)!
        ),
        users: .all,
        devices: .init([.iPhone])
      )
      
      showCachedView = false
      hasLoadedOnce = true
      lastRefreshTimestamp = Date().timeIntervalSince1970
      
      // Stop loading indicator after reasonable time
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        isLoadingFreshData = false
      }
    }
  }
}
