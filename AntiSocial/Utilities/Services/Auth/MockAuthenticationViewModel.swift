//
//  MockAuthenticationViewModel.swift
//  FlowMemory
//
//  Created by Daniil Bystrov on 10.12.2024.
//


import Observation
import Foundation
import FirebaseAuth
import AuthenticationServices

@MainActor
class MockAuthenticationViewModel: ObservableObject, @preconcurrency AuthenticationViewModelProtocol {
  @Published var email: String = ""
  @Published var password: String = ""
  @Published var confirmPassword: String = ""
  @Published var flow: AuthenticationFlow = .login
  @Published var isValid: Bool = false
  @Published var authenticationState: AuthenticationState = .unauthenticated
  @Published var errorMessage: String = ""
  @Published var fireUser: User?
  @Published var user: ASUser?
  @Published var displayName: String = "Mock User"

  required init(subscriptionManager: SubscriptionManager) {}

  func signInWithEmailPassword() async -> Bool {
    if email == "test@example.com" && password == "password123" {
      authenticationState = .authenticated
      user = ASUser.mock()
      return true
    } else {
      errorMessage = "Invalid email or password"
      return false
    }
  }

  func signUpWithEmailPassword() async -> Bool {
    if email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword {
      errorMessage = "Invalid registration details"
      return false
    }
    authenticationState = .authenticated
    user = ASUser.mock()
    return true
  }

  func signInAnonymously() async -> Bool {
    authenticationState = .authenticated
    user = ASUser.mock(isAnonymous: true)
    return true
  }

  func signOut() {
    authenticationState = .unauthenticated
    user = nil
  }

  func deleteAccount() async -> Bool {
    if user != nil {
      user = nil
      authenticationState = .unauthenticated
      return true
    }
    errorMessage = "No account to delete"
    return false
  }

  func linkEmail(email: String, password: String) async throws -> Bool {
    return true
  }

  func linkGoogle() async throws -> Bool {
    return true
  }

  func handleLinkWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
    switch result {
      case .failure(let error):
        errorMessage = "Mock Apple link failed: \(error.localizedDescription)"
      case .success:
        authenticationState = .authenticated
        user = ASUser.mock(name: "Apple User")
        displayName = "Apple Mock User"
        errorMessage = ""
    }
  }

  func signInWithGoogle() async -> Bool {
    authenticationState = .authenticated
    user = ASUser.mock(name: "Google User")
    return true
  }

  func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {}

  func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {}

  func verifySignInWithAppleAuthenticationState() {}

  func fetchUser(uid: String?) {
    if let uid = uid {
      user = ASUser.mock(id: uid)
    }
  }
}
