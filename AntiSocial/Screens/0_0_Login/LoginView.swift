//
//  LoginView.swift
//   
//
//  Created by D C on 12.03.2025.
//

import SwiftUI
import AuthenticationServices
import RevenueCat
import RevenueCatUI

struct LoginView: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var authVM: AuthenticationViewModel
  @Environment(\.presentationMode) var presentationMode

  @State private var email: String = ""
  @State private var password: String = ""

  @State private var selectedCardIndex: Int = 0
//  @State private var contents: [WelcomeContent] = []
  @State private var showPaywall = false
  @AppStorage("hasSeenPaywallAfterOnboarding") var hasSeenPaywallAfterOnboarding: Bool = false

  //MARK: - Views
  var body: some View {
    BGView(imageRsc: .bgLogin) {
    contentView
    }
    .task {
//      contents = WelcomeContent.example
      if !hasSeenPaywallAfterOnboarding {
        showPaywall = true
      }
    }
    .fullScreenCover(isPresented: $showPaywall) {
      hasSeenPaywallAfterOnboarding = true
      return PaywallView(displayCloseButton: true)
    }
  }

    //MARK: - Private Views
  private var contentView: some View {
    VStack {
      Spacer()

      textView
      
      logoView
      
      buttonsView
      .padding(.bottom, 32)
      .padding(.horizontal, 32)
    }
  }
  
  private var textView: some View {
    Text("Less Screen.\nMore Freedom.")
      .font(.system(size: 32, weight: .semibold))
      .foregroundColor(.white)
      .multilineTextAlignment(.center)
  }
  
  private var logoView: some View {
    Image(.icLock)
      .resizable()
      .frame(maxHeight: 420)
      .frame(maxWidth: 350)
  }
  
  private var buttonsView: some View {
    VStack {
      appleButton
      googleButton
      skipButton
    }
  }
  
  private var appleButton: some View {
    CustomAppleSignInButton(
      onRequest: { request in
        authVM.handleSignInWithAppleRequest(request)
      },
      onCompletion: { result in
        authVM.handleSignInWithAppleCompletion(result)
      }
    )
  }

  private var googleButton: some View {
    ButtonLeftIcon(title: "Sign in with Google",
                   imageLeading: Image(.icGoogleWhite),
                   colorBackground: Color.clear,
                   colorTxt: .white,
                   showStroke: true)
    {
    signInWithGoogle()
    }
  }

  private var skipButton: some View {
    Button {
      signInAnonymously()
    } label: {
      Text("Continue as a guest")
        .underline()
        .foregroundStyle(.white)
    }
  }

//  private var carouselContentView: some View {
//    TabView(selection: $selectedCardIndex) {
//      ForEach(contents.indices, id: \.self) { index in
//        GeometryReader { geometry in
//          WelcomeView(content: contents[index])
//            .tag(index)
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//        }
//      }
//    }
//    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
//    .padding(.bottom, 20) // добавляем отступ снизу, чтобы избежать перекрытия
//  }

  //MARK: - Private Methods
  private func signInWithGoogle() {
    Task {
      if await authVM.signInWithGoogle() == true {
        presentationMode.wrappedValue.dismiss()
      }
    }
  }

  private func signInAnonymously() {
    Task.detached() {
      if await authVM.signInAnonymously() == true {
        await MainActor.run {
          presentationMode.wrappedValue.dismiss()
        }
      }
    }
  }
}

//MARK: - Preview
#Preview {
  LoginView()
}
