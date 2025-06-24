//
// AuthenticationViewModel.swift
// Favourites
//
// Created by Peter Friese on 08.07.2022
// Copyright © 2021 Google LLC. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import SwiftUI

import FirebaseCore
import FirebaseAuth

// For Sign in with Google
import GoogleSignIn
import GoogleSignInSwift

// For Sign in with Apple
import AuthenticationServices
import CryptoKit

import Combine

import RevenueCat

enum AuthenticationState: String {
  case unauthenticated
  case authenticating
  case authenticated
}

enum AuthenticationFlow {
  case login
  case signUp
}

enum AuthenticationError: Error {
  case tokenError(message: String)
}

typealias GFBUser = User

@MainActor
class AuthenticationViewModel: ObservableObject, @preconcurrency AuthenticationViewModelProtocol {
  @Published var subscriptionManager: SubscriptionManager
  
  @Published var email: String = ""
  @Published var password: String = ""
  @Published var confirmPassword: String = ""
  
  @Published var flow: AuthenticationFlow = .login
  
  @Published var isValid: Bool  = false
  
  @AppStorage("authState") private var authStateRawValue: String = AuthenticationState.unauthenticated.rawValue
  @Published var authenticationState: AuthenticationState = .unauthenticated {
    didSet {
      authStateRawValue = authenticationState.rawValue
    }
  }
  
  
  @Published var errorMessage: String = ""
  @Published var fireUser: User?
  @Published var user: ASUser?
  
  @Published var displayName: String = ""
  
  private var authStateHandler: AuthStateDidChangeListenerHandle?
  private var currentNonce: String?
  private var cancellables = Set<AnyCancellable>()
  
  
  required init(subscriptionManager: SubscriptionManager) {
    self.subscriptionManager = subscriptionManager
    
    // Синхронизация начального значения из @AppStorage
    authenticationState = AuthenticationState(rawValue: authStateRawValue) ?? .unauthenticated
    
    // Слушаем изменения @AppStorage и обновляем @Published
    // Слушаем изменения в authStateRawValue через Combine
    $authenticationState
      .dropFirst() // Избегаем начального вызова при инициализации
      .sink { [weak self] newValue in
        self?.authStateRawValue = newValue.rawValue
      }
      .store(in: &cancellables)
    
    $user
      .sink { newValue in
        guard let userValue = newValue else { return }
        AppLogger.trace("userValue.id \(userValue.id)")
        
        FirestoreStorage.shared.setUserId(userValue.id)
        Storage.shared.setUserID(userValue.id)
      }.store(in: &cancellables)
    
    
    registerAuthStateHandler()
    
    $flow
      .combineLatest($email, $password, $confirmPassword)
      .map { flow, email, password, confirmPassword in
        flow == .login
        ? !(email.isEmpty || password.isEmpty)
        : !(email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
      }
      .assign(to: &$isValid)
  }
  
  private func registerAuthStateHandler() {
    if authStateHandler == nil {
      authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
        self.fireUser = user
        self.authenticationState = user == nil ? .unauthenticated : .authenticated
        self.displayName = user?.email ?? ""
        
        if let uid = user?.uid {
          // Используем SubscriptionManager
          Task {
            await self.subscriptionManager.login(userId: uid)
          }
        }
        
        self.fetchUser(uid: user?.uid)
      }
    }
  }
  
  private func switchFlow() {
    flow = flow == .login ? .signUp : .login
    errorMessage = ""
  }
  
  private func reset() {
    flow = .login
    email = ""
    password = ""
    confirmPassword = ""
  }
  
  //MARK: - General Public Methods
  func signOut() {
    do {
      try Auth.auth().signOut()
      //      Task {
      //        try? await ItemsStorage.shared.deleteAllLocal()
      //      }
    } catch {
      AppLogger.alert(error)
      errorMessage = error.localizedDescription
    }
  }
  
  func deleteAccount() async -> Bool {
    do {
      try await fireUser?.delete()
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }
}

// MARK: - Sign in with Email and Password
extension AuthenticationViewModel {
  func signInWithEmailPassword() async -> Bool {
    authenticationState = .authenticating
    do {
      try await Auth.auth().signIn(withEmail: self.email, password: self.password)
      return true
    } catch {
      AppLogger.alert(error)
      errorMessage = error.localizedDescription
      authenticationState = .unauthenticated
      return false
    }
  }
  
