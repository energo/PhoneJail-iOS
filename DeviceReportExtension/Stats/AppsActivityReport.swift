//
//  AppsActivityReport.swift
//  DeviceReportExtension
//


import SwiftUI
import DeviceActivity
import ManagedSettings

private actor AppsCache {
  static let shared = AppsCache()
  
  private var cache: [String: CachedAppsData] = [:]
  private let cacheLifetime: TimeInterval = 60 
  private let maxCacheSize = 7
  
  private struct CachedAppsData {
    let data: AppsReportData
    let timestamp: Date
  }
  
  func get(for date: Date) -> AppsReportData? {
    let key = cacheKey(for: date)
    guard let cached = cache[key] else { return nil }
    
    if Date().timeIntervalSince(cached.timestamp) > cacheLifetime  {
      cache.removeValue(forKey: key)
      return nil
    }
    
    return cached.data
  }
  
  func set(_ data: AppsReportData, segmentCount: Int, for date: Date) {
    let key = cacheKey(for: date)
    
    performCleanupIfNeeded()
    
    cache[key] = CachedAppsData(
      data: data,
      timestamp: Date(),
    )
  }
  
  // Получение ключа для даты
  private func cacheKey(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: date)
  }
  
  private func performCleanupIfNeeded() {
    guard cache.count >= maxCacheSize else { return }
    
    let sortedKeys = cache
      .sorted { $0.value.timestamp < $1.value.timestamp }
      .map { $0.key }
    
    let keysToRemove = sortedKeys.prefix(cache.count - maxCacheSize + 1)
    for key in keysToRemove {
      cache.removeValue(forKey: key)
    }
  }
  
  func clearAll() {
    cache.removeAll()
  }
  
  func clearExpired() {
    cache = cache.filter { _, value in
      Date().timeIntervalSince(value.timestamp) <= cacheLifetime
    }
  }
  
}

struct AppsActivityReport: DeviceActivityReportScene {
  
  let context: DeviceActivityReport.Context = .appsActivity
  let content: (AppsReportData) -> AppUsageSectionView
  
  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> AppsReportData {
    
    var reportDate: Date? = nil
    var segmentCount = 0
    
    for await d in data {
      for await segment in d.activitySegments {
        if reportDate == nil {
          reportDate = segment.dateInterval.start
          
          if let cachedData = await AppsCache.shared.get(for: reportDate!) {
            return cachedData
          }
        }
        segmentCount += 1
        break
      }
      break
    }
    
    var appUsageMap: [ApplicationToken: (name: String, duration: TimeInterval)] = [:]
    var totalDuration: TimeInterval = 0
    
    segmentCount = 0
    
    for await d in data {
      for await segment in d.activitySegments {
        segmentCount += 1
        
        if reportDate == nil {
          reportDate = segment.dateInterval.start
        }
        
        for await category in segment.categories {
          for await app in category.applications {
            let duration = app.totalActivityDuration
            
            guard duration > 0 else { continue }
            guard let token = app.application.token else { continue }
            
            let appName = app.application.localizedDisplayName ?? "Unknown App"
            
            // Суммируем время для КАЖДОГО приложения
            if let existing = appUsageMap[token] {
              appUsageMap[token] = (existing.name, existing.duration + duration)
            } else {
              appUsageMap[token] = (appName, duration)
            }
            
            totalDuration += duration
          }
        }
      }
    }
    
    // Преобразуем в массив и сортируем ВСЕ приложения по убыванию времени
    // Возвращаем ВСЕ приложения, отсортированные от большего времени к меньшему
    let allAppsSorted = appUsageMap
      .map { (token, data) in
        AppUsageInfo(
          token: token,
          name: data.name,
          duration: data.duration
        )
      }
      .sorted { $0.duration > $1.duration }
        
    let result = AppsReportData(
      apps: allAppsSorted,
      totalDuration: totalDuration,
      reportDate: reportDate ?? Date()
    )
    
    if let reportDate = reportDate {
      await AppsCache.shared.set(result, segmentCount: segmentCount, for: reportDate)
    }
    
    return result
  }}

