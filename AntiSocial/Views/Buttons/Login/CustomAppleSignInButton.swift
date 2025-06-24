//
//  CustomAppleSignInButton.swift
//  AntiSocial
//
//  Created by D C on 24.06.2025.
//


import SwiftUI
import AuthenticationServices

struct CustomAppleSignInButton: View {
  var onRequest: (ASAuthorizationAppleIDRequest) -> Void
  var onCompletion: (Result<ASAuthorization, Error>) -> Void

  @State private var signInDelegate: AppleSignInDelegate? = nil

  var body: some View {
    Button(action: {
      let provider = ASAuthorizationAppleIDProvider()
      let request = provider.createRequest()
      onRequest(request)

      let delegate = AppleSignInDelegate(onCompletion: onCompletion)
      self.signInDelegate = delegate // 💡 сохраняем, чтобы не деинициализировался

      let controller = ASAuthorizationController(authorizationRequests: [request])
      controller.delegate = delegate
      controller.performRequests()
    }) {
      HStack {
        Image(.icApple)
          .resizable()
          .frame(width: 18, height: 20)
        
        Text("Sign in with Apple")
          .font(.primary(weight: .semibold,
                         size: .smallPlus))
      }
      .foregroundColor(.black)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background(Color.white)
      .cornerRadius(14)
    }
  }
}



// Delegate helper (bridging UIKit to SwiftUI)
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    var onCompletion: (Result<ASAuthorization, Error>) -> Void

    init(onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.onCompletion = onCompletion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion(.failure(error))
    }
}
