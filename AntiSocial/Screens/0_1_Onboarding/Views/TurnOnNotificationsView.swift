//
//  TurnOnNotificationsView.swift
//  AntiSocial
//
//  Created by D C on 08.08.2025.
//

import SwiftUI

struct TurnOnNotificationsView: View {
  @Binding var hasRequestedPermission: Bool
  @Binding var isAuthorized: Bool?
    
  var body: some View {
    VStack {
      Spacer()
      if let isAuthorized, isAuthorized == false {
        noAccessAlertView
        Spacer()
      } else if isAuthorized != true {
        allowNotificationView
      }
    }
  }
  
  private var allowNotificationView: some View {
    Image(.onbgNotificationsAllow)
      .resizable()
      .scaledToFit()
      .padding(.horizontal, 64)
      .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
  }
  
  // MARK: - Private views
  private var noAccessAlertView: some View {
    VStack(spacing: 8) {
      Image(.onbgAlert)
        .resizable()
        .scaledToFit()
        .frame(width: 102, height: 98)
        .transition(.opacity)
      Text("Without access to your notifications, the app won’t be able to deliver the full experience, as restrictions limit its functionality.")
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
    }
  }
}
