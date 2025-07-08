//
//  BlurBackgroundModifier.swift
//  AntiSocial
//
//  Created by D C on 08.07.2025.
//


import SwiftUI

struct BlurBackgroundModifier: ViewModifier {
  var radius: CGFloat = 10
  var cornerRadius: CGFloat = 32
  var isBlack: Bool = false

  func body(content: Content) -> some View {
    content
      .background(
        ZStack {
          BackdropBlurView(isBlack: isBlack, radius: radius)
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.07))
        }
      )
  }
}

extension View {
  func blurBackground(radius: CGFloat = 10, cornerRadius: CGFloat = 32, isBlack: Bool = false) -> some View {
    self.modifier(BlurBackgroundModifier(radius: radius, cornerRadius: cornerRadius, isBlack: isBlack))
  }
}
