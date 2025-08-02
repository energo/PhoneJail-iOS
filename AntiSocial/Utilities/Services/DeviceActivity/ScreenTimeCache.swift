//
//  ScreenTimeCache.swift
//  AntiSocial
//
//  Created by Assistant on 02.08.2025.
//

import Foundation
import DeviceActivity

/// Cache manager for Screen Time data
final class ScreenTimeCache {
    static let shared = ScreenTimeCache()
    
    private let cacheKey = "cachedScreenTimeData"
    private let cacheExpirationKey = "cachedScreenTimeExpiration"
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    struct CachedData: Codable {
        let totalDuration: TimeInterval
        let totalPickups: Int
        let topApps: [CachedApp]
        let timestamp: Date
        
        struct CachedApp: Codable {
            let displayName: String
            let duration: String
            let bundleId: String
        }
    }
    
    /// Save screen time data to cache
    func cacheScreenTimeData(totalDuration: TimeInterval, totalPickups: Int, topApps: [(name: String, duration: String, bundleId: String)]) {
        let cachedApps = topApps.map { CachedData.CachedApp(displayName: $0.name, duration: $0.duration, bundleId: $0.bundleId) }
        let data = CachedData(
            totalDuration: totalDuration,
            totalPickups: totalPickups,
            topApps: cachedApps,
            timestamp: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(data) {
            // Save to the same key that @AppStorage uses
            SharedData.userDefaults?.set(encoded, forKey: SharedData.ScreenTime.cachedScreenTimeData)
            SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedData.ScreenTime.lastScreenTimeRefresh)
            SharedData.userDefaults?.set(true, forKey: SharedData.ScreenTime.screenTimeHasLoadedOnce)
        }
    }
    
    /// Get cached screen time data if available and not expired
    func getCachedData() -> CachedData? {
        guard let data = SharedData.userDefaults?.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(CachedData.self, from: data) else {
            return nil
        }
        
        // Check if cache is still valid (not older than 24 hours)
        let maxAge: TimeInterval = 86400 // 24 hours
        if Date().timeIntervalSince(decoded.timestamp) > maxAge {
            clearCache()
            return nil
        }
        
        return decoded
    }
    
    /// Check if cache is expired (for soft expiration - still show but refresh in background)
    func isCacheExpired() -> Bool {
        guard let expirationDate = SharedData.userDefaults?.object(forKey: cacheExpirationKey) as? Date else {
            return true
        }
        return Date() > expirationDate
    }
    
    /// Clear cached data
    func clearCache() {
        SharedData.userDefaults?.removeObject(forKey: cacheKey)
        SharedData.userDefaults?.removeObject(forKey: cacheExpirationKey)
    }
}