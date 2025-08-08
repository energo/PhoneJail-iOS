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
  case weeklyBlocks
  case weeklyInterruptionDays
  case weeklyAlertDays
  
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
      case .weeklyBlocks:
        return isSubscriptionActive ? (Int.max, 0) : (3, 0) // 3 free blocks per week
      case .weeklyInterruptionDays:
        return isSubscriptionActive ? (Int.max, 0) : (1, 0) // 1 free day per week  
      case .weeklyAlertDays:
        return isSubscriptionActive ? (Int.max, 0) : (1, 0) // 1 free day per week
    }
  }
}

