//
//  AuthenticationViewModelProtocol.swift
//  FlowMemory
//
//  Created by Daniil Bystrov on 10.12.2024.
//


import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import AuthenticationServices

protocol AuthenticationViewModelProtocol: ObservableObject {
    // Published свойства
  var email: String { get set }
  var password: String { get set }
  var confirmPassword: String { get set }
  var flow: AuthenticationFlow { get set }
  var isValid: Bool { get }
  var authenticationState: AuthenticationState { get set }
  var errorMessage: String { get set }
  var fireUser: User? { get set }
  var user: ASUser? { get set }
  var displayName: String { get set }

    // Инициализация
  init(subscriptionManager: SubscriptionManager)

    // Основные методы
  func signInWithEmailPassword() async -> Bool
  func signUpWithEmailPassword() async -> Bool
  func signInAnonymously() async -> Bool
  func signOut()
  func deleteAccount() async -> Bool
  
  func linkEmail(email: String, password: String) async throws -> Bool
  func linkGoogle() async throws -> Bool
  func handleLinkWithAppleCompletion(_ result: Result<ASAuthorization, Error>)

  func signInWithGoogle() async -> Bool
  func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest)
  func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>)
  
  func verifySignInWithAppleAuthenticationState()
  func fetchUser(uid: String?)
}

//protocol AuthenticationViewModelProtocol: ObservableObject {
//    // Published свойства
//    var email: String { get set }
//    var password: String { get set }
//    var confirmPassword: String { get set }
//    var flow: AuthenticationFlow { get set }
//    var isValid: Bool { get }
//    var authenticationState: AuthenticationState { get set }
//    var errorMessage: String { get set }
//    var fireUser: User? { get set }
//    var user: DTNUser? { get set }
//    var displayName: String { get set }
//    
//    // Инициализация
//    init(subscriptionManager: SubscriptionManager)
//    
//    // Методы
//    func signInWithEmailPassword() async -> Bool
//    func signUpWithEmailPassword() async -> Bool
//    func signInAnonymously() async -> Bool
//    func linkEmail(email: String, password: String) async throws -> Bool
//    func linkGoogle() async throws -> Bool
//    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest)
//    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>)
//    func signOut()
//    func deleteAccount() async -> Bool
//    func verifySignInWithAppleAuthenticationState()
//    
//    // Вспомогательные методы
//    func fetchUser(uid: String?)
//}
