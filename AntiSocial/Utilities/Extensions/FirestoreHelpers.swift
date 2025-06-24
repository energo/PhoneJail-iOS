//
//  FirestoreHelpers.swift
//  AntiSocialApp
//
//  Created by D C on 24.06.2025.
//

import Foundation
import FirebaseFirestore


/// Use only for simple Codable models (e.g., Feedback, BugReport).
/// Avoid for user models with custom nested fields or arrays.
extension FirebaseFirestore.DocumentReference {
  func setData<T: Encodable>(from value: T, merge: Bool = false) async throws {
    let encoder = Firestore.Encoder()
    let data = try encoder.encode(value)
    try await setData(data, merge: merge)
  }
}
