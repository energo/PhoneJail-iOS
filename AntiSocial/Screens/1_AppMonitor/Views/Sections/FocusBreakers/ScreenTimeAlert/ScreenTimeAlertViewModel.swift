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
          // Check subscription before starting
          if checkSubscriptionAndStart() {
            startMonitoring()
          } else {
            // Reset toggle if subscription check fails
            DispatchQueue.main.async {
              self.isAlertEnabled = false
            }
          }
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
  private let subscriptionManager = SubscriptionManager.shared
  
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
  
  private func checkSubscriptionAndStart() -> Bool {
    if !subscriptionManager.canUseAlertsToday() {
      return false
    }
    
    // Mark the day as used
    subscriptionManager.markAlertDayUsed()
    return true
  }
  
  func startMonitoring() {
    let timeLimitMinutes = selectedTime.minutes
    
    AppLogger.notice("startMonitoring alert with timeLimitMinutes: \(timeLimitMinutes)")
    updateMonitoringState()
    
    // Reset usage counters when starting fresh monitoring
    SharedData.resetAppUsageTimes()
    
    // Get enabled tokens
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
    // Update the model's selection with only enabled tokens
    var updatedSelection = model.activitySelection
    updatedSelection.applicationTokens = enabledTokens
    
    // Save the updated selection before starting monitoring
    SharedData.selectedAlertActivity = updatedSelection
    AppLogger.notice("Saved alert selection with \(enabledTokens.count) enabled apps (from \(model.activitySelection.applicationTokens.count) total)")
    
    // Verify saved data
    if let savedSelection = SharedData.selectedAlertActivity {
      AppLogger.notice("Verified saved selection has \(savedSelection.applicationTokens.count) apps")
    }
    
    // Create event with threshold
    var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
    
    let event = DeviceActivityEvent(
      applications: enabledTokens,
      categories: updatedSelection.categoryTokens,
      webDomains: updatedSelection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes)
      // Don't include includesPastActivity - default is false, which is what we want
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
        
        // Send notification on successful start
        LocalNotificationManager.scheduleExtensionNotification(
          title: "✅ Screen Time Alerts Enabled",
          details: "You'll be notified after \(timeLimitMinutes) minutes of app use"
        )
      } catch let error {
        AppLogger.critical(error, details: "Failed to start alert monitoring")
      }
    }
  }
  
  func stopMonitoring() {
    center.stopMonitoring([.appMonitoringAlert])
    
    // Reset all usage counters when stopping monitoring
    SharedData.resetAppUsageTimes()
    
    // Send notification about disabling
    LocalNotificationManager.scheduleExtensionNotification(
      title: "🛑 Screen Time Alerts Disabled",
      details: "You will no longer receive app usage notifications"
    )
    
    AppLogger.notice("Stopped alert monitoring and reset usage counters")
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
          // Check subscription before starting
          if self.checkSubscriptionAndStart() {
            self.startMonitoring()
          } else {
            // Reset toggle if subscription check fails
            DispatchQueue.main.async {
              self.model.isEnabled = false
            }
          }
        } else if oldValue == true && newValue == false {
          self.stopMonitoring()
        }
      }
    )
  }
}
