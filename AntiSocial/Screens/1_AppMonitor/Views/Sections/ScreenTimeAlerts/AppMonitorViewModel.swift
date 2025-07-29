import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity
import WidgetKit

class AppMonitorViewModel: ObservableObject {
  @AppStorage("isInterruptionsEnabled") var isInterruptionsEnabled: Bool = false {
    didSet {
        if oldValue == false && isInterruptionsEnabled == true {
            startMonitoring()
        } else if oldValue == true && isInterruptionsEnabled == false {
            stopInterruptionMonitoring()
        }
    }
  }

  @AppStorage("isAlertEnabled") var isAlertEnabled: Bool = false {
      didSet {
          if oldValue == false && isAlertEnabled == true {
              startMonitoring()
          } else if oldValue == true && isAlertEnabled == false {
              stopAlertMonitoring()
          }
      }
  }
  
  @Published var model: SelectAppsModel
  
  @AppStorage("selectedFrequency") var selectedFrequency: FrequencyOption = FrequencyOption.frequencyOptions[0]
  @AppStorage("selectedTime") var selectedTime: TimeIntervalOption = TimeIntervalOption.timeOptions[0]

  @Published var pickerIsPresented = false
  @Published var showSocialMediaHint = false
  @Published var monitoredApps: [MonitoredApp] = []

  let center = DeviceActivityScheduleService.center

  //MARK: - Init
  init(model: SelectAppsModel) {
    self.model = model
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
    print("Изменился выбор приложений в модели")
    updateMonitoredAppsList()
  }
  
  func toggleAppMonitoring(app: MonitoredApp) {
    if let index = monitoredApps.firstIndex(where: { $0.token == app.token }) {
      monitoredApps[index].isMonitored.toggle()
      updateMonitoringState()
    }
  }
  
  func startMonitoring() {
    let timeLimitMinutes = isInterruptionsEnabled ? selectedFrequency.minutes : selectedTime.minutes
    
    print("startMonitoring timeLimitMinutes: \(timeLimitMinutes)")
    updateMonitoringState()
    
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
    // Create multiple events with increasing thresholds to trigger multiple times
    var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
    
    // Create up to 10 events for the day (covers 10 triggers)
    for i in 1...10 {
      let eventName = isInterruptionsEnabled 
        ? DeviceActivityEvent.Name("\(DeviceActivityEvent.Name.interruption.rawValue)_\(i)")
        : DeviceActivityEvent.Name("\(DeviceActivityEvent.Name.screenAlert.rawValue)_\(i)")
      
      let event = DeviceActivityEvent(
        applications: enabledTokens,
        categories: model.activitySelection.categoryTokens,
        webDomains: model.activitySelection.webDomainTokens,
        threshold: DateComponents(minute: timeLimitMinutes * i) // Cumulative thresholds
      )
      
      events[eventName] = event
    }
    
    let activity = isInterruptionsEnabled ? DeviceActivityName.appMonitoringInterruption : DeviceActivityName.appMonitoringAlert
    let schedule = schedule24h()
    
    DispatchQueue.main.async {
      do {
        print("startMonitoring \(activity) with \(events.count) events")
        try self.center.startMonitoring(activity,
                                   during: schedule,
                                   events: events)
      } catch let error {
        print("center.startMonitoring error \(error.localizedDescription)")
      }
    }
  }
  
  func stopInterruptionMonitoring() {
    let center = DeviceActivityCenter()
    center.stopMonitoring([.appMonitoringInterruption])
    
    // Clear any active restrictions from interruptions
    DeviceActivityService.shared.stopAppRestrictions()
    
    // Also stop any active blocking schedule
    DeviceActivityScheduleService.stopSchedule()
    
    // Reset blocking state completely
    resetInterruptionBlockingState()
    
    print("Stopped interruption monitoring and cleared all restrictions")
  }
  
  func stopAlertMonitoring() {
    let center = DeviceActivityCenter()
    center.stopMonitoring([.appMonitoringAlert])
    print("Stopped alert monitoring")
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
    // Clear all shared data related to interruption blocking
    SharedDataConstants.userDefaults?.set(false, forKey: SharedDataConstants.Widget.isBlocked)
    SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.AppBlocking.currentBlockingStartTimestamp)
    SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endHour)
    SharedDataConstants.userDefaults?.removeObject(forKey: SharedDataConstants.Widget.endMinutes)
    
    // Clear device activity service state
    let service = DeviceActivityService.shared
    service.selectionToDiscourage = FamilyActivitySelection()
    service.savedSelection.removeAll()
    service.saveFamilyActivitySelection(service.selectionToDiscourage)
    service.unlockDate = nil
    
    // Reload widgets
    WidgetCenter.shared.reloadAllTimelines()
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
