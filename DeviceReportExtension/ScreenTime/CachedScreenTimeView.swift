//
//  CachedScreenTimeView.swift
//  AntiSocial
//
//  Created by Assistant on 02.08.2025.
//

import SwiftUI

struct CachedScreenTimeView: View {
    let cachedData: ScreenTimeCache.CachedData
    @State private var totalBlockingTime: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Screen Time Today")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            screenTimeView
            bottomView
            
            Spacer()
        }
        .padding()
        .padding(.horizontal, 32)
        .onAppear {
            loadBlockingStats()
        }
    }
    
    private func loadBlockingStats() {
        let groupDefaults = UserDefaults(suiteName: "group.com.app.antisocial.sharedData")
        totalBlockingTime = groupDefaults?.double(forKey: "todayTotalBlockingTime") ?? 0
    }
    
    private var bottomView: some View {
        HStack(spacing: 32) {
            // Time Blocked
            VStack {
                if totalBlockingTime > 0 {
                    Text(formatDuration(totalBlockingTime))
                        .font(.title2)
                        .foregroundColor(.white)
                } else {
                    Text("—")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text("TIME IN FOCUS")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Most Used Apps
            VStack {
                HStack(spacing: -8) {
                    ForEach(0..<min(cachedData.topApps.count, 3), id: \.self) { index in
                        CachedAppIcon(appName: cachedData.topApps[index].displayName)
                            .frame(width: 30, height: 30)
                            .zIndex(Double(3 - index))
                    }
                }
                
                Text("MOST USED")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            // Pickups
            VStack {
                Text("\(cachedData.totalPickups)")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("PICKUPS")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var screenTimeView: some View {
        HStack {
            VStack(spacing: 0) {
                Text(hoursString(from: cachedData.totalDuration))
                    .font(.system(size: 144, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("HOURS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .offset(y: -30)
            }
            
            VStack(spacing: 0) {
                Text(minutesString(from: cachedData.totalDuration))
                    .font(.system(size: 144, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("MINUTES")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .offset(y: -30)
            }
        }
    }
    
    private func hoursString(from interval: TimeInterval) -> String {
        "\(Int(interval) / 3600)"
    }
    
    private func minutesString(from interval: TimeInterval) -> String {
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%02d", minutes)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct CachedAppIcon: View {
    let appName: String
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text(String(appName.prefix(1)))
                    .font(.caption)
                    .foregroundColor(.white)
            )
    }
}