//
//  SwiftUIView.swift
//  AntiSocialApp
//
//  Created by D C on 23.09.2025.
//

import SwiftUI

struct TestOverlayView: View {
    var body: some View {
      VStack {
        Image(.testWater2)
          .resizable()
          .scaledToFill()
          .overlay {
            Image(.testGradient)
              .resizable()
              .scaledToFill()
              .opacity(0.5)
              .edgesIgnoringSafeArea(.all)
          }
      }
      .ignoresSafeArea()
    }
}

#Preview {
  TestOverlayView()
}
