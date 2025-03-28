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

let userDefaultsKey = "FamilyActivitySelection"

struct ContentView: View {
  @State private var pickerIsPresented = false
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
//      quickSelectSocialMediaButton
      startMonitorButton
      
      selectedAppsView
    }
    .padding()
    .task {
      Task {
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          // Проверяем, есть ли уже выбранные приложения
          if model.activitySelection.applicationTokens.isEmpty && model.activitySelection.categoryTokens.isEmpty {
            // Если нет, инициализируем с соцсетями
//            initWithDefaultSocialMedia()
          }
        } catch {
          print(error.localizedDescription)
        }
      }
      
//      configureCallbacks()
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
  
//  private var quickSelectSocialMediaButton: some View {
//    VStack {
//      Text("Быстрый выбор категорий")
//        .font(.headline)
//      
//      HStack {
//        Button {
//          selectCategory(.)
//        } label: {
//          VStack {
//            Image(systemName: "person.2.fill")
//              .font(.largeTitle)
//            Text("Соцсети")
//              .font(.caption)
//          }
//          .frame(width: 80, height: 80)
//          .background(Color.blue.opacity(0.2))
//          .cornerRadius(10)
//        }
//        
//        Button {
//          selectCategory(.entertainment)
//        } label: {
//          VStack {
//            Image(systemName: "tv.fill")
//              .font(.largeTitle)
//            Text("Развлечения")
//              .font(.caption)
//          }
//          .frame(width: 80, height: 80)
//          .background(Color.purple.opacity(0.2))
//          .cornerRadius(10)
//        }
//        
//        Button {
//          selectCategory(.games)
//        } label: {
//          VStack {
//            Image(systemName: "gamecontroller.fill")
//              .font(.largeTitle)
//            Text("Игры")
//              .font(.caption)
//          }
//          .frame(width: 80, height: 80)
//          .background(Color.green.opacity(0.2))
//          .cornerRadius(10)
//        }
//      }
//    }
//    .padding()
//    .background(Color.white.opacity(0.5))
//    .cornerRadius(15)
//  }
  
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

    guard let selection: FamilyActivitySelection = SharedData.selectedFamilyActivity else {
      print("Nothing selected for tracking")
      return
    }

    let event = DeviceActivityEvent(
      applications: selection.applicationTokens,
      categories: selection.categoryTokens,
      webDomains: selection.webDomainTokens,
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
