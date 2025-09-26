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
  
  @State private var notificationRequested: Bool = false
  @State private var notificationAuthorized: Bool?
  
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
          ConnectScreenTimeView(showScreenTimeImage: $hasRequestedScreenTime, isAuthorized: $familyControlsManager.isAuthorized)
        }
        .tag(2)
        
        OnboardingPage(
          title: "Turn on notifications to experience Phone Jail's core features",
          bottomTxt: notificationAuthorized == false ? "" : "Turn on notifications to get reminders, summaries and reports of your activity and enable push notifications."
        ) {
          TurnOnNotificationsView(hasRequestedPermission: $notificationRequested, isAuthorized: $notificationAuthorized)
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
    ButtonMain(
      title: buttonTitle,
      bgStyle: AnyShapeStyle(Color.as_gradient_pomodoro_focus_progress),
      txtColor: .white
    ) {
      handleButtonAction()
    }
//    .disabled(isButtonDisabled)
  }
  
  private var buttonTitle: String {
    switch currentPage {
      case 2:
        if !hasRequestedScreenTime {
          return "Connect Phone Jail"
        } else {
          if familyControlsManager.hasScreenTimePermission {
            return "Next:"
          } else {
            return "Give an access"
          }
        }
      case 3:
        if notificationAuthorized == true {
          return "Next:"
        } else {
          return "Give an access"
        }
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
        if !hasRequestedScreenTime || !familyControlsManager.hasScreenTimePermission {
          requestScreenTimePermission()
        } else {
          currentPage += 1
          requestNotificationPermission()
        }
      case 3:
        if notificationAuthorized == true {
          saveConsentAndGoal()
          isShow = false
        } else {
          requestNotificationPermission()
        }
        
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
  
  private func requestNotificationPermission() {
    notificationAuthorized = nil
    notificationRequested = true
    LocalNotificationManager.shared.requestAuthorization { isAuthorized in
      notificationAuthorized = isAuthorized
      AppLogger.trace("Notifications authorized: \(isAuthorized)")
      UNUserNotificationCenter.current().delegate = DTNNotificationHandler.shared
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
