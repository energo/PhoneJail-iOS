import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

class AppMonitorViewModel: ObservableObject {
  @AppStorage("isInterruptionsEnabled") var isInterruptionsEnabled: Bool = false {
    didSet {
        if oldValue == false && isInterruptionsEnabled == true {
            startMonitoring()
        } else if oldValue == true && isInterruptionsEnabled == false {
            stopMonitoring()
        }
    }
  }

  @AppStorage("isAlertEnabled") var isAlertEnabled: Bool = false {
      didSet {
          if oldValue == false && isAlertEnabled == true {
              startMonitoring()
          } else if oldValue == true && isAlertEnabled == false {
              stopMonitoring()
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
    let event = DeviceActivityEvent(
      applications: enabledTokens,
      categories: model.activitySelection.categoryTokens,
      webDomains: model.activitySelection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes))
    let activity = isInterruptionsEnabled ? DeviceActivityName.appMonitoringInterruption : DeviceActivityName.appMonitoringAlert
    let eventName = isInterruptionsEnabled ? DeviceActivityEvent.Name.interruption : DeviceActivityEvent.Name.screenAlert
    let schedule = schedule24h()
    
    DispatchQueue.main.async {
      do {
        print("startMonitoring \(activity)")
        try self.center.startMonitoring(activity,
                                   during: schedule,
                                   events: [eventName: event])
      } catch let error {
        print("center.startMonitoring error \(error.localizedDescription)")
      }
    }
  }
  
  func stopMonitoring() {
    let activity = isInterruptionsEnabled ? DeviceActivityName.appMonitoringInterruption : DeviceActivityName.appMonitoringAlert
    let center = DeviceActivityCenter()
    center.stopMonitoring([activity])
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
