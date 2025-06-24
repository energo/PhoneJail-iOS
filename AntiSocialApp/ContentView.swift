//
//  ContentView.swift
//  ScreenTimeTestApp
//
//  Created by D C on 11.02.2025.
//

import SwiftUI

import Foundation

import ScreenTime
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import DeviceActivity

// Константы для ключей UserDefaults
let enabledAppsKey = "EnabledApps"
let disabledAppsKey = "DisabledApps"
let isAuthorizedKey = "IsAuthorized"

extension SharedData.Keys {
  static let disabledApps = "DisabledApps"
  static let allSelectedApps = "AllSelectedApps"
}

// Расширяем SharedData дополнительным свойством для хранения выключенных приложений
extension SharedData {
  static var disabledFamilyActivity: FamilyActivitySelection? {
    get {
      guard let data = defaultsGroup?.data(forKey: Keys.disabledApps) else { return nil }
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } set {
      defaultsGroup?.set(try? JSONEncoder().encode(newValue), forKey: Keys.disabledApps)
    }
  }
  
  static var allSelectedFamilyActivity: FamilyActivitySelection? {
    get {
      guard let data = defaultsGroup?.data(forKey: Keys.allSelectedApps) else { return nil }
      return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } set {
      defaultsGroup?.set(try? JSONEncoder().encode(newValue), forKey: Keys.allSelectedApps)
    }
  }
}

struct ContentView: View {
  @State private var pickerIsPresented = false
  @State private var showSocialMediaHint = false
  @State private var monitoredApps: [MonitoredApp] = []
  @State private var isAuthorized = false
  @ObservedObject var model: SelectAppsModel
  
  let columns = [
          GridItem(.flexible()),
          GridItem(.flexible()),
          GridItem(.flexible()),
          GridItem(.flexible()),
      ]

  //MARK: - Views
  var body: some View {
    VStack(spacing: 16) {
      screenTimeSelectButton
      
      if !monitoredApps.isEmpty {
        monitoredAppsListView
      } else {
        quickSelectSocialMediaButton
      }
      
      startMonitorButton
      
//      selectedAppsView
    }
    .padding()
    .task {
      Task {
        // Загружаем статус авторизации
        isAuthorized = SharedData.defaultsGroup?.bool(forKey: isAuthorizedKey) ?? false
        
        // Проверяем, была ли уже дана авторизация
        if !isAuthorized {
          do {
            // Запрашиваем авторизацию, если её нет
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            
            // Сохраняем статус авторизации
            isAuthorized = true
            SharedData.defaultsGroup?.set(true, forKey: isAuthorizedKey)
          } catch {
            print("Ошибка авторизации: \(error.localizedDescription)")
          }
        }
        
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
          print("Нет приложений, показываем подсказку")
          showPickerWithInstructions()
        }
      }
    }
    .onChange(of: model.activitySelection) { _ in 
      print("Изменился выбор приложений в модели")
      updateMonitoredAppsList()
    }
  }
  
  private var screenTimeSelectButton: some View {
    Button {
      pickerIsPresented = true
    } label: {
      HStack {
        Text("Select Apps")
          .padding(32)
          .background(Color.white)
      }
    }
    .familyActivityPicker(
      isPresented: $pickerIsPresented,
      selection: $model.activitySelection
    )
  }
  
  private var quickSelectSocialMediaButton: some View {
    Button {
      showPickerWithInstructions()
    } label: {
      HStack {
        Image(systemName: "person.2.fill")
          .font(.title2)
        Text("Выбрать Facebook и Instagram")
          .padding()
          .background(Color.blue.opacity(0.2))
          .cornerRadius(10)
      }
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(Color.blue, lineWidth: 1)
      )
    }
    .alert(isPresented: $showSocialMediaHint) {
      Alert(
        title: Text("Подсказка"),
        message: Text("Пожалуйста, выберите Facebook и Instagram из списка приложений"),
        dismissButton: .default(Text("OK"))
      )
    }
  }
  
  private var startMonitorButton: some View {
    Button {
      startMonitoring()
    } label: {
      HStack {
        Text("Start Monitor")
          .padding(32)
          .background(Color.white)
      }
    }
    .familyActivityPicker(
      isPresented: $pickerIsPresented,
      selection: $model.activitySelection
    )
  }
  
  private var selectedAppsView: some View {
    Group {
      if (model.activitySelection.applicationTokens.count > 0) {
        ScrollView(.vertical) {
          LazyVGrid(columns: columns, spacing: 10) {
            appTokensView
            categoryTokensView
          }
          .padding()
        }
        .frame(width: UIScreen.main.bounds.width * 0.9, height:200)
      }
    }
  }
  
  private var appTokensView: some View {
    ForEach(Array(model.activitySelection.applicationTokens), id: \.self) { app in
      ZStack {
        RoundedRectangle(cornerRadius: 25, style: .continuous)
          .fill(.clear)
          .shadow(radius: 10)
          .shadow(radius: 10)
        VStack {
//                Label(app)
//                  .labelStyle(.iconOnly)
//                  .shadow(radius: 2)
//                  .scaleEffect(3)
//                  .frame(width:50, height:50)
          
          Label(app)
            .shadow(radius: 2)
            .frame(width:50, height:50)
          
          
        }
        .padding()
        .multilineTextAlignment(.center)
      }
      .frame(width: 100, height:100)
      .padding()
    }
  }
  
  private var categoryTokensView: some View {
    ForEach(Array(model.activitySelection.categoryTokens), id: \.self) { app in
      ZStack {
        RoundedRectangle(cornerRadius: 25, style: .continuous)
          .fill(.clear)
          .shadow(radius: 10)
          .shadow(radius: 10)
        VStack {
          Label(app)
            .labelStyle(.iconOnly)
            .shadow(radius: 2)
            .scaleEffect(3)
            .frame(width:50, height:50)
          
        }
        .padding()
        .multilineTextAlignment(.center)
      }
      .frame(width: 100, height:100)
      .padding()
    }
  }
  
  private var monitoredAppsListView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Мониторинг приложений")
        .font(.headline)
      
      ForEach(0..<monitoredApps.count, id: \.self) { index in
        monitoredAppRow(app: $monitoredApps[index])
      }
      
      Button("Добавить больше приложений") {
        pickerIsPresented = true
      }
      .padding(.top, 8)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(10)
  }
  
  private func monitoredAppRow(app: Binding<MonitoredApp>) -> some View {
    HStack {
      Label(app.wrappedValue.token)
        .lineLimit(1)
        .truncationMode(.tail)
      
      Spacer()
      
      Toggle("", isOn: Binding(
        get: { app.wrappedValue.isMonitored },
        set: { 
          app.wrappedValue.isMonitored = $0
          // Обновляем выбор в SharedData при изменении состояния
          updateMonitoringState()
        }
      ))
      .labelsHidden()
    }
    .padding(.vertical, 4)
  }
  
  //MARK: - Functions
