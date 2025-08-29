//
//  AppInterruptionViewModel.swift
//  AntiSocial
//
//  Created by Assistant on 2025.
//

import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

class AppInterruptionViewModel: ObservableObject {
  @AppStorage(SharedData.ScreenTime.isInterruptionsEnabled, store: SharedData.userDefaults) var isInterruptionsEnabled: Bool = false {
    didSet {
      if oldValue != isInterruptionsEnabled {
        if oldValue == false && isInterruptionsEnabled == true {
          // Check subscription before starting
          if checkSubscriptionAndStart() {
            startMonitoring()
          } else {
            // Reset toggle if subscription check fails
            DispatchQueue.main.async {
              self.isInterruptionsEnabled = false
            }
          }
        } else if oldValue == true && isInterruptionsEnabled == false {
          stopMonitoring()
        }
      }
    }
  }
  
  @Published var model: SelectAppsModel
  
  @AppStorage(SharedData.ScreenTime.selectedInterruptionTime, store: SharedData.userDefaults) var selectedInterruptionTime: TimeIntervalOption = TimeIntervalOption.timeOptions[1]  // Default 5 mins
  
  @Published var pickerIsPresented = false
  @Published var showSocialMediaHint = false
  @Published var monitoredApps: [MonitoredApp] = []
  
  let center = DeviceActivityCenter()
  private let subscriptionManager = SubscriptionManager.shared
  
  //MARK: - Init
  init() {
    self.model = SelectAppsModel(mode: .interruptions)
    
    // Load saved selection
    if let savedSelection = SharedData.selectedInterruptionsActivity {
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
    AppLogger.trace("Изменился выбор приложений для interruptions")
    updateMonitoredAppsList()
    
    // Save selection to SharedData
    SharedData.selectedInterruptionsActivity = model.activitySelection
  }
  
  func toggleAppMonitoring(app: MonitoredApp) {
    if let index = monitoredApps.firstIndex(where: { $0.token == app.token }) {
      monitoredApps[index].isMonitored.toggle()
      updateMonitoringState()
    }
  }
  
  private func checkSubscriptionAndStart() -> Bool {
    if !subscriptionManager.canUseInterruptionsToday() {
      return false
    }
    
    // Mark the day as used
    subscriptionManager.markInterruptionDayUsed()
    return true
  }
  
  func startMonitoring() {
    let timeLimitMinutes = selectedInterruptionTime.minutes
    
    AppLogger.notice("startMonitoring interruptions with timeLimitMinutes: \(timeLimitMinutes)")
    updateMonitoringState()
    
    // Save selection before starting monitoring
    SharedData.selectedInterruptionsActivity = model.activitySelection
    AppLogger.notice("Saved interruptions selection with \(model.activitySelection.applicationTokens.count) apps")
    
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
        
    // Create event with threshold
    var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
    
    // ВАЖНО: Создаем ОДИН event со ВСЕМИ приложениями
    // iOS будет считать ОБЩЕЕ время использования ВСЕХ приложений
    // Это ограничение iOS API - мы не можем узнать какое конкретное приложение использовалось
    let event = DeviceActivityEvent(
      applications: enabledTokens,  // ВСЕ выбранные приложения
      categories: model.activitySelection.categoryTokens,
      webDomains: model.activitySelection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes)
    )
    
    events[DeviceActivityEvent.Name.interruption] = event
    
    AppLogger.notice("Created interruption event with \(enabledTokens.count) apps. iOS will track TOTAL usage!")
    
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
      repeats: true
    )
    
    // Run monitoring setup off main thread to prevent blocking
    Task {
      do {
        AppLogger.notice("Starting interruption monitoring with threshold: \(timeLimitMinutes) minutes")
        try self.center.startMonitoring(.appMonitoringInterruption,
                                   during: schedule,
                                   events: events)
        
        // Send notification on successful start
        LocalNotificationManager.scheduleExtensionNotification(
          title: "✅ App Interruptions Enabled",
          details: "Apps will be blocked for 2 minutes every \(timeLimitMinutes) minutes of use"
        )
      } catch let error {
        AppLogger.critical(error, details: "Failed to start interruption monitoring")
      }
    }
  }
  
  func stopMonitoring() {
    center.stopMonitoring([.appMonitoringInterruption])
    
    // Clear any active restrictions from interruptions
    DeviceActivityService.shared.stopAppRestrictions(storeName: .interruption)
    
    // Also stop any active interruption blocking schedule
    DeviceActivityScheduleService.stopInterruptionSchedule()
    
    // Reset blocking state completely
    resetInterruptionBlockingState()
    
    // Send notification about disabling
    LocalNotificationManager.scheduleExtensionNotification(
      title: "🛑 App Interruptions Disabled",
      details: "Interruption blocking has been turned off"
    )
    
    AppLogger.notice("Stopped interruption monitoring and cleared all restrictions")
  }
  
  private func resetInterruptionBlockingState() {
    // Clear only interruption-specific data
    SharedData.userDefaults?.removeObject(forKey: SharedData.ScreenTime.isInterruptionBlock)
    SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.lastInterruptionBlockTime)
    
    // Clear interruption restrictions
    DeviceActivityService.shared.stopAppRestrictions(storeName: .interruption)
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
    SharedData.selectedInterruptionsActivity = selection
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
