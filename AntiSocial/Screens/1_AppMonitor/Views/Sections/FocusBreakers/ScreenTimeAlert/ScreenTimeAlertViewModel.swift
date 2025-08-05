//
//  ScreenTimeAlertViewModel.swift
//  AntiSocial
//
//  Created by Assistant on 2025.
//

import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

class ScreenTimeAlertViewModel: ObservableObject {
  @AppStorage(SharedData.ScreenTime.isAlertEnabled, store: SharedData.userDefaults) var isAlertEnabled: Bool = false {
    didSet {
      if oldValue != isAlertEnabled {
        if oldValue == false && isAlertEnabled == true {
          startMonitoring()
        } else if oldValue == true && isAlertEnabled == false {
          stopMonitoring()
        }
      }
    }
  }
  
  @Published var model: SelectAppsModel
  
  @AppStorage(SharedData.ScreenTime.selectedTime, store: SharedData.userDefaults) var selectedTime: TimeIntervalOption = TimeIntervalOption.timeOptions[0]
  
  @Published var pickerIsPresented = false
  @Published var showSocialMediaHint = false
  @Published var monitoredApps: [MonitoredApp] = []
  
  let center = DeviceActivityCenter()
  
  //MARK: - Init
  init() {
    self.model = SelectAppsModel(mode: .alert)
    
    // Load saved selection
    if let savedSelection = SharedData.selectedAlertActivity {
      model.activitySelection = savedSelection
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
    AppLogger.trace("Изменился выбор приложений для alert")
    updateMonitoredAppsList()
    
    // Save selection to SharedData
    SharedData.selectedAlertActivity = model.activitySelection
  }
  
  func toggleAppMonitoring(app: MonitoredApp) {
    if let index = monitoredApps.firstIndex(where: { $0.token == app.token }) {
      monitoredApps[index].isMonitored.toggle()
      updateMonitoringState()
    }
  }
  
  func startMonitoring() {
    let timeLimitMinutes = selectedTime.minutes
    
    AppLogger.notice("startMonitoring alert with timeLimitMinutes: \(timeLimitMinutes)")
    updateMonitoringState()
    
    // Save selection before starting monitoring
    SharedData.selectedAlertActivity = model.activitySelection
    AppLogger.notice("Saved alert selection with \(model.activitySelection.applicationTokens.count) apps")
    
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
    // Create event with threshold
    var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
    
    let event = DeviceActivityEvent(
      applications: enabledTokens,
      categories: model.activitySelection.categoryTokens,
      webDomains: model.activitySelection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes)
    )
    
    events[DeviceActivityEvent.Name.screenAlert] = event
    
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
      repeats: true
    )
    
    // Run monitoring setup off main thread to prevent blocking
    Task {
      do {
        AppLogger.notice("Starting alert monitoring with threshold: \(timeLimitMinutes) minutes")
        try self.center.startMonitoring(.appMonitoringAlert,
                                   during: schedule,
                                   events: events)
      } catch let error {
        AppLogger.critical(error, details: "Failed to start alert monitoring")
      }
    }
  }
  
  func stopMonitoring() {
    center.stopMonitoring([.appMonitoringAlert])
    AppLogger.notice("Stopped alert monitoring")
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
    SharedData.selectedAlertActivity = selection
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
