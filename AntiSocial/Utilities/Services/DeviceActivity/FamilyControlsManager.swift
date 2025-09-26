//
//  FamilyControlsManager.swift
//  AntiSocial
//
//  Created by D C on 21.07.2025.
//

import Foundation
import FamilyControls

class FamilyControlsManager: ObservableObject {
  static let shared = FamilyControlsManager()
  private init() {}
  
  // MARK: - Object managing the FamilyControls permission state
  let authorizationCenter = AuthorizationCenter.shared
  
  // MARK: - Member variable to utilize ScreenTime permission state
  @Published var hasScreenTimePermission: Bool = false
  @Published var hasDeniedPermissionRequest: Bool = false
  
  // MARK: - Request permission to use ScreenTime API
  /// To use the ScreenTime API, permission must be requested first.
  /// This method requests permission to use the ScreenTime API and updates the hasScreenTimePermission property.
  @MainActor
  func requestAuthorization() {
    if authorizationCenter.authorizationStatus == .approved {
      AppLogger.notice("ScreenTime Permission approved")
      hasScreenTimePermission = true
      hasDeniedPermissionRequest = false
      
    } else {
      Task {
        do {
          try await authorizationCenter.requestAuthorization(for: .individual)
          hasScreenTimePermission = true
          hasDeniedPermissionRequest = false
          AppLogger.notice("ScreenTime Permission approved")
        } catch {
          // Consent not given
          AppLogger.critical(error, details: "Failed to enroll")
          hasScreenTimePermission = false
          hasDeniedPermissionRequest = true
          // The user did not allow.
          // Error Domain=FamilyControls.FamilyControlsError Code=5 "(null)"
        }
      }
    }
  }
  
  // MARK: - Check ScreenTime permission
  /// This method checks the current permission status of the ScreenTime API when called.
  func requestAuthorizationStatus() -> AuthorizationStatus {
    authorizationCenter.authorizationStatus
  }
  
  // MARK: - Cancel ScreenTime permission
  /// If the current permission status is `.approved`, this method sets it to `.notDetermined`.
  func requestAuthorizationRevoke() {
    authorizationCenter.revokeAuthorization(completionHandler: { result in
      switch result {
        case .success:
          AppLogger.notice("Success")
        case .failure(let failure):
          AppLogger.critical(nil, details: "\(failure) - failed revoke Permission")
      }
    })
  }
  
  // MARK: - Update permission status
  /// Method to update the state of hasScreenTimePermission
  func updateAuthorizationStatus(authStatus: AuthorizationStatus) {
    switch authStatus {
      case .notDetermined:
        hasScreenTimePermission = false
        hasDeniedPermissionRequest = false
      case .denied:
        hasScreenTimePermission = false
        hasDeniedPermissionRequest = true
      case .approved:
        hasScreenTimePermission = true
        hasDeniedPermissionRequest = false
      @unknown default:
        fatalError("No handling exists for the requested permission type")
    }
  }
}
