//
//  VisualBlurView.swift
//   
//
//  Created by D C on 26.03.2025.
//

import SwiftUI

struct VisualBlurView: UIViewRepresentable {
  let style: UIBlurEffect.Style
  
  func makeUIView(context: Context) -> UIVisualEffectView {
    return UIVisualEffectView(effect: UIBlurEffect(style: style))
  }
  
  func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