  func signUpWithEmailPassword() async -> Bool {
    authenticationState = .authenticating
    do {
      try await Auth.auth().createUser(withEmail: email, password: password)
      return true
    } catch {
      AppLogger.alert(error)
      errorMessage = error.localizedDescription
      authenticationState = .unauthenticated
      return false
    }
  }
}

extension AuthenticationViewModel {
  func signInAnonymously() async -> Bool {
    authenticationState = .authenticating
    do {
      let authResult = try await Auth.auth().signInAnonymously()
      
      let firebaseUser = authResult.user
      AppLogger.alert("User \(firebaseUser.uid) signed anonymously ")
      
      Task {
        await self.saveUser()
      }
      return true
    } catch {
      AppLogger.alert(error)
      errorMessage = error.localizedDescription
      authenticationState = .unauthenticated
      return false
    }
  }
  
  func linkEmail(email: String, password: String) async throws -> Bool {
    let credential = EmailAuthProvider.credential(withEmail: email, password: password)
    guard let user = Auth.auth().currentUser else {
      throw URLError(.badURL)
    }
    
    do {
      let authResult = try await user.link(with: credential)
      let firebaseUser = authResult.user
      AppLogger.alert("User \(firebaseUser.uid) linked email ")
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }
  
  func linkGoogle() async throws -> Bool {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      fatalError("No client ID found in Firebase configuration")
    }

    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config
    
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let rootViewController = window.rootViewController else {
      AppLogger.alert("There is no root view controller!")
      return false
    }
    
    do {
      let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
      
      let user = userAuthentication.user
      guard let idToken = user.idToken else { throw AuthenticationError.tokenError(message: "ID token missing") }
      let accessToken = user.accessToken
      
      let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString,
                                                     accessToken: accessToken.tokenString)
      
      
      guard let user = Auth.auth().currentUser else {
        throw URLError(.badURL)
      }
      
      do {
        let authResult = try await user.link(with: credential)
        let firebaseUser = authResult.user
        AppLogger.alert("User \(firebaseUser.uid) linked google ")
        
        Task.detached {
          await self.saveUser()
        }
        return true
      } catch {
        errorMessage = error.localizedDescription
        return false
      }
    }
    catch {
      AppLogger.alert(error.localizedDescription)
      self.errorMessage = error.localizedDescription
      return false
    }
  }
  
  func handleLinkWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
    if case .failure(let failure) = result {
      errorMessage = failure.localizedDescription
    } else if case .success(let authorization) = result {
      if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
        guard let nonce = currentNonce else {
          fatalError("Invalid state: a login callback was received, but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
          AppLogger.alert("Unable to fetdch identify token.")
          return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
          AppLogger.alert("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
          return
        }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
        
        guard let user = Auth.auth().currentUser else {
          //          throw URLError(.badURL)
          return
        }
        
        Task {
          do {
            let authResult = try await user.link(with: credential)
            let firebaseUser = authResult.user
            AppLogger.alert("User \(firebaseUser.uid) linked apple ")
            await updateDisplayName(for: authResult.user, with: appleIDCredential)
            
            return true
          } catch {
            errorMessage = error.localizedDescription
            return false
          }
        }
        
        Task {
          do {
            let result = try await Auth.auth().signIn(with: credential)
            await updateDisplayName(for: result.user, with: appleIDCredential)
          } catch {
            AppLogger.alert("Error authenticating: \(error.localizedDescription)")
          }
        }
      }
    }
  }
}

// MARK: - Sign in with Google
extension AuthenticationViewModel {
  func signInWithGoogle() async -> Bool {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      fatalError("No client ID found in Firebase configuration")
    }
    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config
    
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let rootViewController = window.rootViewController else {
      AppLogger.alert("There is no root view controller!")
      return false
    }
    
    do {
      let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
      
      let user = userAuthentication.user
      guard let idToken = user.idToken else { throw AuthenticationError.tokenError(message: "ID token missing") }
      let accessToken = user.accessToken
      
      let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString,
                                                     accessToken: accessToken.tokenString)
      
      let result = try await Auth.auth().signIn(with: credential)
      let firebaseUser = result.user
      AppLogger.alert("User \(firebaseUser.uid) signed in with email \(firebaseUser.email ?? "unknown")")
      
      Task.detached {
        await self.saveUser()
      }
      
      return true
    } catch {
      AppLogger.alert(error.localizedDescription)
      self.errorMessage = error.localizedDescription
      return false
    }
  }
}

