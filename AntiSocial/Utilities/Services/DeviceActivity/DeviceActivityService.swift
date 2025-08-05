import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import UserNotifications

struct AppEntity: Codable, Identifiable {
  var id = UUID()
  var name: String
}


extension ManagedSettingsStore.Name {
  static let mySettingStore = Self("mySettingStore")
  static let appBlocking = Self("appBlocking")
  static let interruption = Self("interruption")
}

class DeviceActivityService: ObservableObject {
  // MARK: - Settings Store
  let store = ManagedSettingsStore(named: .mySettingStore)
  static let shared = DeviceActivityService()

  // MARK: - Published Properties
  @Published var selectionToDiscourage: FamilyActivitySelection
  @Published var selectionToEncourage: FamilyActivitySelection
  @Published var savedSelection: [AppEntity] = [] {
    didSet { saveApps() }
  }
  @Published var unlockDate: Date? = nil {
    didSet { saveUnlockDate() }
  }
  
  // MARK: - UserDefaults Keys
  private let userDefaultsKey = "savedSelection"
  private let selectionKey = "ScreenTimeSelection"
  private let unlockDateKey = "UnlockDate"
  
  // MARK: - Encoder/Decoder
  private let encoder = PropertyListEncoder()
  private let decoder = PropertyListDecoder()
  
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
    selectionToEncourage = FamilyActivitySelection()
    loadApps()
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
//      AppLogger.trace("[MyModel] saveUnlockDate: \(date)")
      UserDefaults.standard.set(date, forKey: unlockDateKey)
      // Also save to SharedData for extensions
      SharedData.userDefaults?.set(date, forKey: SharedData.AppBlocking.unlockDate)
    } else {
//      AppLogger.trace("[MyModel] saveUnlockDate: nil (removing)")
      UserDefaults.standard.removeObject(forKey: unlockDateKey)
      SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.unlockDate)
    }
  }
  
  func loadUnlockDate() {
    // First try to load from UserDefaults
    if let date = UserDefaults.standard.object(forKey: unlockDateKey) as? Date {
//      AppLogger.trace("[MyModel] loadUnlockDate: \(date)")
      unlockDate = date
    } 
    // Also check SharedData for unlock date
    else if let sharedDate = SharedData.userDefaults?.object(forKey: SharedData.AppBlocking.unlockDate) as? Date {
//      AppLogger.trace("[MyModel] loadUnlockDate from SharedData: \(sharedDate)")
      unlockDate = sharedDate
      // Sync to UserDefaults
      UserDefaults.standard.set(sharedDate, forKey: unlockDateKey)
    } else {
//      AppLogger.trace("[MyModel] loadUnlockDate: nil")
    }
  }
  
  // MARK: - FamilyActivitySelection Save/Load
  func saveFamilyActivitySelection(_ selection: FamilyActivitySelection) {
    Task { @MainActor in
      selectionToDiscourage = selection
    }
    if let data = try? encoder.encode(selection) {
      UserDefaults.standard.set(data, forKey: selectionKey)
    }
    // Also save to SharedData for persistence
    SharedData.selectedBlockingActivity = selection
  }
  
  func saveFamilyActivitySelectionAsync(_ selection: FamilyActivitySelection) async {
    await MainActor.run {
      selectionToDiscourage = selection
    }
    if let data = try? encoder.encode(selection) {
      UserDefaults.standard.set(data, forKey: selectionKey)
    }
    // Also save to SharedData for persistence
    SharedData.selectedBlockingActivity = selection
  }
  
  func loadSelection() {
    if let data = UserDefaults.standard.data(forKey: selectionKey),
       let loaded = try? decoder.decode(FamilyActivitySelection.self, from: data) {
      selectionToDiscourage = loaded
    } else if let sharedSelection = SharedData.selectedBlockingActivity {
      // Load from SharedData if available
      selectionToDiscourage = sharedSelection
      // Save to UserDefaults for future use
      saveFamilyActivitySelection(selectionToDiscourage)
    }
  }
  
  // MARK: - AppEntity Save/Load
  func loadApps() {
    if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
      do {
        let decoded = try JSONDecoder().decode([AppEntity].self, from: data)
        self.savedSelection = decoded
      } catch {
//        AppLogger.critical(error, details: "Failed to decode apps")
        self.savedSelection = []
      }
    }
  }
  
  func saveApps() {
    do {
      let data = try JSONEncoder().encode(savedSelection)
      UserDefaults.standard.set(data, forKey: userDefaultsKey)
    } catch {
//      AppLogger.critical(error, details: "Failed to encode apps")
    }
  }
  
  func addApp(name: String) {
    let newApp = AppEntity(name: name)
    savedSelection.append(newApp)
  }
  
  func deleteAllApps() {
    savedSelection.removeAll()
  }
  
  // MARK: - Shield Restrictions
  func setShieldRestrictions() {
    let applications = selectionToDiscourage
    store.shield.applications = applications.applicationTokens.isEmpty ? nil : applications.applicationTokens
    store.shield.applicationCategories = applications.categoryTokens.isEmpty
    ? nil
    : ShieldSettings.ActivityCategoryPolicy.specific(applications.categoryTokens)
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
  
  func setShieldRestrictionsAsync() async {
    await withCheckedContinuation { continuation in
      setShieldRestrictions()
      continuation.resume()
    }
  }
  
  func startAppRestrictions() {
    stopAppRestrictions()
    setShieldRestrictions()
    store.media.denyExplicitContent = true
    store.application.denyAppRemoval = true
    store.dateAndTime.requireAutomaticDateAndTime = true
    store.application.blockedApplications = selectionToDiscourage.applications
  }
  
  func stopAppRestrictions() {
    store.clearAllSettings()
  }
  
  func stopAppRestrictions(storeName: ManagedSettingsStore.Name) {
    let customStore = ManagedSettingsStore(named: storeName)
    customStore.clearAllSettings()
  }
  
  // MARK: - Helpers
  func countSelectedAppCategory() -> Int {
    return selectionToDiscourage.categoryTokens.count
  }
  
  func countSelectedApp() -> Int {
    return selectionToDiscourage.applicationTokens.count
  }
}
