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
          
          // Восстанавливаем сохраненный выбор приложений
          if let savedSelection = SharedData.selectedFamilyActivity {
            // Обновляем модель сохраненным выбором
            model.activitySelection = savedSelection
            
            // Обновляем наш список приложений, включая их состояние
            updateMonitoredAppsList()
            
            // Загружаем сохраненное состояние (включено/выключено)
            loadMonitoredAppsState()
          } else if !model.activitySelection.applicationTokens.isEmpty {
            // Если нет сохраненных, но есть в текущей модели
            updateMonitoredAppsList()
          } else {
            // Если нет ни сохраненных, ни текущих - показываем подсказку
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
    
    // Получаем все токены из модели
    var allTokens = Set(model.activitySelection.applicationTokens)
    
    // Добавляем токены, которые были в нашем списке, но отсутствуют в новом выборе
    let previousTokens = monitoredApps.map { $0.token }
    allTokens.formUnion(previousTokens)
    
    // Создаем новый список из всех собранных приложений
    monitoredApps = Array(allTokens).map { token in
      // Сохраняем состояние, если приложение уже было в списке
      let isEnabled = existingAppsState[token.hashValue] ?? true
      return MonitoredApp(token: token, isMonitored: isEnabled)
    }
    
    // Обновляем selection с учетом всех токенов
    updateSelectionWithAllTokens(allTokens: allTokens)
    
    // Сохраняем состояние (включено/выключено)
    saveMonitoredAppsState()
  }
  
  func updateMonitoringState() {
    // Собираем только активные токены для мониторинга
    let enabledTokens = Set(monitoredApps.filter { $0.isMonitored }.map { $0.token })
    
    // Получаем все токены (и активные, и неактивные)
    let allTokens = Set(monitoredApps.map { $0.token })
    
    // Создаем селекцию из всех токенов
    var selection = FamilyActivitySelection()
    
    // Устанавливаем все токены (и активные, и неактивные)
    selection.applicationTokens = allTokens
    
    // Обновляем сохраненное состояние
    model.activitySelection = selection
    
    // Сохраняем в SharedData для мониторинга ВСЕ токены
    SharedData.selectedFamilyActivity = selection
    
    // Сохраняем состояние переключателей (включено/выключено)
    saveMonitoredAppsState()
  }
  
  // Обновляет selection в модели и сохраняет его
  func updateSelectionWithAllTokens(allTokens: Set<ApplicationToken>) {
    var selection = FamilyActivitySelection()
    selection.applicationTokens = allTokens
    model.activitySelection = selection
    
    // Сохраняем выбор в SharedData
    SharedData.selectedFamilyActivity = selection
  }
  
  // Функция для сохранения состояния приложений в UserDefaults
  func saveMonitoredAppsState() {
    // Создаем словарь [String: Bool], где ключ - хеш токена в виде строки, значение - состояние мониторинга
    var appsState: [String: Bool] = [:]
    
    // Заполняем словарь, преобразуя хеш-значения в строки
    for app in monitoredApps {
      appsState[String(app.token.hashValue)] = app.isMonitored
    }
    
    // Сохраняем в UserDefaults группы приложений
    SharedData.defaultsGroup?.set(appsState, forKey: monitoredAppsEnabledStateKey)
  }
  
  // Функция для загрузки состояния приложений из UserDefaults
  func loadMonitoredAppsState() {
    guard let savedState = SharedData.defaultsGroup?.dictionary(forKey: monitoredAppsEnabledStateKey) as? [String: Bool] else {
      return
    }
    
    // Обновляем состояние приложений из сохраненных данных
    for i in 0..<monitoredApps.count {
      let tokenHashStr = String(monitoredApps[i].token.hashValue)
      if let isEnabled = savedState[tokenHashStr] {
        monitoredApps[i].isMonitored = isEnabled
      }
    }
    
    // Проверка: выводим состояние каждого приложения
    for app in monitoredApps {
      print("Приложение: \(app.token), Включено: \(app.isMonitored)")
    }
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
