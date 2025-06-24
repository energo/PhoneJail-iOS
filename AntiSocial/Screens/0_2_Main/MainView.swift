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
  @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = true
  @AppStorage("isFirstRun") private var isFirstRun: Bool = true

  @State private var showPaywall = false
  
  //MARK: - Init Methods
  init() {
    UITabBar.appearance().unselectedItemTintColor = UIColor(Color.white)
//    let appearance = UITabBarAppearance()
//    UITabBar.appearance().scrollEdgeAppearance = appearance    
  }
  
  //MARK: - Views
  var body: some View {
    switch authVM.authenticationState {
      case .unauthenticated, .authenticating:
        LoginView()
        
      case .authenticated:
        if isFirstRun {
//          UnifiedOnboardingScreen(isShow: $isFirstRun)
        } else {
          ContentView(model: SelectAppsModel())
        }
    }
  }
}

//MARK: - Preview
#Preview {
  MainView()
}
