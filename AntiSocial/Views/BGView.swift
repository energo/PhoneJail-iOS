//
//  BGView.swift
//   
//
//

import SwiftUI

struct BGView<Content: View>: View {
  let content: Content
  let imageRsc: ImageResource

  init(imageRsc: ImageResource = .bgMain, @ViewBuilder content: () -> Content) {
    self.content = content()
    self.imageRsc = imageRsc
  }
  
  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        Image(imageRsc)
          .resizable()
          .ignoresSafeArea()

        content
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity) // Расширяем содержимое на весь экранн
      .navigationBarHidden(true)
    }
  }
}
