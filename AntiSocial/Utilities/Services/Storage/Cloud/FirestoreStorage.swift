//
//  FirestoreItemsStorage.swift
//  AntiSocial
//

import Foundation
import FirebaseFirestore

final class FirestoreStorage {
  static let shared = FirestoreStorage()
  private let db = Firestore.firestore()
  private var userId: String?

  private init() {}

  func setUserId(_ id: String) {
    self.userId = id
  }

  private func ensureUserId() throws -> String {
    guard let id = userId else {
      throw NSError(domain: "FirestoreItemsStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "userId not set"])
    }
    return id
  }
  
  func saveUser(_ user: ASUser) async throws {
    let userId = try ensureUserId()
    let userRef = db.collection("users").document(userId)

    let data: [String: Any] = [
      "id": user.id,
      "name": user.name,
      "email": user.email,
      "imageURL": user.imageURL?.absoluteString ?? NSNull(),
      "lastUpdated": Timestamp(date: user.lastUpdated),
      "isAnonymous": user.isAnonymous
    ]

    try await userRef.setData(data, merge: true)
  }

  func loadUser() async throws -> ASUser? {
    let userId = try ensureUserId()
    let document = try await db.collection("users").document(userId).getDocument()
    
    guard let dict = document.data() else { return nil }

    return ASUser(
      id: dict["id"] as? String ?? userId,
      name: dict["name"] as? String ?? "",
      email: dict["email"] as? String ?? "",
      imageURL: (dict["imageURL"] as? String).flatMap(URL.init),
      lastUpdated: (dict["lastUpdated"] as? Timestamp)?.dateValue() ?? Date(),
      isAnonymous: dict["isAnonymous"] as? Bool ?? false
    )
  }

//  func saveUser(_ user: ASUser) async throws {
//    let ref = db.collection("users").document(user.id)
//    try await ref.setData(from: user, merge: true)
//  }

//  func loadUser() async throws -> ASUser? {
//    let id = try ensureUserId()
//    let doc = try await db.collection("users").document(id).getDocument()
//    return try doc.data(as: ASUser.self)
//  }

  func deleteUser() async throws {
    let id = try ensureUserId()
    try await db.collection("users").document(id).delete()
  }
}