//  fileprivate func configureCallbacks() {
//      DarwinNotificationManager.shared.startObserving(name: "com.yourapp.BroadcastStarted") {
//          print("*******Broadcast has started*******")
//          // Handle the event when broadcast starts
//      }
//      
//      DarwinNotificationManager.shared.startObserving(name: "com.yourapp.BroadcastStopped") {
//          print("*******Broadcast has stopped*******")
//          // Handle the event when broadcast starts
//      }
//    
//    DarwinNotificationManager.shared.startObserving(name: "com.yourapp.ReachThresholdWarning") {
//        print("*******Broadcast has stopped*******")
//        // Handle the event when broadcast starts
//    }
//
//  }
  
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
    
    let center = DeviceActivityCenter()
    let activity = DeviceActivityName("MyApp.ScreenTime")
    let eventName = DeviceActivityEvent.Name("MyApp.SomeEventName")
    let schedule = getScheduleDeviceActivity()
    
    DispatchQueue.main.async {
      do {
        print("startMonitoring \(activity)")

        try center.startMonitoring(activity,
                                   during: schedule,
                                   events: [eventName: event])
      } catch let error {
        print("center.startMonitoring error \(error.localizedDescription)")
      }
    }
  }
  
  
  func getScheduleDeviceActivity() -> DeviceActivitySchedule {
    return DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
      repeats: true
    )
  }
  
//  func selectCategory(_ category: ActivityCategory) {
//    print("Выбрана категория: \(category)")
//    
//    // Создаем выбор с выбранной категорией
//    let selection = FamilyActivitySelection(categoryTokens: [category.token])
//    
//    // Обновляем модель выбора
//    model.activitySelection = selection
//    
//    // Сохраняем выбор в SharedData
//    SharedData.selectedFamilyActivity = selection
//  }
  
