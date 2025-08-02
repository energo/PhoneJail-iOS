//
//  AppMonitorScreen.swift
//  ScreenTimeTestApp
//
//  Created by D C on 11.02.2025.
//

import SwiftUI
import ScreenTime
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import DeviceActivity
import RevenueCatUI
import RevenueCat

struct AppMonitorScreen: View {
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @EnvironmentObject var familyControlsManager: FamilyControlsManager
  @StateObject private var restrictionModel = MyRestrictionModel()
  @Environment(\.scenePhase) var scenePhase
  
  @StateObject var vmScreenInteraption: AppMonitorViewModel = AppMonitorViewModel(model: SelectAppsModel(mode: .interruptions))
  @StateObject var vmScreenAlert: AppMonitorViewModel = AppMonitorViewModel(model: SelectAppsModel(mode: .alert))

  @State private var isShowingProfile: Bool = false
  @State private var offsetY: CGFloat = .zero
  @State private var headerHeight: CGFloat = UIScreen.main.bounds.height * 0.35
  
  @State private var screenTimeID = UUID() // используется как .id
  @State private var lastRefreshDate = Date()
  
  var body: some View {
    BGView(imageRsc: .bgMain) {
      GeometryReader { screenGeometry in
        ZStack(alignment: .top) {
          
          //          Color.clear
          
          ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
              // Spacer-заполнитель под header
              Color.clear
                .frame(height: headerHeight)
                .overlay() {
                  headerOverlayView(screenGeometry: screenGeometry)
                }
              
              VStack {
                appBlockingSection
                statsSection
                focusBreaksSection
              }
              .padding(.horizontal, 20)
            }
            .background(
              GeometryReader { proxy in
                Color.clear
                  .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                      offsetY = screenGeometry.safeAreaInsets.top
                    }
                  }
                  .onChange(of: proxy.frame(in: .global).minY) { newValue in
                    offsetY = newValue
                  }
                
              }
            )
            //            .padding(.horizontal, 20)
          }
          .refreshable {
            refreshScreenTime()
          }
          
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .fullScreenCover(isPresented: $isShowingProfile) {
      ProfileScreen()
    }
    .task {
      await AppBlockingLogger.shared.refreshAllData()
      await MainActor.run {
        familyControlsManager.requestAuthorization()
      }
    }
    .onChange(of: scenePhase) { newPhase in
      switch newPhase {
      case .active:
        // Check if enough time passed since last refresh (at least 5 seconds)
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshDate)
        if timeSinceLastRefresh > 5 {
          // Refresh screen time data when app becomes active
          refreshScreenTime()
          lastRefreshDate = Date()
        }
      case .inactive, .background:
        break
      @unknown default:
        break
      }
    }
    .presentPaywallIfNeeded(
      requiredEntitlementIdentifier: SubscriptionManager.Constants.entitlementID,
      purchaseCompleted: { _ in },
      restoreCompleted: { _ in
        Task {
          try? await subscriptionManager.restorePurchases()
        }
      }
    )
  }
  
  // MARK: - Header View (Floating)
  @ViewBuilder
  private func headerOverlayView(screenGeometry: GeometryProxy) -> some View {
    VStack(spacing: 8) {
      headerView
      screenTimeSection
    }
    .background(
      GeometryReader { proxy in
        Color.clear.onAppear {
          headerHeight = proxy.size.height
        }
      }
    )
    .offset(y: max(0, screenGeometry.safeAreaInsets.top - offsetY))
  }
  
  // MARK: - Header (Top-right profile)
  private var headerView: some View {
    HStack {
      Spacer()
      profileButton
    }
    .padding(.horizontal)
  }
  
  private var profileButton: some View {
    Button(action: { isShowingProfile = true }) {
      Image(systemName: "person.fill")
        .font(.system(size: 18))
        .foregroundStyle(Color.white)
        .padding()
        .contentShape(Rectangle())
    }
  }
  
  // MARK: - ScreenTime Today Section
  private var screenTimeSection: some View {
    ScreenTimeTodayView(id: screenTimeID)
  }
  
  private func refreshScreenTime() {
    screenTimeID = UUID()
  }
  
  // MARK: - App Blocking
  private var appBlockingSection: some View {
    VStack {
      AppBlockingSectionView(restrictionModel: restrictionModel)
    }
  }
  
  // MARK: - Focus Breaks Section
  private var focusBreaksSectionHeaderView: some View {
    HStack {
      Text("Focus Breaks")
        .foregroundColor(.white)
        .font(.system(size: 19, weight: .medium))
      Spacer()
    }
  }
  
  private var focusBreaksSection: some View {
    VStack {
      focusBreaksSectionHeaderView
        .padding(.top)
        .padding(.horizontal)
      
      separatorView.padding(.horizontal, 20)
      
      AppInterruptionsSectionView(viewModel: vmScreenInteraption)
      
      separatorView.padding(.horizontal, 20)
      
      ScreenTimeAlertsSectionView(viewModel: vmScreenAlert)
    }
    .blurBackground()
  }
  
  private var separatorView: some View {
    SeparatorView()
  }
  
  // MARK: - Stats Section
  private var statsSection: some View {
    ActivityReportView()
      .frame(maxWidth: .infinity)
      .frame(minHeight: 500)
      .frame(maxHeight: .infinity)
  }
}

#Preview {
  AppMonitorScreen()
}
