//
//  OnboardingScreen.swift
//
//

import SwiftUI
import RevenueCatUI

struct OnboardingScreen: View {
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @EnvironmentObject var familyControlsManager: FamilyControlsManager
  
  @Binding var isShow: Bool
  @State private var currentPage = 0
  
  @State private var agreedToStorage = false
  @State private var agreedToProcessing = false
  @State private var selectedGoal: String? = nil
  @State private var hasRequestedScreenTime = false
  
  //MARK: - Views
  var body: some View {
    BGView(imageRsc: .bgMain) {
      ZStack {
        tabView
        
        VStack {
          Spacer()
          
          nextButton
            .padding(.horizontal, 72)
            .padding(.bottom, 56)
        }
      }
    }
    .ignoresSafeArea()
  }
  
  private var tabView: some View {
    VStack {
      TabView(selection: $currentPage) {
        OnboardingPage(
          title: "Help us tailor your screen time journey by telling us your main goal...",
        ) {
          MainGoalQuizView(selectedGoal: $selectedGoal)
        }
        .tag(0)
        
        OnboardingPage(
          title: "How Phone Jail works",
          image: .onbgHwLock
        ) {
          HowWorksView()
        }
        .tag(1)
        
        OnboardingPage(
          title: "Connect Phone Jail to Screen Time"
        ) {
          ConnectScreenTimeView(showScreenTimeImage: $hasRequestedScreenTime)
        }
        .tag(2)
        
        OnboardingPage(
          title: "Turn on notifications to experience Phone Jail's core features",
          bottomTxt: "Turn on notifications to get reminders, summaries and reports of your activity and enable push notifications."
        ) {
          TurnOnNotificationsView()
        }
        .tag(3)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      
      if !isLastPage {
        Spacer()
          .frame(height: 80)
      }
    }
  }
  
  private var nextButton: some View {
    ButtonMain(title: buttonTitle) {
      handleButtonAction()
    }
//    .disabled(isButtonDisabled)
  }
  
  private var buttonTitle: String {
    switch currentPage {
      case 2:
        return hasRequestedScreenTime ? "Next" : "Connect Phone Jail"
      default:
        return "Next"
    }
  }
  
//  private var isButtonDisabled: Bool {
//    currentPage == 2 && hasRequestedScreenTime
//  }
  
  private func handleButtonAction() {
    switch currentPage {
      case 2:
        if !hasRequestedScreenTime {
          requestScreenTimePermission()
        } else {
          currentPage += 1
        }
      case 3:
        saveConsentAndGoal()
        isShow = false
      default:
        currentPage += 1
    }
  }
  
  @MainActor
  private func requestScreenTimePermission() {
    familyControlsManager.requestAuthorization()
    withAnimation(.easeIn(duration: 0.5)) {
      hasRequestedScreenTime = true
    }
  }
  
  private var isLastPage: Bool {
    currentPage == 3
  }
  
  func saveConsentAndGoal() {
    guard var currentUser = Storage.shared.user else { return }
    
    currentUser.agreedToDataStorage = agreedToStorage
    currentUser.agreedToDataProcessing = agreedToProcessing
    currentUser.mainGoal = selectedGoal
    currentUser.lastUpdated = Date()
    
    Task {
      do {
        try await Storage.shared.saveUser(currentUser)
      } catch {
        AppLogger.critical(error, details: "Failed to save user")
      }
    }
  }
  
}

//MARK: - Preview
#Preview {
  OnboardingScreen(isShow: .constant(false))
    .environmentObject(FamilyControlsManager.shared)
}
