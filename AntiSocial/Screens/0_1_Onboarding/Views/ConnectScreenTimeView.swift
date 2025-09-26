//
//  ConnectScreenTimeView.swift
//  AntiSocial
//
//  Created by D C on 08.08.2025.
//

import SwiftUI
//import FamilyControls

struct ConnectScreenTimeView: View {
  //  @EnvironmentObject var familyControlsManager: FamilyControlsManager
  @Binding var showScreenTimeImage: Bool
  @Binding var hasDeniedPermissionRequest: Bool
  
  // MARK: - Views
  var body: some View {
    VStack {
      Text("Your data is completely safe and never leaves your device.")
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.top, 16)
      
      if !showScreenTimeImage {
        Spacer()
        bgScreenTimeView
        Spacer()
      } else if hasDeniedPermissionRequest {
        Spacer()
        noAccessAlertView
        Spacer()
      } else {
        allowScreenTimeView
      }
    }
  }
  
  // MARK: - Private views
  private var noAccessAlertView: some View {
    VStack(spacing: 8) {
      Image(.onbgAlert)
        .resizable()
        .scaledToFit()
        .frame(width: 102, height: 98)
        .transition(.opacity)
      Text("Without access to your Screen Time data, the app will not be able to function properly or provide any of its features.")
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
    }
  }
  
  private var bgScreenTimeView: some View {
    Image(.onbgScreentime)
      .resizable()
      .scaledToFit()
      .padding(.horizontal, 48)
      .transition(.opacity)
  }
  
  private var allowScreenTimeView: some View {
    Image(.onbgScreentimeAllow)
      .resizable()
      .scaledToFit()
      .padding(.horizontal, 64)
      .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 24)
      .transition(.opacity)
  }
}
