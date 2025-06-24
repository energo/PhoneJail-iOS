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



struct AppMonitorView: View {
  @StateObject private var viewModel: AppMonitorViewModel
  
  let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]
  
  init(model: SelectAppsModel) {
    self._viewModel = StateObject(wrappedValue: AppMonitorViewModel(model: model))
  }
  
  var body: some View {
    VStack(spacing: 16) {
      screenTimeSelectButton
      
      if !viewModel.monitoredApps.isEmpty {
        monitoredAppsListView
      } else {
        quickSelectSocialMediaButton
      }
      
      startMonitorButton
      
      // selectedAppsView - можно раскомментировать если нужен
    }
    .padding()
    .task {
      await viewModel.onAppear()
    }
    .onChange(of: viewModel.model.activitySelection) { _ in 
      viewModel.onActivitySelectionChange()
    }
  }
  
  private var screenTimeSelectButton: some View {
    Button {
      viewModel.showSelectApps()
    } label: {
      HStack {
        Text("Select Apps")
          .padding(32)
          .background(Color.white)
      }
    }
    .familyActivityPicker(
      isPresented: $viewModel.pickerIsPresented,
      selection: $viewModel.model.activitySelection
    )
  }
  
  private var quickSelectSocialMediaButton: some View {
    Button {
      viewModel.showPickerWithInstructions()
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
    .alert(isPresented: $viewModel.showSocialMediaHint) {
      Alert(
        title: Text("Подсказка"),
        message: Text("Пожалуйста, выберите Facebook и Instagram из списка приложений"),
        dismissButton: .default(Text("OK"))
      )
    }
  }
  
  private var startMonitorButton: some View {
    Button {
      viewModel.startMonitoring()
    } label: {
      HStack {
        Text("Start Monitor")
          .padding(32)
          .background(Color.white)
      }
    }
  }
  
  private var monitoredAppsListView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Мониторинг приложений")
        .font(.headline)
      
      ForEach(0..<viewModel.monitoredApps.count, id: \.self) { index in
        monitoredAppRow(app: viewModel.monitoredApps[index])
      }
      
      Button("Добавить больше приложений") {
        viewModel.showSelectApps()
      }
      .padding(.top, 8)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(10)
  }
  
  private func monitoredAppRow(app: MonitoredApp) -> some View {
    HStack {
      Label(app.token)
        .lineLimit(1)
        .truncationMode(.tail)
      
      Spacer()
      
      Toggle("", isOn: Binding(
        get: { app.isMonitored },
        set: { _ in
          viewModel.toggleAppMonitoring(app: app)
        }
      ))
      .labelsHidden()
    }
    .padding(.vertical, 4)
  }
  
  // Оригинальный selectedAppsView из ContentView (закомментирован, но можно включить)
  /*
  private var selectedAppsView: some View {
    Group {
      if (viewModel.model.activitySelection.applicationTokens.count > 0) {
        ScrollView(.vertical) {
          LazyVGrid(columns: columns, spacing: 10) {
            appTokensView
            categoryTokensView
          }
          .padding()
        }
        .frame(width: UIScreen.main.bounds.width * 0.9, height: 200)
      }
    }
  }
  
  private var appTokensView: some View {
    ForEach(Array(viewModel.model.activitySelection.applicationTokens), id: \.self) { app in
      ZStack {
        RoundedRectangle(cornerRadius: 25, style: .continuous)
          .fill(.clear)
          .shadow(radius: 10)
          .shadow(radius: 10)
        VStack {
          Label(app)
            .shadow(radius: 2)
            .frame(width: 50, height: 50)
        }
        .padding()
        .multilineTextAlignment(.center)
      }
      .frame(width: 100, height: 100)
      .padding()
    }
  }
  
  private var categoryTokensView: some View {
    ForEach(Array(viewModel.model.activitySelection.categoryTokens), id: \.self) { app in
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
            .frame(width: 50, height: 50)
        }
        .padding()
        .multilineTextAlignment(.center)
      }
      .frame(width: 100, height: 100)
      .padding()
    }
  }
  */
}

// Структура для отображения приложения с переключателем
struct AppRowView: View {
  let app: MonitoredApp
  let onToggle: (MonitoredApp) -> Void
  
  var body: some View {
    HStack {
      // Иконка приложения
      appIcon
      
      VStack(alignment: .leading, spacing: 2) {
        Text(app.displayName)
          .font(.subheadline)
          .fontWeight(.medium)
        
        if let bundleId = app.bundleIdentifier {
          Text(bundleId)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }
      
      Spacer()
      
      Toggle("", isOn: Binding(
        get: { app.isMonitored },
        set: { newValue in
          var updatedApp = app
          updatedApp.isMonitored = newValue
          onToggle(updatedApp)
        }
      ))
      .toggleStyle(SwitchToggleStyle(tint: .blue))
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color.white)
    .cornerRadius(8)
    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
  }
  
  @ViewBuilder
  private var appIcon: some View {
    ZStack {
      // Fallback background
      RoundedRectangle(cornerRadius: 8)
        .fill(LinearGradient(
          colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ))
        .frame(width: 36, height: 36)
      
      // First letter of app name
      Text(String(app.displayName.prefix(1)).uppercased())
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundColor(.white)
    }
  }
}

// Структура для хранения приложения и его состояния мониторинга
struct MonitoredApp: Identifiable, Hashable {
    let id: String
    let token: ApplicationToken
    var isMonitored: Bool = true
    
    init(token: ApplicationToken, isMonitored: Bool = true) {
        self.token = token
        self.isMonitored = isMonitored
        // Используем описание токена для создания стабильного ID
        self.id = String(describing: token)
    }
    
    var displayName: String {
        return "App" // ApplicationToken не имеет displayName
    }
    
    var bundleIdentifier: String? {
        return nil // ApplicationToken не имеет bundleIdentifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MonitoredApp, rhs: MonitoredApp) -> Bool {
        return lhs.id == rhs.id
    }
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