// MARK: - Sign in with Apple
extension AuthenticationViewModel {
  func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
    request.requestedScopes = [.fullName, .email]
    let nonce = randomNonceString()
    currentNonce = nonce
    request.nonce = sha256(nonce)
  }
  
  func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
    if case .failure(let failure) = result {
      errorMessage = failure.localizedDescription
    }
    else if case .success(let authorization) = result {
      if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
        guard let nonce = currentNonce else {
          fatalError("Invalid state: a login callback was received, but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
          AppLogger.alert("Unable to fetdch identify token.")
          return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
          AppLogger.alert("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
          return
        }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
        Task {
          do {
            let result = try await Auth.auth().signIn(with: credential)
            await updateDisplayName(for: result.user, with: appleIDCredential)
          }
          catch {
            AppLogger.alert("Error authenticating: \(error.localizedDescription)")
          }
        }
      }
    }
  }
  
  func updateDisplayName(for user: User, with appleIDCredential: ASAuthorizationAppleIDCredential, force: Bool = false) async {
    
    if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
      // current user is non-empty, don't overwrite it
    }
    else {
      let changeRequest = user.createProfileChangeRequest()
      changeRequest.displayName = appleIDCredential.displayName()
      do {
        try await changeRequest.commitChanges()
        self.displayName = Auth.auth().currentUser?.displayName ?? ""
      }
      catch {
        AppLogger.alert("Unable to update the user's displayname: \(error.localizedDescription)")
        errorMessage = error.localizedDescription
      }
    }
  }
  
  func verifySignInWithAppleAuthenticationState() {
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let providerData = Auth.auth().currentUser?.providerData
    if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
      Task {
        do {
          let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
          switch credentialState {
            case .authorized:
              break // The Apple ID credential is valid.
            case .revoked, .notFound:
              // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
              self.signOut()
            default:
              break
          }
        }
        catch {
        }
      }
    }
  }
}

extension ASAuthorizationAppleIDCredential {
  func displayName() -> String {
    return [self.fullName?.givenName, self.fullName?.familyName]
      .compactMap( {$0})
      .joined(separator: " ")
  }
}

// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
private func randomNonceString(length: Int = 32) -> String {
  precondition(length > 0)
  let charset: [Character] =
  Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
  var result = ""
  var remainingLength = length
  
  while remainingLength > 0 {
    let randoms: [UInt8] = (0 ..< 16).map { _ in
      var random: UInt8 = 0
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }
      return random
    }
    
    randoms.forEach { random in
      if remainingLength == 0 {
        return
      }
      
      if random < charset.count {
        result.append(charset[Int(random)])
        remainingLength -= 1
      }
    }
  }
  
  return result
}

private func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashedData = SHA256.hash(data: inputData)
  let hashString = hashedData.compactMap {
    String(format: "%02x", $0)
  }.joined()
  
  return hashString
}

//MARK: - Private Methods
extension AuthenticationViewModel {
  private func saveUser() async {
    guard let fireUser = fireUser else { return }
    
    user = ASUser.fromFBUser(fireUser as GFBUser)
    guard let user = user else { return }
    
    AppLogger.trace("user.id \(user.id)")
    
    // Используем только ItemsStorage, который сам инициирует синхронизацию 
    // с FirestoreItemsStorage при необходимости
    Storage.shared.setUserID(user.id)
    
    // Сохраняем пользователя в ItemsStorage, который сам сохранит в Firestore
    Task {
      do {
        try await Storage.shared.saveUser(user)
      } catch {
        AppLogger.alert(error)
      }
    }
  }
  
  func fetchUser(uid: String?) {
    guard let uid = uid else { return }
    
    // Установить идентификатор пользователя
    AppLogger.notice("uid \(uid)")
    
    // Устанавливаем идентификатор пользователя только один раз
    // ItemsStorage уже имеет проверку на повторный вызов с тем же ID
    let fs = FirestoreStorage.shared
    
    // Запускаем только ItemsStorage, которое само синхронизирует данные
    // с FirestoreItemsStorage, избегая двойной синхронизации
    Storage.shared.setUserID(uid)
    
    // Запустить асинхронную загрузку пользователя
    Task {
      do {
        if let user = try await fs.loadUser() {
          await MainActor.run {
            self.user = user
            AppLogger.notice("User fetched from Firestore")
          }
        }
      } catch {
        AppLogger.critical(error)
      }
    }
  }
}
