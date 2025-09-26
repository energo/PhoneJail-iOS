//
//  AppUsageSectionView.swift
//  DeviceReportExtension
//

import SwiftUI

struct AppUsageSectionView: View {
  let appsData: AppsReportData
  
  var body: some View {
    ScrollView() {
      VStack(spacing: 6) {
        ForEach(appsData.apps) { app in
          HStack(spacing: 6) {
            Label(app.token)
              .labelStyle(.iconOnly)
              .adaptiveFrame(width: \.appIconSize, height: \.appIconSize)
            
            Text(app.name)
              .adaptiveFont(\.body)
              .fontWeight(.medium)
              .foregroundStyle(.white)
            
            Spacer()
            
            Text(app.duration.formattedAsHoursMinutes())
              .adaptiveFont(\.body)
              .foregroundStyle(.white)
          }
        }
      }
    }
  }
}

