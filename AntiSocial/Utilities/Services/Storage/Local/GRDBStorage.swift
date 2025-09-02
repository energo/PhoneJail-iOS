//
//  GRDBItemsStorage.swift
//  AntiSocial
//

import Foundation
import GRDB

final class GRDBStorage {
  static let shared = GRDBStorage()
  internal var writer: DatabaseWriter?
  private var userId: String?
  
  private init() {
    do {
      let url = try FileManager.default
        .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent("AntiSocial.sqlite")
      writer = try DatabaseQueue(path: url.path)
      try setupDatabase()
    } catch {
      AppLogger.critical(error, details: "GRDB Init Error")
    }
  }
  
  func setUserId(_ id: String) {
    self.userId = id
  }
  
  private func ensureUserId() throws -> String {
    guard let id = userId else {
      throw NSError(domain: "GRDBItemsStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "userId not set"])
    }
    return id
  }
  
  private func setupDatabase() throws {
    try writer?.write { db in
      try db.create(table: ASUser.databaseTableName, ifNotExists: true) { t in
        t.column("id", .text).primaryKey()
        t.column("name", .text)
        t.column("email", .text)
        t.column("imageURL", .text)
        t.column("lastUpdated", .date)
        t.column("isAnonymous", .boolean)
        t.column("agreedToDataStorage", .boolean)
        t.column("agreedToDataProcessing", .boolean)
        t.column("mainGoal", .text)
      }
    }
  }
  
  func saveUser(_ user: ASUser) async throws {
    try await writer?.write { db in
      var u = user
      u.lastUpdated = Date()
      try u.save(db)
    }
  }
  
  func loadUser() async throws -> ASUser? {
    let id = try ensureUserId()
    return try await writer?.read { db in
      try ASUser
        .filter(key: id)
        .fetchOne(db)
    }
  }
  
  func deleteUser() async throws {
    let id = try ensureUserId()
    try await writer?.write { db in
      _ = try ASUser.filter(key: id).deleteAll(db)
    }
  }
  
  func ensureDatabaseSchema() async throws {
    try await writer?.write { db in
      let userTableExists = try self.tableExists(db, tableName: ASUser.databaseTableName)
      
      if !userTableExists {
        try self.setupDatabase()
      }
    }
  }
  
  private func tableExists(_ db: Database, tableName: String) throws -> Bool {
    let count = try Int.fetchOne(db, sql: """
      SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?
      """, arguments: [tableName])
    return count ?? 0 > 0
  }
}
