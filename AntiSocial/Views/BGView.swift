//
//  BGView.swift
//   
//
//

import SwiftUI

struct BGView<Content: View>: View {
  let content: Content
  let imageRsc: ImageResource
  let withBGBlur: Bool
  
  init(imageRsc: ImageResource = .bgMain, withBGBlur: Bool = false ,@ViewBuilder content: () -> Content) {
    self.content = content()
    self.withBGBlur = withBGBlur
    self.imageRsc = imageRsc
  }
  
  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        Image(imageRsc)
          .resizable()
          .ignoresSafeArea()
        
        if withBGBlur {
          bgBlur
            .ignoresSafeArea()
        }
        
        content
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity) // Расширяем содержимое на весь экранн
      .navigationBarHidden(true)
    }
    .background(bgBlur)
  }
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 32)
        .fill(
          Color.white.opacity(0.07)
        )
    }
  }
}
