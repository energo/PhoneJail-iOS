import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity
import WidgetKit

class AppMonitorViewModel: ObservableObject {
  @AppStorage(SharedData.ScreenTime.isInterruptionsEnabled, store: SharedData.userDefaults) var isInterruptionsEnabled: Bool = false {
    didSet {
        if oldValue == false && isInterruptionsEnabled == true {
            startMonitoring()
        } else if oldValue == true && isInterruptionsEnabled == false {
            stopInterruptionMonitoring()
        }
    }
  }

  @AppStorage(SharedData.ScreenTime.isAlertEnabled, store: SharedData.userDefaults) var isAlertEnabled: Bool = false {
      didSet {
          if oldValue == false && isAlertEnabled == true {
              startMonitoring()
          } else if oldValue == true && isAlertEnabled == false {
              stopAlertMonitoring()
          }
      }
  }
  
  @Published var model: SelectAppsModel
  
  @AppStorage(SharedData.ScreenTime.selectedInterruptionTime, store: SharedData.userDefaults) var selectedInterruptionTime: TimeIntervalOption = TimeIntervalOption.timeOptions[1]  // Default 5 mins
  @AppStorage(SharedData.ScreenTime.selectedTime, store: SharedData.userDefaults) var selectedTime: TimeIntervalOption = TimeIntervalOption.timeOptions[0]

  @Published var pickerIsPresented = false
  @Published var showSocialMediaHint = false
  @Published var monitoredApps: [MonitoredApp] = []

  let center = DeviceActivityScheduleService.center

  //MARK: - Init
  init(model: SelectAppsModel) {
    self.model = model
    
    // Load saved selection based on mode
    if model.mode == .interruptions {
      if let savedSelection = SharedData.selectedInterruptionsActivity {
        model.activitySelection = savedSelection
      }
    } else if model.mode == .alert {
      if let savedSelection = SharedData.selectedAlertActivity {
        model.activitySelection = savedSelection
      }
    }
  }
  
  @MainActor
  func onAppear() async {
    let tokens = self.model.activitySelection.applicationTokens
    monitoredApps = tokens.map { token in
      MonitoredApp(token: token, isMonitored: true)
    }
  }
  
  func showSelectApps() {
    self.pickerIsPresented = true
  }
  
  func onActivitySelectionChange() {
    AppLogger.trace("Изменился выбор приложений в модели")
    updateMonitoredAppsList()
    
    // Save selection to SharedData based on mode
    if model.mode == .interruptions {
      SharedData.selectedInterruptionsActivity = model.activitySelection
    } else if model.mode == .alert {
      SharedData.selectedAlertActivity = model.activitySelection
    }
  }
  
  func toggleAppMonitoring(app: MonitoredApp) {
    if let index = monitoredApps.firstIndex(where: { $0.token == app.token }) {
      monitoredApps[index].isMonitored.toggle()
      updateMonitoringState()
    }
  }
  
  func startMonitoring() {
    let timeLimitMinutes = isInterruptionsEnabled ? selectedInterruptionTime.minutes : selectedTime.minutes
    
    AppLogger.notice("startMonitoring timeLimitMinutes: \(timeLimitMinutes)")
    updateMonitoringState()
    
    // Save selection to SharedData before starting monitoring
    if model.mode == .interruptions {
      SharedData.selectedInterruptionsActivity = model.activitySelection
      AppLogger.notice("Saved interruptions selection with \(model.activitySelection.applicationTokens.count) apps")
    } else if model.mode == .alert {
      SharedData.selectedAlertActivity = model.activitySelection
      AppLogger.notice("Saved alert selection with \(model.activitySelection.applicationTokens.count) apps")
    }
    
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
    // Create a single event with the threshold
    var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
    
    let eventName = isInterruptionsEnabled 
      ? DeviceActivityEvent.Name.interruption
      : DeviceActivityEvent.Name.screenAlert
    
    let event = DeviceActivityEvent(
      applications: enabledTokens,
      categories: model.activitySelection.categoryTokens,
      webDomains: model.activitySelection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes)
    )
    
    events[eventName] = event
    
    let activity = isInterruptionsEnabled ? DeviceActivityName.appMonitoringInterruption : DeviceActivityName.appMonitoringAlert
    let schedule = schedule24h()
    
    // Run monitoring setup off main thread to prevent blocking
    Task {
      do {
        AppLogger.notice("startMonitoring \(activity) with threshold: \(timeLimitMinutes) minutes")
        try self.center.startMonitoring(activity,
                                   during: schedule,
                                   events: events)
      } catch let error {
        AppLogger.critical(error, details: "center.startMonitoring error")
      }
    }
  }
  
  func stopInterruptionMonitoring() {
    let center = DeviceActivityCenter()
    center.stopMonitoring([.appMonitoringInterruption])
    
    // Clear any active restrictions from interruptions
    DeviceActivityService.shared.stopAppRestrictions(storeName: .interruption)
    
    // Also stop any active interruption blocking schedule
    DeviceActivityScheduleService.stopInterruptionSchedule()
    
    // Reset blocking state completely
    resetInterruptionBlockingState()
    
    AppLogger.notice("Stopped interruption monitoring and cleared all restrictions")
  }
  
  func stopAlertMonitoring() {
    let center = DeviceActivityCenter()
    center.stopMonitoring([.appMonitoringAlert])
    AppLogger.notice("Stopped alert monitoring")
  }
  
  func stopMonitoring() {
    // Stop monitoring based on what's currently enabled
    if isInterruptionsEnabled {
      stopInterruptionMonitoring()
    }
    if isAlertEnabled {
      stopAlertMonitoring()
    }
  }
  
  private func resetInterruptionBlockingState() {
    // Clear only interruption-specific data
    SharedData.userDefaults?.removeObject(forKey: SharedData.ScreenTime.isInterruptionBlock)
    SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.lastInterruptionBlockTime)
    
    // Clear interruption restrictions
    DeviceActivityService.shared.stopAppRestrictions(storeName: .interruption)
    
    // Don't touch main blocking state or selectionToDiscourage
  }
  
  func schedule24h() -> DeviceActivitySchedule {
    return DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
      repeats: true
    )
  }
  
  private func updateMonitoredAppsList() {
    let tokens = self.model.activitySelection.applicationTokens
    monitoredApps = tokens.map { token in
      MonitoredApp(token: token, isMonitored: true)
    }
  }
  
  private func updateMonitoringState() {
    let enabledApps: Set<ApplicationToken> = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    var selection = self.model.activitySelection
    selection.applicationTokens = enabledApps
    self.model.activitySelection = selection
    
    // Save updated selection to SharedData
    if model.mode == .interruptions {
      SharedData.selectedInterruptionsActivity = selection
    } else if model.mode == .alert {
      SharedData.selectedAlertActivity = selection
    }
  }

  var toggleBinding: Binding<Bool> {
    Binding<Bool>(
      get: { self.model.isEnabled },
      set: { newValue in
        let oldValue = self.model.isEnabled
        self.model.isEnabled = newValue
        if oldValue == false && newValue == true {
          self.startMonitoring()
        } else if oldValue == true && newValue == false {
          self.stopMonitoring()
        }
      }
    )
  }
}
