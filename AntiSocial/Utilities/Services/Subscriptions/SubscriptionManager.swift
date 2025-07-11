//
//  SettingsVM.swift
//  Flashcards
//
//  Created by Daniil Bystrov on 03.08.2024.
//

import Foundation
import SwiftUI

import RevenueCat
import Firebase

enum SubscriptionManagerError: Error {
  case firebaseAnalticsError
  case restoreFailed
  case purchaseFailed
  case noProductsFound
}


class SubscriptionManager: ObservableObject, SubscriptionManagerProtocol {
  struct Constants {
    /*
     The API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
     */
    static let apiKey = "appl_xHDwwaqjicDtYkIWMWgOpPQHVcF"
    
    /*
     The entitlement ID from the RevenueCat dashboard that is activated upon successful in-app purchase for the duration of the purchase.
     */
    static let entitlementID = "Pro"
  }
  
  public static let shared = SubscriptionManager()
  @Published public var isRestoringPurchases = false
  
//  @Published public var isSubscriptionActive = (FCUserDefaults.shared.get(key: .isSubscribed) ?? false) as! Bool ? true : false
  @Published public var isSubscriptionActive: Bool

  
  private var usageCounters: [String: Int] {
    get {
      if let data = FCUserDefaults.shared.get(key: .usageCounters) as? [String: Int] {
        return data
      }
      return [:]
    }
    set {
      FCUserDefaults.shared.set(newValue, key: .usageCounters)
    }
  }
  
  init() {
    AppLogger.notice("SubscriptionManager init")
    let savedStatus = FCUserDefaults.shared.get(key: .isSubscribed) as? Bool ?? false
    self.isSubscriptionActive = savedStatus

    configureRevenueCat()
    addFirebaseAnalytcis()
  
    refreshSubscription()
    Task {
//      async let _: () = self.syncPurchases()
      async let _: () = self.listenUpdates()
    }
//    Task {
//      await syncPurchases()
//    }
//    
//    Task.detached {
//      await self.listenUpdates()
//    }
  }
  
  /// Sync purchases and update subscription status
  @MainActor
  func syncPurchases() async {
      do {
          let customerInfo = try await Purchases.shared.syncPurchases()
          let isActive = customerInfo.entitlements.all[Constants.entitlementID]?.isActive == true
          
          updateSubscriptionStatus(isActive)
          AppLogger.alert("Purchases synced successfully. Active: \(isActive)")
          
      } catch {
          AppLogger.critical(error, details: "Failed to sync purchases")
      }
  }

  
  @MainActor
  func restorePurchases() async throws {
    isRestoringPurchases = true
    defer { isRestoringPurchases = false }
    
    do {
      let customerInfo = try await Purchases.shared.restorePurchases()
      let isActive = customerInfo.entitlements.all[Constants.entitlementID]?.isActive == true
      
      updateSubscriptionStatus(isActive)
      
      AppLogger.alert("Purchases restored successfully. Active: \(isActive)")
      
      if !isActive {
        throw SubscriptionManagerError.restoreFailed
      }
      
    } catch {
      AppLogger.critical(error, details: "Failed to restore purchases")
      throw SubscriptionManagerError.restoreFailed
    }
  }
  
  @MainActor
  private func updateSubscriptionStatus(_ isActive: Bool) {
    if isSubscriptionActive != isActive {
      isSubscriptionActive = isActive
      FCUserDefaults.shared.set(isActive, key: .isSubscribed)
      AppLogger.alert("Subscription status updated: \(isActive)")
    }
  }
  
  func limit(for type: LimitType) -> (count: Int, delay: TimeInterval) {
    return type.value(isSubscriptionActive: isSubscriptionActive)
  }
  
  func limitDetails(for type: LimitType) -> (remainingCount: Int, remainingTime: TimeInterval) {
    let limit = type.value(isSubscriptionActive: isSubscriptionActive)
    let currentUsage = usageCounters[type.rawValue, default: 0]
    
    // Если лимит бесконечен, возвращаем максимальные значения
    if limit.count == Int.max {
      return (Int.max, 0)
    }
    
    // Обработка лимитов с таймером
    //    if let timerKey = type.timerKey {
    //      if let lastDate = FCUserDefaults.shared.get(key: timerKey) as? Date {
    //        let elapsedTime = Date().timeIntervalSince(lastDate)
    //        let remainingTime = max(0, limit.delay - elapsedTime)
    //
    //          // Если время истекло, сбрасываем счетчик
    //        if remainingTime <= 0 {
    //          resetUsage(for: type)
    //          return (limit.count, 0)
    //        }
    //
    //          // Рассчитываем оставшиеся попытки
    //        let remainingCount = max(0, limit.count - currentUsage)
    //        return (remainingCount, remainingTime)
    //      } else {
    //          // Если данных о последнем использовании нет, возвращаем полный лимит
    //        return (limit.count, 0)
    //      }
    //    }
    
    // Обработка лимитов без таймера
    return (max(0, limit.count - currentUsage), 0)
  }
  
