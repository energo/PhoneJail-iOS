import Foundation
import WidgetKit
import FamilyControls
import ManagedSettings
import DeviceActivity
import UserNotifications

extension ManagedSettingsStore.Name {
//  static let mySettingStore = Self("mySettingStore")
  static let appBlocking = Self("appBlocking")
  static let interruption = Self("interruption")
}

class ShieldService: ObservableObject {
  // MARK: - Settings Store
  let store = ManagedSettingsStore(named: .appBlocking)
  static let shared = ShieldService()

  // MARK: - Published Properties
  @Published var selectionToDiscourage: FamilyActivitySelection
  @Published var unlockDate: Date? = nil {
    didSet { saveUnlockDate() }
  }
  
  var timeBlockedString: String {
    if let startTimestamp = SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp) {
      let elapsed = Date().timeIntervalSince1970 - startTimestamp
      
      // Валидация: если elapsed > 24 часов или отрицательное, что-то пошло не так
      guard elapsed >= 0 && elapsed < 86400 else {
//        AppLogger.alert("DeviceActivityService: Invalid elapsed time: \(elapsed) seconds from timestamp: \(startTimestamp)")
        // Очищаем некорректный timestamp
        SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
        return "0h 00m"
      }
      
      let hours = Int(elapsed) / 3600
      let minutes = (Int(elapsed) % 3600) / 60
      return String(format: "%dh %02dm", hours, minutes)
    }
    return "0h 00m"
  }
  
  // MARK: - Init
 private init() {
    selectionToDiscourage = FamilyActivitySelection()

    loadSelection()
    loadUnlockDate()
  }
  
  // MARK: - Unlock Date
  func setUnlockDate(hour: Int, minute: Int) {
    let now = Date()
    var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
    components.hour = hour
    components.minute = minute
    components.second = 0
    let newUnlockDate: Date?
    if let unlock = Calendar.current.date(from: components), unlock > now {
      newUnlockDate = unlock
    } else if let unlock = Calendar.current.date(from: components) {
      newUnlockDate = Calendar.current.date(byAdding: .day, value: 1, to: unlock)
    } else {
      newUnlockDate = nil
    }
    
    Task { @MainActor in
      unlockDate = newUnlockDate
    }
  }
  
  static var logDateFormat = "HH:mm:ss.SSS"
  static var logDateFormatter: DateFormatter {
      let formatter = DateFormatter()
      formatter.dateFormat = logDateFormat
      formatter.locale = Locale.autoupdatingCurrent
      formatter.timeZone = TimeZone.autoupdatingCurrent
      return formatter
  }
  
  var timeRemainingString: String {
    guard let unlockDate = unlockDate else { return "0:00:00" }
    
//    let dateFormatted = DeviceActivityService.logDateFormatter.string(from: unlockDate)
//    AppLogger.notice("\n[MyModel] timeRemainingString: \(dateFormatted)")
    
    let remaining = Int(unlockDate.timeIntervalSinceNow)
    if remaining <= 0 { return "0:00:00" }
    let hours = remaining / 3600
    let minutes = (remaining % 3600) / 60
    let seconds = remaining % 60
    
    return String(format: "%d:%02d:%02d", hours, minutes, seconds)
  }
  
  private func saveUnlockDate() {
    if let date = unlockDate {
      SharedData.userDefaults?.set(date, forKey: SharedData.AppBlocking.unlockDate)
    } else {
      SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.unlockDate)
    }
  }
  
  func loadUnlockDate() {
    if let sharedDate = SharedData.userDefaults?.object(forKey: SharedData.AppBlocking.unlockDate) as? Date {
      unlockDate = sharedDate
    }
  }
  
  // MARK: - FamilyActivitySelection Save/Load
  func saveFamilyActivitySelection(_ selection: FamilyActivitySelection) {
    Task { @MainActor in
      selectionToDiscourage = selection
    }

    SharedData.selectedBlockingActivity = selection
  }
  
  func saveFamilyActivitySelectionAsync(_ selection: FamilyActivitySelection) async {
    await MainActor.run {
      selectionToDiscourage = selection
    }

    SharedData.selectedBlockingActivity = selection
  }
  
  func loadSelection() {
    if let sharedSelection = SharedData.selectedBlockingActivity {
      // Load from SharedData if available
      selectionToDiscourage = sharedSelection
      // Save to UserDefaults for future use
      saveFamilyActivitySelection(selectionToDiscourage)
    }
  }

  // MARK: - Shield Restrictions
  func setShieldRestrictions(_ isStricted: Bool = false) {
    let applications = selectionToDiscourage
    store.shield.applications = applications.applicationTokens.isEmpty ? nil : applications.applicationTokens
    store.shield.applicationCategories = applications.categoryTokens.isEmpty
    ? nil
    : ShieldSettings.ActivityCategoryPolicy.specific(applications.categoryTokens)
    
    store.application.denyAppRemoval = isStricted
  }
  
  func setShieldRestrictions(for selection: FamilyActivitySelection) {
    store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
    store.shield.applicationCategories = selection.categoryTokens.isEmpty
    ? nil
    : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
  }
  
  func setShieldRestrictions(for selection: FamilyActivitySelection, storeName: ManagedSettingsStore.Name) {
    let customStore = ManagedSettingsStore(named: storeName)
    customStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
    customStore.shield.applicationCategories = selection.categoryTokens.isEmpty
    ? nil
    : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
  }
  
  func setShieldRestrictionsAsync(_ isStricted: Bool = false) async {
    await withCheckedContinuation { continuation in
      setShieldRestrictions(isStricted)
      continuation.resume()
    }
  }
  
  func startAppRestrictions(_ isStricted: Bool = false) {
    stopAppRestrictions()
    setShieldRestrictions(isStricted)
    store.media.denyExplicitContent = true
    if isStricted {
      store.application.denyAppRemoval = true
    }
    store.dateAndTime.requireAutomaticDateAndTime = true
    store.application.blockedApplications = selectionToDiscourage.applications
  }
  
  func stopAppRestrictions() {
    print("stopAppRestrictions")
    store.application.blockedApplications = nil
    store.clearAllSettings()
    WidgetCenter.shared.reloadAllTimelines()
  }
  
  func stopAppRestrictions(storeName: ManagedSettingsStore.Name) {
    print("stopAppRestrictions(storeName")
    let customStore = ManagedSettingsStore(named: storeName)
    customStore.application.blockedApplications = nil
    customStore.clearAllSettings()
    WidgetCenter.shared.reloadAllTimelines()
  }
  
  // MARK: - Helpers
  func countSelectedAppCategory() -> Int {
    return selectionToDiscourage.categoryTokens.count
  }
  
  func countSelectedApp() -> Int {
    return selectionToDiscourage.applicationTokens.count
  }
}
