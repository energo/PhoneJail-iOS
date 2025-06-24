//
//  ItemsStorage.swift
//  AntiSocial
//
//  Created by D C on 13.03.2024.
//


import Foundation
import Firebase
import Combine
import GRDB

enum SyncState {
  case idle
  case syncing
  case completed
  case failed(Error)
}

enum SyncMode {
  case smart
  case force
}

final class Storage: ObservableObject {
  static let shared = Storage()

  private let cache = GRDBStorage.shared
  private let cloud = FirestoreStorage.shared

  private var userId: String?

  @Published var user: ASUser?
  @Published var syncState: SyncState = .idle

  private init() {}

  // MARK: - User ID

  func setUserID(_ userID: String) {
    guard self.userId != userID else { return }
    self.userId = userID
    cache.setUserId(userID)
    cloud.setUserId(userID)

    Task {
      do {
        try await cache.ensureDatabaseSchema()
        user = try await loadUser()
      } catch {
        AppLogger.critical(error, details: "Init error")
      }
    }
  }

  func ensureUserID() throws -> String {
    guard let id = userId else {
      throw NSError(domain: "ItemsStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "userId not set"])
    }
    return id
  }

  // MARK: - User

  func saveUser(_ user: ASUser) async throws {
    try await cache.saveUser(user)
    try await cloud.saveUser(user)
    self.user = user

    if self.userId == nil {
      setUserID(user.id)
    }
  }

  func loadUser() async throws -> ASUser? {
    if let local = try await cache.loadUser() {
      return local
    }
    if let remote = try await cloud.loadUser() {
      try await cache.saveUser(remote)
      return remote
    }
    return nil
  }

  func deleteUser() async throws {
    _ = try ensureUserID()
    try await cache.deleteUser()
    try await cloud.deleteUser()
    self.user = nil
    self.userId = nil
  }
}
