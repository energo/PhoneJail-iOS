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
  @EnvironmentObject var familyControlsManager: FamilyControlsManager
  @StateObject private var restrictionModel = MyRestrictionModel()
  
  @State private var isShowingProfile: Bool = false
  
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
            statsSection
            focusBreaksSection
          }
        }
        .padding(.horizontal, 20)
      }
    }
    .fullScreenCover(isPresented: $isShowingProfile, content: {
      ProfileScreen()
    })
    .task {
      await AppBlockingLogger.shared.refreshAllData()
      
      await MainActor.run {
          familyControlsManager.requestAuthorization()
      }
    }
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

//      .padding(.bottom, 16)
      separatorView.padding(.horizontal, 20)

      AppInterruptionsSectionView()

      separatorView.padding(.horizontal, 20)
      
      ScreenTimeAlertsSectionView()
    }
//    .padding()
    .blurBackground()
  }
  
  private var separatorView: some View {
    SeparatorView()
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
  AppMonitorScreen()
}
