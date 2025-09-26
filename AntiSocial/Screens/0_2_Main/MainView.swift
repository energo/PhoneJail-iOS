//
//  MainView.swift
//  AntiSocial
//
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct MainView: View {
  @EnvironmentObject var authVM: AuthenticationViewModel
  @AppStorage("isFirstRun") private var isFirstRun: Bool = true

  @State private var showPaywall = false
  
  // MARK: - Navigation guide
  @AppStorage("showNavigationGuide") private var showNavigationGuide: Bool = true
  @State private var navigationGuideViewsPosition = NavigationGuideViewsPosition()
  
  //MARK: - Init Methods
  
  //MARK: - Views
  var body: some View {
    switch authVM.authenticationState {
      case .unauthenticated, .authenticating:
        LoginView()
        
      case .authenticated:
        if isFirstRun {
          OnboardingScreen(isShow: $isFirstRun)
        } else {
          AppMonitorScreen(navigationGuideViewsPosition: $navigationGuideViewsPosition)
            .fullScreenCover(isPresented: $showNavigationGuide) {
              NavigationGuideView(
                viewsPosition: $navigationGuideViewsPosition,
                isShown: $showNavigationGuide
              )
            }
        }
    }
  }
}

//MARK: - Preview
#Preview {
  MainView()
}
