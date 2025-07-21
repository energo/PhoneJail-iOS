import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

class AppMonitorViewModel: ObservableObject {
  @Published var isAlertEnabled = false {
      didSet {
          if oldValue == false && isAlertEnabled == true {
              startMonitoring()
          } else if oldValue == true && isAlertEnabled == false {
              stopMonitoring()
          }
      }
  }
  
  @Published var isInterruptionsEnabled = false {
      didSet {
          if oldValue == false && isInterruptionsEnabled == true {
              startMonitoring()
          } else if oldValue == true && isInterruptionsEnabled == false {
              stopMonitoring()
          }
      }
  }

  @Published var pickerIsPresented = false
  @Published var showSocialMediaHint = false
  @Published var monitoredApps: [MonitoredApp] = []

  @Published var model: SelectAppsModel
  
  @Published var selectedFrequency: FrequencyOption
  @Published var selectedTime: TimeIntervalOption

  let center = DeviceActivityScheduleService.center

  init(model: SelectAppsModel) {
    self.model = model
    let saveInterraptedTimePeriods = SharedData.selectedInterraptedTimePeriods
    
    // Ищем FrequencyOption с таким же числом минут
    if let matched = TimeIntervalOption.timeOptions.first(where: { $0.minutes == saveInterraptedTimePeriods }) {
      self.selectedTime = matched
    } else {
      self.selectedTime = TimeIntervalOption.timeOptions[1] // default (e.g., Often)
    }
    
    let selectedScreenAlertTimePeriods = SharedData.selectedScreenAlertTimePeriods
    
    // Ищем FrequencyOption с таким же числом минут
    if let matched = FrequencyOption.frequencyOptions.first(where: { $0.minutes == selectedScreenAlertTimePeriods }) {
      self.selectedFrequency = matched
    } else {
      self.selectedFrequency = FrequencyOption.frequencyOptions[1] // default (e.g., Often)
    }
  }
  
  @MainActor
  func onAppear() async {
    // Восстанавливаем все сохраненные приложения
    let allSelectedApps = SharedData.allSelectedFamilyActivity?.applicationTokens ?? Set<ApplicationToken>()
    let disabledApps = SharedData.disabledFamilyActivity?.applicationTokens ?? Set<ApplicationToken>()
    
    if !allSelectedApps.isEmpty {
      print("Найдено ранее выбранных приложений: \(allSelectedApps.count)")
      
      // Создаем список из всех сохраненных приложений
      monitoredApps = allSelectedApps.map { token in
        // Приложение включено, если оно не в списке выключенных
        let isEnabled = !disabledApps.contains(token)
        return MonitoredApp(token: token, isMonitored: isEnabled)
      }
      
      // Обновляем модель только включенными приложениями
      if let enabledSelection = SharedData.selectedFamilyActivity {
        model.activitySelection = enabledSelection
      } else {
        var enabledSelection = FamilyActivitySelection()
        enabledSelection.applicationTokens = allSelectedApps.subtracting(disabledApps)
        model.activitySelection = enabledSelection
      }
      
      print("Создано приложений: \(monitoredApps.count)")
      print("Включено: \(monitoredApps.filter { $0.isMonitored }.count)")
      print("Выключено: \(monitoredApps.filter { !$0.isMonitored }.count)")
    } else if !model.activitySelection.applicationTokens.isEmpty {
      // Если нет сохраненных, но есть в текущей модели
      updateMonitoredAppsList()
    } else {
      // Если нет приложений, показываем пикер
      print("Нет приложений")
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
      // Обновляем выбор в SharedData при изменении состояния
      updateMonitoringState()
    }
  }
  
  func startMonitoring() {
    let timeLimitMinutes = 2
    
    print("startMonitoring timeLimitMinutes: \(timeLimitMinutes)")
    
    // Обновляем состояние всех приложений
    updateMonitoringState()
    
    // Получаем только включенные токены для мониторинга
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
    let event = DeviceActivityEvent(
      applications: enabledTokens,
      categories: model.activitySelection.categoryTokens,
      webDomains: model.activitySelection.webDomainTokens,
      threshold: DateComponents(minute: timeLimitMinutes))
    
    let activity = DeviceActivityName.appMonitoring
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
    let activity = DeviceActivityName.appMonitoring
    let center = DeviceActivityCenter()
    center.stopMonitoring([activity])
    
    SharedData.selectedFamilyActivity = nil
  }
  
  func schedule24h() -> DeviceActivitySchedule {
    return DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
      repeats: true
    )
  }
  
  private func updateMonitoredAppsList() {
    // Получаем токены всех сохраненных приложений
    let allSelectedApps = SharedData.allSelectedFamilyActivity?.applicationTokens ?? Set<ApplicationToken>()
    let disabledApps = SharedData.disabledFamilyActivity?.applicationTokens ?? Set<ApplicationToken>()
    
    // Получаем новые приложения из выбора
    let newAppsFromSelection = model.activitySelection.applicationTokens
    
    // Объединяем все приложения
    var allApps = allSelectedApps
    allApps.formUnion(newAppsFromSelection)
    
    // Объединяем с текущими приложениями
    let currentTokens = Set(monitoredApps.map { $0.token })
    allApps.formUnion(currentTokens)
    
    // Сохраняем все приложения
    var allSelection = FamilyActivitySelection()
    allSelection.applicationTokens = allApps
    SharedData.allSelectedFamilyActivity = allSelection
    
    // Создаем новый список приложений для отображения
    monitoredApps = allApps.map { token in
      // Приложение включено, если оно не в списке выключенных
      
      let isEnabled = !disabledApps.contains(token)
      return MonitoredApp(token: token, isMonitored: isEnabled)
    }
    
    print("Обновлено приложений: \(monitoredApps.count)")
    print("Включено: \(monitoredApps.filter { $0.isMonitored }.count)")
    print("Выключено: \(monitoredApps.filter { !$0.isMonitored }.count)")
  }
  
  private func updateMonitoringState() {
    // Получаем список всех приложений
    let allApps: Set<ApplicationToken> = Set(monitoredApps.map { $0.token })
    
    // Получаем список выключенных приложений
    let disabledApps: Set<ApplicationToken> = Set(monitoredApps.filter { !$0.isMonitored }.map { $0.token })
    
    // Получаем список включенных приложений
    let enabledApps: Set<ApplicationToken> = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
    // Сохраняем все приложения
    var allSelection = FamilyActivitySelection()
    allSelection.applicationTokens = allApps
    SharedData.allSelectedFamilyActivity = allSelection
    
    // Сохраняем выключенные приложения
    var disabledSelection = FamilyActivitySelection()
    disabledSelection.applicationTokens = disabledApps
    SharedData.disabledFamilyActivity = disabledSelection
    
    // Сохраняем включенные приложения для мониторинга
    var enabledSelection = FamilyActivitySelection()
    enabledSelection.applicationTokens = enabledApps
    SharedData.selectedFamilyActivity = enabledSelection
  }
}
