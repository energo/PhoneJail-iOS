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
  var topLeading: CGFloat?
  var topTrailing: CGFloat?
  var bottomLeading: CGFloat?
  var bottomTrailing: CGFloat?
  var isBlack: Bool = false

  func body(content: Content) -> some View {
    content
      .background(
        ZStack {
          BackdropBlurView(isBlack: isBlack, radius: radius)
          
          // Use custom corner radii if provided, otherwise use uniform cornerRadius
          if let tl = topLeading, let tr = topTrailing, let bl = bottomLeading, let br = bottomTrailing {
            UnevenRoundedRectangle(
              topLeadingRadius: tl,
              bottomLeadingRadius: bl,
              bottomTrailingRadius: br,
              topTrailingRadius: tr
            )
            .fill(Color.white.opacity(0.07))
          } else {
            RoundedRectangle(cornerRadius: cornerRadius)
              .fill(Color.white.opacity(0.07))
          }
        }
      )
  }
}

extension View {
  func blurBackground(radius: CGFloat = 10, cornerRadius: CGFloat = 32, isBlack: Bool = false) -> some View {
    self.modifier(BlurBackgroundModifier(radius: radius, cornerRadius: cornerRadius, isBlack: isBlack))
  }
  
  func blurBackground(
    radius: CGFloat = 10,
    topLeading: CGFloat,
    topTrailing: CGFloat,
    bottomLeading: CGFloat,
    bottomTrailing: CGFloat,
    isBlack: Bool = false
  ) -> some View {
    self.modifier(BlurBackgroundModifier(
      radius: radius,
      topLeading: topLeading,
      topTrailing: topTrailing,
      bottomLeading: bottomLeading,
      bottomTrailing: bottomTrailing,
      isBlack: isBlack
    ))
  }
}
