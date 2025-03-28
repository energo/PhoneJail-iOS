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
let userDefaultsKey = "FamilyActivitySelection"
let monitoredAppsEnabledStateKey = "MonitoredAppsEnabledState"
let monitoredAppsTokensKey = "MonitoredAppsTokens"

struct ContentView: View {
  @State private var pickerIsPresented = false
  @State private var showSocialMediaHint = false
  @State private var monitoredApps: [MonitoredApp] = []
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
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          
          // Проверяем, есть ли уже сохраненные приложения
          if let savedTokens = loadSavedTokens(), !savedTokens.isEmpty {
            // Создаем список из сохраненных токенов
            monitoredApps = Array(savedTokens).map { token in
              return MonitoredApp(token: token, isMonitored: false)
            }
            
            // Теперь загружаем состояние для этих приложений
            loadMonitoredAppsState()
          } else if !model.activitySelection.applicationTokens.isEmpty {
            // Если есть выбранные приложения, загружаем их
            updateMonitoredAppsList()
          } else {
            // Если нет ни сохраненных, ни выбранных - показываем подсказку
            showPickerWithInstructions()
          }
        } catch {
          print(error.localizedDescription)
        }
      }
    }
    .onChange(of: model.activitySelection) { _ in 
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
    // Сначала сохраняем состояние существующих приложений
    let existingAppsState = Dictionary(uniqueKeysWithValues: 
      monitoredApps.map { ($0.token.hashValue, $0.isMonitored) })
    
    // Получаем все токены из селекции
    var allTokens = Set(model.activitySelection.applicationTokens)
    
    // Восстанавливаем сохраненные токены из UserDefaults
    if let savedTokens = loadSavedTokens() {
      // Добавляем ранее сохраненные токены
      allTokens.formUnion(savedTokens)
    } else {
      // Если сохраненных токенов нет, добавляем те, которые были в списке
      let previousTokens = monitoredApps.map { $0.token }
      allTokens.formUnion(previousTokens)
    }
    
    // Создаем новый список из всех собранных приложений
    monitoredApps = Array(allTokens).map { token in
      // Сохраняем состояние, если приложение уже было в списке
      let isEnabled = existingAppsState[token.hashValue] ?? true
      return MonitoredApp(token: token, isMonitored: isEnabled)
    }
    
    // Сохраняем все токены и их состояния
    saveMonitoredAppsState()
    saveAllTokens(tokens: allTokens)
  }
  
  func updateMonitoringState() {
    // Собираем только активные токены для мониторинга
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
    // Создаем селекцию из всех токенов
    var selection = FamilyActivitySelection()
    
    // Устанавливаем все токены - для обоих типов приложений сохраняем в модели
    selection.applicationTokens = Set(monitoredApps.map { $0.token })
    
    // Обновляем сохраненное состояние
    model.activitySelection = selection
    
    // А в SharedData для мониторинга сохраняем только включенные токены
    var monitoringSelection = FamilyActivitySelection()
    monitoringSelection.applicationTokens = enabledTokens
    SharedData.selectedFamilyActivity = monitoringSelection
    
    // Сохраняем состояние переключателей в UserDefaults
    saveMonitoredAppsState()
  }
  
  // Функция для сохранения состояния приложений в UserDefaults
  func saveMonitoredAppsState() {
    // Создаем словарь [String: Bool], где ключ - хеш токена в виде строки, значение - состояние мониторинга
    var appsState: [String: Bool] = [:]
    
    // Заполняем словарь, преобразуя хеш-значения в строки
    for app in monitoredApps {
      appsState[String(app.token.hashValue)] = app.isMonitored
    }
    
    // Сохраняем в UserDefaults
    UserDefaults.standard.set(appsState, forKey: monitoredAppsEnabledStateKey)
  }
  
  // Функция для загрузки состояния приложений из UserDefaults
  func loadMonitoredAppsState() {
    guard let savedState = UserDefaults.standard.dictionary(forKey: monitoredAppsEnabledStateKey) as? [String: Bool] else {
      return
    }
    
    // Обновляем состояние приложений из сохраненных данных
    for i in 0..<monitoredApps.count {
      let tokenHashStr = String(monitoredApps[i].token.hashValue)
      if let isEnabled = savedState[tokenHashStr] {
        monitoredApps[i].isMonitored = isEnabled
      }
    }
  }
  
  // Функция для сохранения всех токенов (включая отключенные)
  func saveAllTokens(tokens: Set<ApplicationToken>) {
    // Преобразуем токены в их хеш-значения и сохраняем
    let tokenHashes = tokens.map { $0.hashValue }
    UserDefaults.standard.set(tokenHashes, forKey: monitoredAppsTokensKey)
  }
  
  // Функция для загрузки сохраненных токенов
  func loadSavedTokens() -> Set<ApplicationToken>? {
    // Загружаем сохраненные хеш-значения токенов
    guard let tokenHashes = UserDefaults.standard.array(forKey: monitoredAppsTokensKey) as? [Int] else {
      return nil
    }
    
    // Ищем токены с такими же хеш-значениями в текущем списке приложений
    var savedTokens = Set<ApplicationToken>()
    
    // Добавляем токены из актуального выбора
    let currentTokens = Array(model.activitySelection.applicationTokens)
    
    // Фильтруем токены по сохраненным хешам
    for token in currentTokens {
      if tokenHashes.contains(token.hashValue) {
        savedTokens.insert(token)
      }
    }
    
    // Добавляем токены из предыдущего состояния
    for app in monitoredApps {
      if tokenHashes.contains(app.token.hashValue) {
        savedTokens.insert(app.token)
      }
    }
    
    return savedTokens
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
