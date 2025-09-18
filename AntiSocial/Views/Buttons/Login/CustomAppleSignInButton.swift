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

  let title: String? = "Sign in with Apple"
  var imageLeading: Image? = Image(.icApple)
  
  var imageLeft: Image?
  var imageRight: Image?

  var colorBackground: Color = Color.white
  var colorTxt: Color = Color.black
  var height: CGFloat = 54
  var showStroke: Bool = false
  var cornerRadius: CGFloat = 14
    
  var body: some View {
    contentView
      .frame(maxWidth: .infinity)
      .frame(height: height)
      .background(colorBackground)
      .cornerRadius(cornerRadius)
  }
  
  private var contentView: some View {
    Button(action:  {
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
        
        if let image = imageLeft {
          image
            .padding(.vertical)
            .foregroundColor(colorTxt)
        } else {
          Spacer()
          
          if let image = imageLeading {
            image
              .padding(.vertical)
              .foregroundColor(colorTxt)
          }
        }
        
        if let title = title {
          Text(title)
          //                        .bold()
            .font(.system(size: 16, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundColor(colorTxt)
            .padding(.vertical)
        }
                
        if let image = imageRight {
          image
            .padding(.vertical)
            .foregroundColor(colorTxt)
        } else {
          Spacer()
        }
      }
      .padding(.horizontal, 4)
    }
  }
  
  private var overlayView: some View {
    Group {
      if showStroke {
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.white, lineWidth: 1)
      } else {
        Color.clear
      }
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
