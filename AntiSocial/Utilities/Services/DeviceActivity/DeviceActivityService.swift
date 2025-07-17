import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import UserNotifications

struct AppEntity: Codable, Identifiable {
  var id = UUID()
  var name: String
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
    if let startTimestamp = SharedDataConstants.userDefaults?.double(forKey: SharedDataConstants.AppBlocking.currentBlockingStartTimestamp) {
      let elapsed = Date().timeIntervalSince1970 - startTimestamp
      let hours = Int(elapsed) / 3600
      let minutes = (Int(elapsed) % 3600) / 60
      return String(format: "%02dh %02dm", hours, minutes)
    }
    return "00h 00m"
  }
  
  // MARK: - Init
  init() {
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
    if let unlock = Calendar.current.date(from: components), unlock > now {
      unlockDate = unlock
    } else if let unlock = Calendar.current.date(from: components) {
      unlockDate = Calendar.current.date(byAdding: .day, value: 1, to: unlock)
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
    guard let unlockDate = unlockDate else { return "--:--:--" }
    
    let dateFormatted = DeviceActivityService.logDateFormatter.string(from: unlockDate)
//    AppLogger.notice("\n[MyModel] timeRemainingString: \(dateFormatted)")
    
    let remaining = Int(unlockDate.timeIntervalSinceNow)
    if remaining <= 0 { return "00:00:00" }
    let hours = remaining / 3600
    let minutes = (remaining % 3600) / 60
    let seconds = remaining % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }
  
  private func saveUnlockDate() {
    if let date = unlockDate {
      print("[MyModel] saveUnlockDate: \(date)")
      UserDefaults.standard.set(date, forKey: unlockDateKey)
    } else {
      print("[MyModel] saveUnlockDate: nil (removing)")
      UserDefaults.standard.removeObject(forKey: unlockDateKey)
    }
  }
  
  private func loadUnlockDate() {
    if let date = UserDefaults.standard.object(forKey: unlockDateKey) as? Date {
      print("[MyModel] loadUnlockDate: \(date)")
      unlockDate = date
    } else {
      print("[MyModel] loadUnlockDate: nil")
    }
  }
  
  // MARK: - FamilyActivitySelection Save/Load
  func saveFamilyActivitySelection(_ selection: FamilyActivitySelection) {
    selectionToDiscourage = selection
    if let data = try? encoder.encode(selection) {
      UserDefaults.standard.set(data, forKey: selectionKey)
    }
  }
  
  func loadSelection() {
    if let data = UserDefaults.standard.data(forKey: selectionKey),
       let loaded = try? decoder.decode(FamilyActivitySelection.self, from: data) {
      selectionToDiscourage = loaded
    }
  }
  
  // MARK: - AppEntity Save/Load
  func loadApps() {
    if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
      do {
        let decoded = try JSONDecoder().decode([AppEntity].self, from: data)
        self.savedSelection = decoded
      } catch {
        print("Failed to decode apps: \(error)")
        self.savedSelection = []
      }
    }
  }
  
  func saveApps() {
    do {
      let data = try JSONEncoder().encode(savedSelection)
      UserDefaults.standard.set(data, forKey: userDefaultsKey)
    } catch {
      print("Failed to encode apps: \(error)")
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
  
  // MARK: - Helpers
  func countSelectedAppCategory() -> Int {
    return selectionToDiscourage.categoryTokens.count
  }
  func countSelectedApp() -> Int {
    return selectionToDiscourage.applicationTokens.count
  }
  
  // MARK: - Singleton
  class var sharedInstance: DeviceActivityService { shared }
}

extension ManagedSettingsStore.Name {
  static let mySettingStore = Self("mySettingStore")
}
