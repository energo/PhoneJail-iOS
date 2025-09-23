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
        Image(.testWater)
          .resizable()
          .scaledToFill()
//          .overlay {
//            Image(.testGradientOpacity)
//              .resizable()
//              .scaledToFill()
//              .edgesIgnoringSafeArea(.all)
//          }
      }
      .ignoresSafeArea()
    }
}

#Preview {
  TestOverlayView()
}
