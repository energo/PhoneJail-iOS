//
//  FocusTimeSavingService.swift
//  AntiSocialApp
//
//

import Foundation
import Combine

class FocusTimeSavingService: NSObject {
  static var shared: FocusTimeSavingService = FocusTimeSavingService()
  
  private var cancellables: Set<AnyCancellable> = []
  
  // MARK: - Setup
  func setupSubscriptions() {
    cancellables.removeAll()
    NotificationCenter.default
          .publisher(for: UserDefaults.didChangeNotification,
                     object: SharedData.userDefaults)
          .map { _ in SharedData.userDefaults?.data(forKey: SharedData.AppBlocking.firebasePendingUpdateData) }
          .removeDuplicates()
          .receive(on: DispatchQueue.main)
          .sink { newValue in
            guard
              let newValue,
              let decoded = try? JSONDecoder().decode(PendingFocusTimeUpdates.self, from: newValue)
            else {
              return
            }
            
            SharedData.userDefaults?.set(nil, forKey: SharedData.AppBlocking.firebasePendingUpdateData)
            
            Task {
              try await FirestoreStorage.shared.saveFocusTimeStats(
                decoded.global,
                dailyStats: decoded.daily,
                hourlyStats: decoded.hourly
              )
            }
          }
          .store(in: &cancellables)
  }
}
