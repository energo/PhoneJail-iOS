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

struct ContentView: View {
  @State private var pickerIsPresented = false
  @State private var showSocialMediaHint = false
  @State private var monitoredApps: [MonitoredApp] = []
  @State private var isAuthorized = false
  @ObservedObject var model: ScreenTimeSelectAppsModel
  
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
        
        // Загружаем сохраненные приложения независимо от статуса авторизации
        let enabledApps = loadEnabledApps()
        let disabledApps = loadDisabledApps()
        
        // Восстанавливаем сохраненный выбор приложений
        if let savedSelection = SharedData.selectedFamilyActivity {
          // Обновляем модель сохраненным выбором
          model.activitySelection = savedSelection
        }
        
        // Собираем все уникальные токены из всех источников
        var allTokens = Set<ApplicationToken>()
        
        // Добавляем токены из текущей модели
        allTokens.formUnion(model.activitySelection.applicationTokens)
        
        // Добавляем сохраненные включенные и выключенные токены
        if !enabledApps.isEmpty || !disabledApps.isEmpty {
          allTokens.formUnion(enabledApps)
          allTokens.formUnion(disabledApps)
          
          print("Загружено включенных приложений: \(enabledApps.count)")
          print("Загружено выключенных приложений: \(disabledApps.count)")
        }
        
        // Если есть хоть какие-то токены, создаем список приложений
        if !allTokens.isEmpty {
          // Создаем список всех приложений
          monitoredApps = allTokens.map { token in
            // Приложение включено, если оно в списке enabledApps или не в списке disabledApps
            let isEnabled = enabledApps.contains(token) || (!disabledApps.contains(token) && !enabledApps.isEmpty)
            return MonitoredApp(token: token, isMonitored: isEnabled)
          }
          
          // Обновляем модель и SharedData со всеми токенами
          updateSelectionWithAllTokens(allTokens: allTokens)
          
          print("Создано приложений: \(monitoredApps.count)")
          for app in monitoredApps {
            print("Приложение: \(app.token), Состояние: \(app.isMonitored)")
          }
        } else {
          // Если нет ни сохраненных, ни текущих - показываем подсказку
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

    // Собираем только активные токены
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
    // Если нет активных токенов, используем все выбранные в модели
    let activeTokens = enabledTokens.isEmpty ? model.activitySelection.applicationTokens : enabledTokens
    
    // Создаем новый FamilyActivitySelection
    var selection = FamilyActivitySelection()
    // Устанавливаем наши токены приложений
    selection.applicationTokens = activeTokens
    
    // Сохраняем выбор
    SharedData.selectedFamilyActivity = selection
    
    let event = DeviceActivityEvent(
      applications: activeTokens,
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
    // Сохраняем текущее состояние приложений
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    let disabledTokens = Set(monitoredApps.filter { !$0.isMonitored }.map { $0.token })
    
    // Получаем все токены из модели
    var allTokens = Set(model.activitySelection.applicationTokens)
    
    // Добавляем токены, которые были в нашем списке
    let previousTokens = monitoredApps.map { $0.token }
    allTokens.formUnion(previousTokens)
    
    // Создаем новый список всех приложений
    monitoredApps = allTokens.map { token in
      // Сохраняем прежнее состояние или устанавливаем включенным по умолчанию
      let isEnabled = enabledTokens.contains(token) || (!disabledTokens.contains(token) && !enabledTokens.isEmpty)
      return MonitoredApp(token: token, isMonitored: isEnabled)
    }
    
    // Обновляем selection с учетом всех токенов
    updateSelectionWithAllTokens(allTokens: allTokens)
    
    // Сохраняем состояние приложений
    saveAppStates()
  }
  
  func updateMonitoringState() {
    // Обновляем списки включенных и выключенных приложений
//    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
//    let disabledTokens = Set(monitoredApps.filter { !$0.isMonitored }.map { $0.token })
    
    // Все токены (и включенные, и выключенные)
    let allTokens = Set(monitoredApps.map { $0.token })
    
    // Обновляем модель и SharedData
    updateSelectionWithAllTokens(allTokens: allTokens)
    
    // Сохраняем состояние приложений
    saveAppStates()
  }
  
  // Обновляет selection в модели и сохраняет его
  func updateSelectionWithAllTokens(allTokens: Set<ApplicationToken>) {
    var selection = FamilyActivitySelection()
    selection.applicationTokens = allTokens
    model.activitySelection = selection
    
    // Сохраняем выбор в SharedData
    SharedData.selectedFamilyActivity = selection
  }
  
  // Сохраняет списки включенных и выключенных приложений
  func saveAppStates() {
    let enabledTokens = monitoredApps.filter { $0.isMonitored }.map { $0.token.hashValue }
    let disabledTokens = monitoredApps.filter { !$0.isMonitored }.map { $0.token.hashValue }
    
    print("Сохраняем включенных приложений: \(enabledTokens.count)")
    print("Сохраняем выключенных приложений: \(disabledTokens.count)")
    
    SharedData.defaultsGroup?.set(enabledTokens, forKey: enabledAppsKey)
    SharedData.defaultsGroup?.set(disabledTokens, forKey: disabledAppsKey)
  }
  
  // Загружает список включенных приложений
  func loadEnabledApps() -> [ApplicationToken] {
    guard let hashes = SharedData.defaultsGroup?.array(forKey: enabledAppsKey) as? [Int] else {
      return []
    }
    
    // Получаем токены из актуального набора приложений
    var tokens = [ApplicationToken]()
    
    // Добавляем токены из модели
    for token in model.activitySelection.applicationTokens {
      if hashes.contains(token.hashValue) {
        tokens.append(token)
      }
    }
    
    // Добавляем токены из текущего списка приложений
    for app in monitoredApps {
      if hashes.contains(app.token.hashValue) && !tokens.contains(app.token) {
        tokens.append(app.token)
      }
    }
    
    return tokens
  }
  
  // Загружает список выключенных приложений
  func loadDisabledApps() -> [ApplicationToken] {
    guard let hashes = SharedData.defaultsGroup?.array(forKey: disabledAppsKey) as? [Int] else {
      return []
    }
    
    // Получаем токены из актуального набора приложений
    var tokens = [ApplicationToken]()
    
    // Добавляем токены из модели
    for token in model.activitySelection.applicationTokens {
      if hashes.contains(token.hashValue) {
        tokens.append(token)
      }
    }
    
    // Добавляем токены из текущего списка приложений
    for app in monitoredApps {
      if hashes.contains(app.token.hashValue) && !tokens.contains(app.token) {
        tokens.append(app.token)
      }
    }
    
    return tokens
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