  func incrementUsage(for type: LimitType, _ incrementor: Int = 1) {
    let key = type.rawValue
    var counters = usageCounters
    counters[key, default: 0] += incrementor
    usageCounters = counters
    
    // Устанавливаем таймер, если лимит имеет задержку
    //    if let timerKey = type.timerKey {
    //      FCUserDefaults.shared.set(Date(), key: timerKey)
    //    }
  }
  
  func setUsage(for type: LimitType, _ counter: Int = 1) {
    let key = type.rawValue
    var counters = usageCounters
    counters[key, default: 0] = counter
    usageCounters = counters
    
    // Устанавливаем таймер, если лимит имеет задержку
    //    if let timerKey = type.timerKey {
    //      FCUserDefaults.shared.set(Date(), key: timerKey)
    //    }
  }
  
  func resetUsage(for type: LimitType) {
    let key = type.rawValue
    var counters = usageCounters
    counters[key] = 0
    usageCounters = counters
    
    // Удаляем таймер, если он есть
    //    if let timerKey = type.timerKey {
    //      FCUserDefaults.shared.set(nil, key: timerKey)
    //    }
  }
  
  func currentUsage(for type: LimitType) -> Int {
    //    if let timerKey = type.timerKey {
    //      if let lastDate = FCUserDefaults.shared.get(key: timerKey) as? Date {
    //        let elapsedTime = Date().timeIntervalSince(lastDate)
    //        let limit = type.value(isSubscriptionActive: isSubscriptionActive)
    //
    //          // Если время ожидания истекло, сбрасываем счетчик
    //        if elapsedTime >= limit.delay {
    //          resetUsage(for: type)
    //          return 0
    //        }
    //      }
    //    }
    
    return usageCounters[type.rawValue, default: 0]
  }
  
  func resetAllUsages() {
    for type in LimitType.allCases {
      SubscriptionManager.shared.resetUsage(for: type)
    }
  }
  
  //  func canImportDeck() -> (canImport: Bool, remainingTime: TimeInterval) {
  //    let details = limitDetails(for: .maxImportBoards)
  //    return (details.remainingCount > 0, details.remainingTime)
  //  }
  
  func login(userId: String) async {
    do {
      let (customerInfo, _) = try await Purchases.shared.logIn(userId)
      //      shared.updateSubscriptionStatus(using: customerInfo)
      let isActive = (customerInfo.entitlements.all[Constants.entitlementID]?.isActive == true)
      
      await MainActor.run {
        updateSubscriptionStatus(isActive)
      }
      
      //      Paywall.identify(userId: userId)
    } catch {
      AppLogger.critical(error, details: "A RevenueCat error occurred")
    }
    
  }
  
  /**
   The current user ID is no longer valid for your instance of *Purchases* since the user is logging out, and is no longer authorized to access customerInfo for that user ID.
   
   `logOut` clears the cache and regenerates a new anonymous user ID.
   
   - Note: Each time you call `logOut`, a new installation will be logged in the RevenueCat dashboard as that metric tracks unique user ID's that are in-use. Since this method generates a new anonymous ID, it counts as a new user ID in-use.
   */
  
  func logout() async {
    do {
      _ = try await Purchases.shared.logOut()
      await MainActor.run {
        self.isSubscriptionActive = false
      }
    } catch {
      AppLogger.critical(error, details:"Error during logout")
    }
  }
  
  //MARK: - Private Methods
  private func configureRevenueCat() {
    Purchases.logLevel = .error
    Purchases.configure(withAPIKey: Constants.apiKey)
  }
  
  private func listenUpdates() async {
    for try await customerInfo in Purchases.shared.customerInfoStream {
      let isActive = (customerInfo.entitlements.all[Constants.entitlementID]?.isActive == true)
      AppLogger.alert("listenUpdates subscription isActive = \(isActive)")
      
      await MainActor.run {
        if isSubscriptionActive != isActive {
          self.isSubscriptionActive = isActive
          FCUserDefaults.shared.set(isActive, key: .isSubscribed)
        }
      }
    }
  }

  func refreshSubscription() {
      Purchases.shared.getCustomerInfo { (customerInfo, error) in
          guard error == nil, let customerInfo = customerInfo else {
              AppLogger.alert("Error refreshing subscription: \(String(describing: error))")
              return
          }
          let isActive = (customerInfo.entitlements.all[Constants.entitlementID]?.isActive == true)
          DispatchQueue.main.async {
              if self.isSubscriptionActive != isActive {
                  self.isSubscriptionActive = isActive
                  FCUserDefaults.shared.set(isActive, key: .isSubscribed)
              }
          }
      }
  }
  
  private func addFirebaseAnalytcis() {
    let instanceID = Analytics.appInstanceID()
    if let unwrapped = instanceID {
      //      AppLogger.alert("Instance ID -> " + unwrapped)
      Purchases.shared.attribution.setFirebaseAppInstanceID(unwrapped)
    } else {
      AppLogger.critical(SubscriptionManagerError.firebaseAnalticsError, details: "Firebase Analytics instance ID not found!")
    }
  }
}
