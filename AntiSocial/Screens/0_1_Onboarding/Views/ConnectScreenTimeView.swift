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

      Spacer()
      if showScreenTimeImage {
        Spacer()
      } else {
        Image(.onbgScreentime) // You'll need to add this image to Assets
          .resizable()
          .scaledToFit()
          .padding(.horizontal, 48)
          .transition(.opacity)
      }
      
      if showScreenTimeImage {
        Image(.onbgScreentimeAllow) // You'll need to add this image to Assets
          .resizable()
          .scaledToFit()
          .padding(.horizontal, 64)
          .padding(.top, 140)
          .transition(.opacity)
      }
      
      Spacer()
    }
  }
}