//  func quickSelectSocialMedia() {
//    selectCategory(.social)
//  }
//  
//  func initWithDefaultSocialMedia() {
//    print("Инициализация с категорией социальных приложений")
//    selectCategory(.social)
//  }
  
  func showPickerWithInstructions() {
    // Показываем подсказку
    showSocialMediaHint = true
    
    // Показываем picker для выбора приложений
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      pickerIsPresented = true
    }
  }
  
  func updateMonitoredAppsList() {
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
  
  func updateMonitoringState() {
    // Получаем список всех приложений
    let allApps = Set(monitoredApps.map { $0.token })
    
    // Получаем список выключенных приложений
    let disabledApps = Set(monitoredApps.filter { !$0.isMonitored }.map { $0.token })
    
    // Получаем список включенных приложений
    let enabledApps = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
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
  
  // Сохраняет все выбранные приложения
  func saveAllSelectedApps(allTokens: Set<ApplicationToken>) {
    // Сохраняем хеши всех токенов
    let allHashes = allTokens.map { $0.hashValue }
    SharedData.defaultsGroup?.set(allHashes, forKey: SharedData.Keys.allSelectedApps)
    
    print("Сохранено всех приложений: \(allHashes.count)")
  }
  
  // Загружает все ранее выбранные приложения
  func loadAllSelectedApps() -> Set<ApplicationToken> {
    // Загружаем хеши всех токенов
    guard let allHashes = SharedData.defaultsGroup?.array(forKey: SharedData.Keys.allSelectedApps) as? [Int] else {
      return []
    }
    
    print("Загружено хешей всех приложений: \(allHashes.count)")
    
    // Собираем все доступные токены
    var allTokensSet = Set<ApplicationToken>()
    
    // Добавляем токены из текущей модели
    allTokensSet.formUnion(model.activitySelection.applicationTokens)
    
    // Добавляем токены из текущего списка
    let currentTokens = monitoredApps.map { $0.token }
    allTokensSet.formUnion(currentTokens)
    
    // Фильтруем токены по хешам
    var matchedTokens = Set<ApplicationToken>()
    for token in allTokensSet {
      if allHashes.contains(token.hashValue) {
        matchedTokens.insert(token)
      }
    }
    
    print("Найдено сохраненных приложений: \(matchedTokens.count)")
    return matchedTokens
  }
  
  // Сохраняет выключенные приложения
  func saveDisabledApps(disabledTokens: Set<ApplicationToken>) {
    // Сохраняем хеши выключенных токенов
    let disabledHashes = disabledTokens.map { $0.hashValue }
    SharedData.defaultsGroup?.set(disabledHashes, forKey: SharedData.Keys.disabledApps)
    
    print("Сохранено выключенных приложений: \(disabledHashes.count)")
  }
  
  // Загружает выключенные приложения
  func loadDisabledApps() -> Set<ApplicationToken> {
    // Загружаем хеши выключенных токенов
    guard let disabledHashes = SharedData.defaultsGroup?.array(forKey: SharedData.Keys.disabledApps) as? [Int] else {
      return []
    }
    
    print("Загружено хешей выключенных приложений: \(disabledHashes.count)")
    
    // Собираем все доступные токены
    var allTokensSet = Set<ApplicationToken>()
    
    // Добавляем токены из текущей модели
    allTokensSet.formUnion(model.activitySelection.applicationTokens)
    
    // Добавляем токены из текущего списка
    let currentTokens = monitoredApps.map { $0.token }
    allTokensSet.formUnion(currentTokens)
    
    // Фильтруем токены по хешам
    var disabledTokens = Set<ApplicationToken>()
    for token in allTokensSet {
      if disabledHashes.contains(token.hashValue) {
        disabledTokens.insert(token)
      }
    }
    
    print("Найдено выключенных приложений: \(disabledTokens.count)")
    return disabledTokens
  }
}

// Структура для хранения приложения и его состояния мониторинга
struct MonitoredApp {
  let token: ApplicationToken
  var isMonitored: Bool = true
}




//  let userDefaultsKey = "FamilyActivitySelection"
//
//    func setSelection(selection: FamilyActivitySelection) {
//      let defaults = UserDefaults.standard
//      defaults.set(try? JSONEncoder().encode(selection), forKey: userDefaultsKey)
//    }
//
//  func getSelection() -> FamilyActivitySelection? {
//    print("getSelection")
//
//    let defaults = UserDefaults.standard
//
//    guard let data = defaults.data(forKey: userDefaultsKey) else { return nil }
//
//    return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
//  }
