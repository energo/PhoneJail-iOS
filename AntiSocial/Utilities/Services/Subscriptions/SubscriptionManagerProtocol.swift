//
//  SubscriptionManagerProtocol.swift
//  FlowMemory
//
//  Created by Daniil Bystrov on 10.12.2024.
//

import Foundation
import Combine

protocol SubscriptionManagerProtocol: ObservableObject {
  var isSubscriptionActive: Bool { get set }
  
  func limit(for type: LimitType) -> (count: Int, delay: TimeInterval)
  func limitDetails(for type: LimitType) -> (remainingCount: Int, remainingTime: TimeInterval)
  func incrementUsage(for type: LimitType, _ incrementor: Int)
  func resetUsage(for type: LimitType)
  func currentUsage(for type: LimitType) -> Int
  func resetAllUsages()
  //    func canImportDeck() -> (canImport: Bool, remainingTime: TimeInterval)
  func login(userId: String) async
  func logout() async
  func refreshSubscription()
}
