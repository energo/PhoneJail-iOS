//
//  NavigationGuideView.swift
//  AntiSocialApp
//
//

import SwiftUI

struct NavigationGuideView: View {
  @Binding var viewsPosition: NavigationGuideViewsPosition
  @Binding var isShown: Bool
  
  var body: some View {
    contentView
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(BackgroundClearView())
      .background(backgroundView)
  }
  
  @ViewBuilder
  private var contentView: some View {
    if let rect = viewsPosition.sideNavigationPanel {
      VStack {
        GeometryReader { proxy in
          Image(.icSwipeGestureGuide)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, rect.width * 2)
            .position(
              x: proxy.size.width / 2,
              y: rect.bounds.minY + rect.bounds.height * 0.65
            )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(alignment: .bottom) {
        overlayButton
          .padding(.bottom, 16)
      }
    }
  }
  
  @ViewBuilder
  private var backgroundView: some View {
    if let rect = viewsPosition.sideNavigationPanel {
      ZStack {
        Color.black
          .opacity(0.5)
          .ignoresSafeArea()
        RoundedRectangle(cornerRadius: rect.width / 2)
          .fill(.black)
          .frame(width: rect.width, height: rect.bounds.height + 10)
          .position(
            x: rect.bounds.minX + rect.bounds.width / 2 + rect.offset,
            y: rect.bounds.minY + rect.bounds.height / 2
          )
          .blendMode(.destinationOut)
      }
      .compositingGroup()
    }
  }
  
  private var overlayButton: some View {
    ButtonMain(
      title: "Get started",
      bgStyle: AnyShapeStyle(Color.as_gradient_pomodoro_focus_progress),
      txtColor: .white
    ) {
      isShown = false
    }
    .padding(.horizontal, 64)
  }
}
