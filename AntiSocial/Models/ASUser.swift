//
//  ASUser.swift
//  AntiSocial
//
//


import Foundation
import GoogleSignIn
import FirebaseAuth
import GRDB

struct ASUser: Identifiable, Codable, Hashable, FetchableRecord, PersistableRecord {
  static let databaseTableName = "users"
  
  var id: String
  var name: String
  var email: String
  
  var imageURL: URL?
  var lastUpdated: Date
  var isAnonymous: Bool
  
  //additional data
  var agreedToDataStorage: Bool?
  var agreedToDataProcessing: Bool?
  var mainGoal: String?
  
  enum CodingKeys: String, CodingKey {
    case id, name, email
    case imageURL, lastUpdated, isAnonymous
    case agreedToDataStorage, agreedToDataProcessing, mainGoal
  }
  
  init(id: String,
       name: String,
       email: String,
       imageURL: URL? = nil,
       lastUpdated: Date = Date(),
       isAnonymous: Bool = false,
       
       agreedToDataStorage: Bool? = nil,
       agreedToDataProcessing: Bool? = nil,
       mainGoal: String? = nil
  )
  {
    self.id = id
    self.name = name
    self.email = email
    self.imageURL = imageURL
    self.lastUpdated = lastUpdated
    self.isAnonymous = isAnonymous
    
    self.agreedToDataStorage = agreedToDataStorage
    self.agreedToDataProcessing = agreedToDataProcessing
    self.mainGoal = mainGoal
  }
  
  // MARK: - Codable
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    email = try container.decode(String.self, forKey: .email)
    
    imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
    lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    isAnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnonymous) ?? false
    
    agreedToDataStorage = try container.decodeIfPresent(Bool.self, forKey: .agreedToDataStorage)
    agreedToDataProcessing = try container.decodeIfPresent(Bool.self, forKey: .agreedToDataProcessing)
    mainGoal = try container.decodeIfPresent(String.self, forKey: .mainGoal)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(email, forKey: .email)
    
    try container.encodeIfPresent(imageURL, forKey: .imageURL)
    try container.encode(lastUpdated, forKey: .lastUpdated)
    try container.encode(isAnonymous, forKey: .isAnonymous)
    
    try container.encodeIfPresent(agreedToDataStorage, forKey: .agreedToDataStorage)
    try container.encodeIfPresent(agreedToDataProcessing, forKey: .agreedToDataProcessing)
    try container.encodeIfPresent(mainGoal, forKey: .mainGoal)
  }
}

// MARK: - Init from providers
extension ASUser {
  static func fromGoogleUser(_ gUser: GIDGoogleUser) -> ASUser? {
    guard let userID = gUser.userID else { return nil }
    return ASUser(
      id: userID,
      name: gUser.profile?.name ?? "",
      email: gUser.profile?.email ?? "",
      isAnonymous: false
    )
  }
  
  static func fromFBUser(_ fUser: GFBUser) -> ASUser {
    ASUser(
      id: fUser.uid,
      name: fUser.displayName ?? "no name",
      email: fUser.email ?? "no email",
      isAnonymous: fUser.isAnonymous
    )
  }
}

// MARK: - Mock
extension ASUser {
  static func mock(id: String = UUID().uuidString,
                   name: String = "Mock User",
                   email: String = "mock@example.com",
                   imageURL: URL? = nil,
                   lastUpdated: Date = Date(),
                   isAnonymous: Bool = false) -> ASUser {
    ASUser(
      id: id,
      name: name,
      email: email,
      imageURL: imageURL,
      lastUpdated: lastUpdated,
      isAnonymous: isAnonymous
    )
  }
}
