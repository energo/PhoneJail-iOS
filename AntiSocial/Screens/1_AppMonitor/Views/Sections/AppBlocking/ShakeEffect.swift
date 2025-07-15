//
//  ShakeEffect.swift
//  AntiSocial
//
//  Created by D C on 15.07.2025.
//


import SwiftUI

struct ShakeEffect: GeometryEffect {
  var amount: CGFloat = 8
  var shakesPerUnit = 3
  var animatableData: CGFloat
  
  func effectValue(size: CGSize) -> ProjectionTransform {
    ProjectionTransform(CGAffineTransform(
      translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0)
    )
  }
}

