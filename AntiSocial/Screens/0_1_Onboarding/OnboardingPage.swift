//
//  OnboardingPage.swift
//
//

import SwiftUI

struct OnboardingPage<MainContent: View>: View {
  @State private var showText = false
  
  let title: String
  var bottomTxt: String
  var image: ImageResource?
  let mainView: MainContent
  
  init(
    title: String, bottomTxt: String = "",
    image: ImageResource? = nil,
    @ViewBuilder mainView: () -> MainContent
  ) {
    self.title = title
    self.image = image
    self.bottomTxt = bottomTxt
    self.mainView = mainView()
  }
  
  var body: some View {
    VStack(spacing: 0) {
      if image != nil {
        topImageView
          .padding(.top, 24)
      }
      
      VStack(spacing: 24) {
        
        topTextView
        mainView
          .opacity(showText ? 1 : 0)
        
        if !bottomTxt.isEmpty {
          bottomTextView
        }
        
        Spacer()
      }
    }
    .frame(maxWidth: .infinity)
    .onAppear {
      showText = false
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(.easeIn(duration: 0.6)) {
          showText = true
        }
      }
    }
  }
  
  private var bottomTextView: some View {
    VStack {
      Spacer()
      Text(bottomTxt)
        .multilineTextAlignment(.center)
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(.white)
    }
    .padding(.horizontal, 8)
    .padding(.bottom, 64)
    .opacity(showText ? 1 : 0)
  }
  
  private var topImageView: some View {
    Image(image!)
      .resizable()
      .frame(width: 128, height: 131)
  }
  
  private var topTextView: some View {
    Text(title)
      .multilineTextAlignment(.center)
      .font(.system(size: 24, weight: .semibold))
      .foregroundColor(.white)
      .padding(.horizontal, 8)
      .padding(.top, image == nil ? 24 : 16)
      .opacity(showText ? 1 : 0)
  }
}
