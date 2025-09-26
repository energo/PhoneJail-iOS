//
//  FirestoreItemsStorage.swift
//  AntiSocial
//

import Foundation
import FirebaseFirestore

final class FirestoreStorage {
  static let shared = FirestoreStorage()
  internal let db = Firestore.firestore()
  private var userId: String?

  private init() {}

  func setUserId(_ id: String) {
    self.userId = id
  }

  internal func ensureUserId() throws -> String {
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

  func deleteUser() async throws {
    let id = try ensureUserId()
    try await db.collection("users").document(id).delete()
  }
}

// MARK: - FocusTime
extension FirestoreStorage {
  func focusTimeDateFormatter() -> DateFormatter {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      return formatter
  }
  
  func saveFocusTimeStats(
    _ item: GlobalFocusTimeStats,
    dailyStats: [String : DailyStats] = [:],
    hourlyStats: [String : HourlyStats] = [:]
  ) async throws {
    let userId = try ensureUserId()
    try await db.collection("focusTime").document(userId).setData(from: item, merge: true)
    
    for daily in dailyStats {
      try await db
        .collection("focusTime")
        .document(userId)
        .collection("dailyStats")
        .document(daily.key)
        .setData(from: daily.value, merge: true)
    }
    
    for hourly in hourlyStats {
      try await db
        .collection("focusTime")
        .document(userId)
        .collection("hourlyStats")
        .document(hourly.key)
        .setData(from: hourly.value, merge: true)
    }
  }

  func loadGlobalFocusTimeStats() async throws -> GlobalFocusTimeStats {
    let userId = try ensureUserId()
    let document = try await db.collection("focusTime").document(userId).getDocument()
    
    return try document.data(as: GlobalFocusTimeStats.self)
  }
  
  func loadDailyFocusTimeStats() async throws -> [DailyStats] {
    let userId = try ensureUserId()
    
    let query = db
      .collection("focusTime")
      .document(userId)
      .collection("dailyStats")

    let snapshot = try await query.getDocuments()
    return snapshot.documents.compactMap { try? $0.data(as: DailyStats.self) }
  }
  
  func loadHourlyFocusTimeStats() async throws -> [DailyStats] {
    let userId = try ensureUserId()
    
    let query = db
      .collection("focusTime")
      .document(userId)
      .collection("hourlyStats")

    let snapshot = try await query.getDocuments()
    return snapshot.documents.compactMap { try? $0.data(as: DailyStats.self) }
  }

  func deleteFocusTimeStats() async throws {
    let userId = try ensureUserId()
    try await db.collection("focusTime").document(userId).delete()
  }
}
