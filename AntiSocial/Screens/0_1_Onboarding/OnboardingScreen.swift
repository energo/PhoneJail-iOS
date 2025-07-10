//
//  OnboardingScreen.swift
//
//

import SwiftUI
import RevenueCatUI

struct OnboardingScreen: View {
  @EnvironmentObject var subscriptionManager: SubscriptionManager

  @Binding var isShow: Bool
  @State private var currentPage = 0
  
  @State private var agreedToStorage = false
  @State private var agreedToProcessing = false
  @State private var selectedGoal: String? = nil
  
  //MARK: - Views
  var body: some View {
    BGView(imageRsc: .bgMain) {
      ZStack {
        tabView
        
        VStack {
          Spacer()
          
          if !isLastPage {
            nextButton
              .padding(.horizontal, 72)
              .padding(.bottom, 56)
          }
        }
      }
    }
    .ignoresSafeArea()
    .onChangeWithOldValue(of: isLastPage) { _, newValue in
      if newValue {
        saveConsentAndGoal()
      }
    }
    .onChangeWithOldValue(of: subscriptionManager.isSubscriptionActive) { oldValue, newValue in
      if newValue {
        isShow = false
      }
    }
  }
  
  private var tabView: some View {
    VStack {
      TabView(selection: $currentPage) {
        OnboardingPage(
          title: "We classify our users’ data as private data.",
        ) {
          PrivacyConsentView(
            agreedToStorage: $agreedToStorage,
            agreedToProcessing: $agreedToProcessing
          )
        }
        .tag(0)
        
        OnboardingPage(
          title: "Help us tailor your screen time journey by telling us your main goal...",
        ) {
          MainGoalQuizView(selectedGoal: $selectedGoal)
        }
        .tag(1)
        
        OnboardingPage(
          title: "Turn on notifications to experience Phone Jail’s core features",
          bottomTxt: "Turn on notifications to get reminders, summaries and reports of your activity and enable push notifications.",
        ) {
          VStack {
            Spacer()
          }
        }
        .tag(2)
        .task {
          try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 секунды
          
          LocalNotificationManager.shared.requestAuthorization { isNotificationAuthed in
            AppLogger.trace("isNotificationAuthed \(isNotificationAuthed)")
            
            UNUserNotificationCenter.current().delegate = DTNNotificationHandler.shared
          }
        }
        
        PaywallView(displayCloseButton: true)
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
    ButtonMain(title: "Next") {
      if isLastPage {
//        saveConsentAndGoal()
//        isShow = false
      } else {
        currentPage += 1
      }
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
        print("Failed to save user: \(error.localizedDescription)")
      }
    }
  }
  
}

//MARK: - Preview
#Preview {
  OnboardingScreen(isShow: .constant(false))
}
