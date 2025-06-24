//
//  LimitType.swift
//  FlowMemory
//
//  Created by Daniil Bystrov on 25.11.2024.
//

import Foundation

enum LimitType: String, CaseIterable {
  case maxToDoItems
  case maxHabits
  case maxGoals
  case maxAffirmations
  
  func value(isSubscriptionActive: Bool) -> (count: Int, delay: TimeInterval) {
    switch self {
      case .maxToDoItems:
        return isSubscriptionActive ? (Int.max, 0) : (6, 0)
      case .maxHabits:
        return isSubscriptionActive ? (Int.max, 0) : (1, 0)
      case .maxGoals:
        return isSubscriptionActive ? (Int.max, 0) : (1, 0)
      case .maxAffirmations:
        return isSubscriptionActive ? (Int.max, 0) : (30, 0)
    }
  }
}

