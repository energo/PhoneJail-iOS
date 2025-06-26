//
//  File.swift
//  Flashcards
//
//  Created by Daniil Bystrov on 08.08.2024.
//


import SwiftUI

struct BackdropView: UIViewRepresentable {
  
  func makeUIView(context: Context) -> UIVisualEffectView {
    let view = UIVisualEffectView()
    let blur = UIBlurEffect()
    let animator = UIViewPropertyAnimator()
    animator.addAnimations { view.effect = blur }
    animator.fractionComplete = 0
    animator.stopAnimation(false)
    animator.finishAnimation(at: .current)
    
    return view
  }
  
  func updateUIView(_ uiView: UIVisualEffectView, context: Context) { }
}

/// A transparent View that blurs its background
struct BackdropBlurView: View {
  var isBlack: Bool = true
  var radius: CGFloat = 4
  
  var gradient: LinearGradient? = nil
  
  @ViewBuilder
  var body: some View {
    ZStack {
      if let gradient = gradient {
        gradient
      }
      
      BackdropView()
        .blur(radius: radius)
      //        .padding(-40) //Trick: To escape from white patch @top & @bottom
    }
    .ignoresSafeArea()
  }
}
