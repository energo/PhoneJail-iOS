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
        Image(.onbgScreentime)
          .resizable()
          .scaledToFit()
          .padding(.horizontal, 48)
          .transition(.opacity)
        Spacer()
      }
      
      if showScreenTimeImage {
        Image(.onbgScreentimeAllow)
          .resizable()
          .scaledToFit()
          .padding(.horizontal, 64)
          .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 24)
          .transition(.opacity)
      }
    }
  }
}
