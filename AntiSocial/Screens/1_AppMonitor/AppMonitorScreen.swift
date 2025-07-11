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

import RevenueCatUI
import RevenueCat

struct AppMonitorScreen: View {
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  
  @StateObject private var viewModel: AppMonitorViewModel
  @StateObject private var restrictionModel = MyRestrictionModel()
  
  @State private var isShowingProfile: Bool = false
  
  let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]
  
  //MARK: - Init Methods
  init(model: SelectAppsModel) {
    self._viewModel = StateObject(wrappedValue: AppMonitorViewModel(model: model))
  }
  
  //MARK: - Views
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
    .fullScreenCover(isPresented: $isShowingProfile, content: {
      ProfileScreen()
    })
    .task {
      await viewModel.onAppear()
      
      // Обновляем статистику блокировок для расширения
      await AppBlockingLogger.shared.refreshAllData()
    }
    .onChangeWithOldValue(of: viewModel.model.activitySelection, perform: { _, _ in
      viewModel.onActivitySelectionChange()
    })
    .presentPaywallIfNeeded(
      requiredEntitlementIdentifier: SubscriptionManager.Constants.entitlementID,
      purchaseCompleted: { customerInfo in
        // Paywall will be dismissed automatically if "pro" is now active.
      },
      restoreCompleted: { customerInfo in
        // Handle restored purchases
        Task {
          try? await subscriptionManager.restorePurchases()
        }
      }
    )
  }
  
  private var headerView: some View {
    HStack {
      Spacer()
      profileButton
    }
    .padding(.horizontal)
  }
  
  private var profileButton: some View {
    Button(action: { isShowingProfile = true },
           label: {
      Image(systemName: "person.fill")
        .font(.system(size: 18))
        .foregroundStyle(Color.white)
        .contentShape(Rectangle())
        .overlay {
          Circle()
            .fill(Color.clear)
            .frame(width: 32, height: 32)
        }
    })
  }
  
  private var screenTimeSection: some View {
    ScreenTimeTodayView()
  }
  
  private var appBlockingSection: some View {
    VStack {
      AppBlockingSectionView(
        restrictionModel: restrictionModel,
        isStrictBlock: .constant(false)
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
    ActivityReportView()
      .frame(maxWidth: .infinity)
      .frame(minHeight: 600)
      .frame(maxHeight: .infinity)
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
  AppMonitorScreen(model: SelectAppsModel())
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
