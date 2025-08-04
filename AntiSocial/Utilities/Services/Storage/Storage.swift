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
        AppLogger.notice("user \(String(describing: user))")
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
  
  // MARK: - App Blocking Methods
  
  func saveBlockingSession(_ session: AppBlockingSession) async throws {
    try await cache.saveBlockingSession(session)
    try await cloud.saveBlockingSession(session)
  }
  
  func getBlockingSessions(for userId: String) async throws -> [AppBlockingSession] {
    return try await cache.getBlockingSessions(for: userId)
  }
  
  func getActiveBlockingSessions(for userId: String) async throws -> [AppBlockingSession] {
    return try await cache.getActiveBlockingSessions(for: userId)
  }
  
  func getDailyBlockingStats(for userId: String, date: Date) async throws -> [DailyAppBlockingStats] {
    return try await cache.getDailyBlockingStats(for: userId, date: date)
  }
  
  func getBlockingStatsForPeriod(for userId: String, from: Date, to: Date) async throws -> [DailyAppBlockingStats] {
    return try await cache.getBlockingStatsForPeriod(for: userId, from: from, to: to)
  }
  
  func getTopBlockedApps(for userId: String, limit: Int) async throws -> [(appName: String, totalDuration: TimeInterval)] {
    return try await cache.getTopBlockedApps(for: userId, limit: limit)
  }
  
  func updateBlockingSession(_ session: AppBlockingSession) async throws {
    try await cache.updateBlockingSession(session)
    try await cloud.saveBlockingSession(session)  // Просто сохраняем заново в облаке
  }
  
  func saveDailyBlockingStats(_ stats: DailyAppBlockingStats) async throws {
    try await cache.saveDailyBlockingStats(stats)
    try await cloud.saveDailyBlockingStats(stats)
  }
  
  func deleteOldBlockingData(olderThan date: Date) async throws {
    let userId = try ensureUserID()
    try await cache.deleteOldBlockingData(olderThan: date)
    try await cloud.deleteOldBlockingData(for: userId, olderThan: date)
  }
  
  func getAllBlockingStats(for userId: String) async throws -> [DailyAppBlockingStats] {
    return try await cache.getAllBlockingStats(for: userId)
  }
  
  /// Обновить дневную статистику на основе завершенной сессии
  func updateDailyStatsForSession(_ session: AppBlockingSession) async throws {
    try await cache.updateDailyStatsForSession(session)
    
    // Получаем обновленную статистику и синхронизируем с облаком
    let stats = try await cache.getDailyBlockingStats(for: session.userId, date: session.startDate)
    for stat in stats {
      if stat.appDisplayName == session.appDisplayName {
        try await cloud.saveDailyBlockingStats(stat)
        break
      }
    }
  }
}
