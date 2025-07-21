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
    
    // MARK: - Request permission to use ScreenTime API
    /// To use the ScreenTime API, permission must be requested first.
    /// This method requests permission to use the ScreenTime API and updates the hasScreenTimePermission property.
    @MainActor
    func requestAuthorization() {
        if authorizationCenter.authorizationStatus == .approved {
            print("ScreenTime Permission approved")
        } else {
            Task {
                do {
                    try await authorizationCenter.requestAuthorization(for: .individual)
                    hasScreenTimePermission = true
                    // Consent given
                } catch {
                    // Consent not given
                    print("Failed to enroll Aniyah with error: \(error)")
                    hasScreenTimePermission = false
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
                print("Success")
            case .failure(let failure):
                print("\(failure) - failed revoke Permission")
            }
        })
    }
    
    // MARK: - Update permission status
    /// Method to update the state of hasScreenTimePermission
    func updateAuthorizationStatus(authStatus: AuthorizationStatus) {
        switch authStatus {
        case .notDetermined:
            hasScreenTimePermission = false
        case .denied:
            hasScreenTimePermission = false
        case .approved:
            hasScreenTimePermission = true
        @unknown default:
            fatalError("No handling exists for the requested permission type")
        }
    }
}
