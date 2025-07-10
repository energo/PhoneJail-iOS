//
//  OnboardingScreen.swift
//
//

import SwiftUI

struct OnboardingScreen: View {
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
            Image(.icNotificationsAlert)
              .resizable()
              .frame(width: 270, height: 178)
          }
        }
        .tag(2)
                .task {
                  try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 секунды
        
                  LocalNotificationManager.shared.requestAuthorization { isNotificationAuthed in
                    AppLogger.trace("isNotificationAuthed \(isNotificationAuthed)")
        
                    UNUserNotificationCenter.current().delegate = DTNNotificationHandler.shared
                  }
                }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      
      Spacer()
        .frame(height: 80)
    }
  }
  
  private var nextButton: some View {
    ButtonMain(title: "Next") {
      if isLastPage {
        isShow = false
      } else {
        currentPage += 1
      }
    }
  }
  
  private var isLastPage: Bool {
    currentPage == 3
  }
}

//MARK: - Preview
#Preview {
  OnboardingScreen(isShow: .constant(false))
}
