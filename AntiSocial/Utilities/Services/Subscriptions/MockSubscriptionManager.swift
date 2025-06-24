//
//  MockSubscriptionManager.swift
//  FlowMemory
//
//  Created by Daniil Bystrov on 10.12.2024.
//

import Foundation
import Combine

class MockSubscriptionManager: SubscriptionManagerProtocol {
  
  @Published var isSubscriptionActive: Bool = false
  private var mockUsageCounters: [String: Int] = [:]
  private var mockLimits: [LimitType: (count: Int, delay: TimeInterval)] = [:]
  private var mockLimitDetails: [LimitType: (remainingCount: Int, remainingTime: TimeInterval)] = [:]

  func setMockLimit(for type: LimitType, count: Int, delay: TimeInterval) {
    mockLimits[type] = (count, delay)
  }

  func setMockLimitDetails(for type: LimitType, remainingCount: Int, remainingTime: TimeInterval) {
    mockLimitDetails[type] = (remainingCount, remainingTime)
  }

  func limit(for type: LimitType) -> (count: Int, delay: TimeInterval) {
    return mockLimits[type] ?? (count: 5, delay: 60) // Значения по умолчанию
  }

  func limitDetails(for type: LimitType) -> (remainingCount: Int, remainingTime: TimeInterval) {
    return mockLimitDetails[type] ?? (remainingCount: 3, remainingTime: 30) // Значения по умолчанию
  }
  
  func incrementUsage(for type: LimitType, _ incrementor: Int) {
    let key = type.rawValue
    mockUsageCounters[key, default: 0] += incrementor
  }


  func resetUsage(for type: LimitType) {
    let key = type.rawValue
    mockUsageCounters[key] = 0
  }

  func currentUsage(for type: LimitType) -> Int {
    return mockUsageCounters[type.rawValue, default: 0]
  }

  func resetAllUsages() {
    mockUsageCounters.removeAll()
  }

  func canImportDeck() -> (canImport: Bool, remainingTime: TimeInterval) {
    return (true, 0) // Пример мока: можно импортировать без ограничений
  }

  func login(userId: String) async {
    isSubscriptionActive = true // Пример мока: при входе подписка становится активной
  }

  func logout() async {
    isSubscriptionActive = false // Пример мока: при выходе подписка отключается
  }

  func refreshSubscription() {
    isSubscriptionActive.toggle() // Пример мока: переключение состояния подписки
  }
}
