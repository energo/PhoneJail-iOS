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
  
//  @StateObject private var viewModel: AppMonitorViewModel
  @StateObject private var restrictionModel = MyRestrictionModel()
  
  @State private var isShowingProfile: Bool = false
  
  //MARK: - Init Methods
//  init(model: SelectAppsModel) {
//    self._viewModel = StateObject(wrappedValue: AppMonitorViewModel(model: model))
//  }
  
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
            Spacer().frame(height: UIScreen.main.bounds.height * 0.3)
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
//      await viewModel.onAppear()
      
      // Обновляем статистику блокировок для расширения
      await AppBlockingLogger.shared.refreshAllData()
    }
//    .onChangeWithOldValue(of: viewModel.model.activitySelection, perform: { _, _ in
//      viewModel.onActivitySelectionChange()
//    })
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
      AppBlockingSectionView(restrictionModel: restrictionModel)
    }
  }
  
  private var screentimeAlertsSection: some View {
    ScreenTimeAlertsSectionView()
//    VStack {
//      ScreenTimeAlertsSectionView(
//        viewModel: viewModel,
//        selectedAlertCategories: .constant([.allInternet, .socialMedia, .news]),
//        notifyInterval: .constant(30 * 60),
//        isAlertEnabled: .constant(true)
//      )
//    }
  }
  
  private var statsSection: some View {
    ActivityReportView()
      .frame(maxWidth: .infinity)
      .frame(minHeight: 600)
      .frame(maxHeight: .infinity)
  }
}

//MARK: - Preview
#Preview {
//  AppMonitorScreen(model: SelectAppsModel())
  AppMonitorScreen()
}

// Оригинальный selectedAppsView из ContentView (закомментирован, но можно включить)

 //// Константы для ключей UserDefaults
 //let enabledAppsKey = "EnabledApps"
 //let disabledAppsKey = "DisabledApps"
 //let isAuthorizedKey = "IsAuthorized"
 //
//private var selectedAppsView: some View {
//  Group {
//    if (viewModel.model.activitySelection.applicationTokens.count > 0) {
//      ScrollView(.vertical) {
//        LazyVGrid(columns: columns, spacing: 10) {
//          appTokensView
//          categoryTokensView
//        }
//        .padding()
//      }
//      .frame(width: UIScreen.main.bounds.width * 0.9, height: 200)
//    }
//  }
//}
//
//private var appTokensView: some View {
//  ForEach(Array(viewModel.model.activitySelection.applicationTokens), id: \.self) { app in
//    ZStack {
//      RoundedRectangle(cornerRadius: 25, style: .continuous)
//        .fill(.clear)
//        .shadow(radius: 10)
//        .shadow(radius: 10)
//      VStack {
//        Label(app)
//          .shadow(radius: 2)
//          .frame(width: 50, height: 50)
//      }
//      .padding()
//      .multilineTextAlignment(.center)
//    }
//    .frame(width: 100, height: 100)
//    .padding()
//  }
//}
//
//private var categoryTokensView: some View {
//  ForEach(Array(viewModel.model.activitySelection.categoryTokens), id: \.self) { app in
//    ZStack {
//      RoundedRectangle(cornerRadius: 25, style: .continuous)
//        .fill(.clear)
//        .shadow(radius: 10)
//        .shadow(radius: 10)
//      VStack {
//        Label(app)
//          .labelStyle(.iconOnly)
//          .shadow(radius: 2)
//          .scaleEffect(3)
//          .frame(width: 50, height: 50)
//      }
//      .padding()
//      .multilineTextAlignment(.center)
//    }
//    .frame(width: 100, height: 100)
//    .padding()
//  }
//}




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
