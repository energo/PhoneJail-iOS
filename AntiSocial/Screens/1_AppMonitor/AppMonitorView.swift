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


struct AppMonitorView: View {
  @StateObject private var viewModel: AppMonitorViewModel
  @StateObject private var restrictionModel = MyRestrictionModel()

  let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]
  
//  @State private var hours = 0
//  @State private var minutes = 0

  init(model: SelectAppsModel) {
    self._viewModel = StateObject(wrappedValue: AppMonitorViewModel(model: model))
  }
  
  var body: some View {
    BGView(imageRsc: .bgMain) {
      ZStack(alignment: .top) {
        VStack(spacing: 8) {
          headerView
          screenTimeSection
//          Spacer()
        }
        
        ScrollView(showsIndicators: false) {
          VStack(spacing: 16) {
            Spacer().frame(height: UIScreen.main.bounds.height * 0.38)
            appBlockingSection
            screentimeAlertsSection
            statsSection
          }
        }
        .padding(.horizontal, 20)
      }
    }
    .task {
      await viewModel.onAppear()
    }
    .onChange(of: viewModel.model.activitySelection) { _ in
      viewModel.onActivitySelectionChange()
    }
  }
  
  private var headerView: some View {
    HStack {
      Spacer()
      Image(systemName: "person.fill")
        .font(.system(size: 24))
        .foregroundStyle(Color.white)
      //      Button(action: { }, label: Image(systemName: "person.fill").font(.system(size: 24)))
    }
    .padding(.horizontal)
  }
  
  private var screenTimeSection: some View {
//    VStack {
      ScreenTimeTodayView()
//      ScreenTimeSectionView(
//        totalTime: 7 * 3600 + 49 * 60,
//        focusTime: 1 * 3600 + 2 * 60,
//        pickups: 72,
//        mostUsedApps: [
//          AppIcon(name: "Apple TV", icon: Image(systemName: "appletv")),
//          AppIcon(name: "YouTube", icon: Image(systemName: "play.display")),
//          AppIcon(name: "CNN", icon: Image(systemName: "play.display"))
//        ]
//      )
//    }
  }
  
  private var appBlockingSection: some View {
    VStack {
      AppBlockingSectionView(
        restrictionModel: restrictionModel,
//        hours: $hours,
//        minutes: $minutes,
//        categories: .constant([.allInternet, .socialMedia, .news]),
        isStrictBlock: .constant(false)
//        onBlock: { /* action */ }
      )
    }
  }
  
  private var screentimeAlertsSection: some View {
    VStack {
      ScreenTimeAlertsSectionView(
        selectedAlertCategories: .constant([.allInternet, .socialMedia, .news]),
        notifyInterval: .constant(30 * 60),
        isAlertEnabled: .constant(true)
      )
    }
  }
  
  private var statsSection: some View {
    VStack {
      StatsSectionView(
        stats: StatsData(
          focusedLifetime: 23 * 3600 + 45 * 60,
          chartData: [
            ChartBar(hour: 0, focusedMinutes: 0, distractedMinutes: 5),
            ChartBar(hour: 6, focusedMinutes: 10, distractedMinutes: 0),
            ChartBar(hour: 12, focusedMinutes: 60, distractedMinutes: 20),
            // ...добавь остальные часы
          ],
          focusedPercent: 28,
          distractedPercent: 31,
          offlinePercent: 51,
          appUsages: [
            //                  AppUsage(name: "Instagram", icon: UIImage(named: "instagram")!, usage: 3 * 3600 + 47 * 60),
            //                  AppUsage(name: "SnapChat", icon: UIImage(named: "snapchat")!, usage: 1 * 3600 + 29 * 60),
            //                  AppUsage(name: "Facebook", icon: UIImage(named: "facebook")!, usage: 54 * 60)
          ]
        )
      )
    }
  }
  
  //MARK: - OLD Implementation (base functional for tracking use of app
  private var oldContentView: some View {
    VStack(spacing: 16) {
      screenTimeSelectButton
      
      if !viewModel.monitoredApps.isEmpty {
        monitoredAppsListView
      } else {
        quickSelectSocialMediaButton
      }
      
      startMonitorButton
      
      selectedAppsView
      
    }
    .padding()
  }
  
  private var selectedAppsView: some View {
    Group {
      if (viewModel.model.activitySelection.applicationTokens.count > 0) {
        ScrollView(.vertical, showsIndicators: false) {
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
  
  //MARK: - Views
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
        Text("Choose Apps to block")
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
        title: Text("Hint"),
        message: Text("Please, chose apps to block"),
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
      Text("Tracking apps")
        .font(.headline)
      
      ForEach(0..<viewModel.monitoredApps.count, id: \.self) { index in
        monitoredAppRow(app: viewModel.monitoredApps[index])
      }
      
      Button("Add more apps") {
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
}


#Preview {
  AppMonitorView(model: SelectAppsModel())
}

// Оригинальный selectedAppsView из ContentView (закомментирован, но можно включить)
/*
 //// Константы для ключей UserDefaults
 //let enabledAppsKey = "EnabledApps"
 //let disabledAppsKey = "DisabledApps"
 //let isAuthorizedKey = "IsAuthorized"
 //
 
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
