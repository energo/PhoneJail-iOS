//
//  AppRowView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct AppRowView: View {
  let app: MonitoredApp
  let onToggle: (MonitoredApp) -> Void
  
  var body: some View {
    HStack {
      // Иконка приложения
      appIcon
      
      VStack(alignment: .leading, spacing: 2) {
        Text(app.displayName)
          .font(.subheadline)
          .fontWeight(.medium)
        
        if let bundleId = app.bundleIdentifier {
          Text(bundleId)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }
      
      Spacer()
      
      Toggle("", isOn: Binding(
        get: { app.isMonitored },
        set: { newValue in
          var updatedApp = app
          updatedApp.isMonitored = newValue
          onToggle(updatedApp)
        }
      ))
      .toggleStyle(SwitchToggleStyle(tint: .blue))
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color.white)
    .cornerRadius(8)
    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
  }
  
  @ViewBuilder
  private var appIcon: some View {
    ZStack {
      // Fallback background
      RoundedRectangle(cornerRadius: 8)
        .fill(LinearGradient(
          colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ))
        .frame(width: 36, height: 36)
      
      // First letter of app name
      Text(String(app.displayName.prefix(1)).uppercased())
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundColor(.white)
    }
  }
}
