//
//  TurnOnNotificationsView.swift
//  AntiSocial
//
//  Created by D C on 08.08.2025.
//

import SwiftUI

struct TurnOnNotificationsView: View {
  @State private var hasRequestedPermission = false
  
  var body: some View {
    VStack {
      Spacer()
      
      Image(.onbgNotificationsAllow)
        .resizable()
        .scaledToFit()
        .padding(.horizontal, 64)
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    }
    .task {
      if !hasRequestedPermission {
        hasRequestedPermission = true
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        LocalNotificationManager.shared.requestAuthorization { isAuthorized in
          AppLogger.trace("Notifications authorized: \(isAuthorized)")
          UNUserNotificationCenter.current().delegate = DTNNotificationHandler.shared
        }
      }
    }
  }
}
