//
//  ButtonBack.swift
//  AntiSocialApp
//
//  Created by D C on 08.07.2025.
//

import SwiftUI

struct ButtonBack: View {
  var action: () -> Void = {}
  
  var body: some View {
    Button(action: action) {
      HStack {
        Spacer()
        Text("Back")
          .font(.system(size: 16, weight: .regular))
          .frame(maxWidth: .infinity)
        Spacer()
      }
      .padding()
      .foregroundColor(.white)
      .frame(height: 40)
      .frame(width: 124)
      .blurBackground()
    }
  }
}

#Preview {
  VStack {
    ButtonBack()
  }
  .padding(.vertical, 30)
  .padding(.horizontal, 300)
  .background(
    Color.black
  )
}
