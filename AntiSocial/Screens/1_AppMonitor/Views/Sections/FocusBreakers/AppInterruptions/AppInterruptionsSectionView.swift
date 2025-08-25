//
//  AppInterruptionsSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI
import FamilyControls
import ManagedSettings
import RevenueCatUI

struct AppInterruptionsSectionView: View {
  @ObservedObject var viewModel: AppInterruptionViewModel
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @State private var showPaywall = false
  
  var body: some View {
    contentView
      .task {
        await viewModel.onAppear()
      }
      .onChangeWithOldValue(of: viewModel.model.activitySelection, perform: { _, newValue in
        viewModel.onActivitySelectionChange()
      })
      .fullScreenCover(isPresented: $showPaywall) {
        PaywallView(displayCloseButton: true)
          .onDisappear {
            // Force refresh subscription status after paywall closes
            SubscriptionManager.shared.refreshSubscription()
          }
      }
  }
  
  private var contentView: some View {
    VStack {
      whatToMonitorView
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
  }
  
  private var frequencyView: some View {
    RoundedPicker(
      title: "Interrupt every",
      options: TimeIntervalOption.timeOptions,
      selected: $viewModel.selectedInterruptionTime,
      labelProvider: { $0.label }
    )
  }
  
  private var bottomTextView: some View {
    Text("Phone Jail will block the apps you select for for a set up period of time.")
      .foregroundColor(Color.as_light_blue)
      .font(.system(size: 10, weight: .regular))
  }
  
  private var whatToMonitorView: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerView
      selectorAppsView
      bottomTextView
      frequencyView
    }
  }
  
  private var headerView: some View {
    HStack {
      Text("App Interruptions")
        .foregroundColor(.white)
        .font(.system(size: 16, weight: .regular))
        .layoutPriority(9999)

      Spacer()
      
      startMonitorButton
    }
  }
  
  private var selectorAppsView: some View {
    Button(action: {
      viewModel.showSelectApps()
    }) {
      VStack(alignment: .leading, spacing: 8) {
        
        // Основной блок — Select Apps (всегда отображается)
        HStack(spacing: 8) {
          Text("Apps")
            .foregroundColor(.white)
            .font(.system(size: 15, weight: .regular))
          
          Spacer()
          
          AppTokensView(
            tokens: viewModel.model.activitySelection.applicationTokens,
            spacing: 8
          )
          
          Image(systemName: "chevron.right")
            .foregroundColor(Color.as_white_light)
        }
        
        // Показываем категории, только если они выбраны
        if !viewModel.model.activitySelection.categoryTokens.isEmpty {
          HStack(spacing: 8) {
            Text("Categories")
              .foregroundColor(.white)
              .font(.system(size: 15, weight: .regular))
            
            Spacer()
            
            CategoryTokensView(
              tokens: viewModel.model.activitySelection.categoryTokens,
              spacing: 8
            )
            
            Image(systemName: "chevron.right")
              .foregroundColor(Color.as_white_light)
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color.white.opacity(0.07))
      .clipShape(RoundedRectangle(cornerRadius: 30))
    }
    .familyActivityPicker(
      isPresented: $viewModel.pickerIsPresented,
      selection: $viewModel.model.activitySelection
    )
  }
  
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 32)
        .fill(
          Color.white.opacity(0.07)
        )
    }
  }
  
  private var startMonitorButton: some View {
    Group {
      let canUse = subscriptionManager.canUseInterruptionsToday()
      
      if !canUse && !viewModel.isInterruptionsEnabled {
        Button(action: {
          HapticManager.shared.impact(style: .light)
          showPaywall = true
        }) {
          HStack(spacing: 6) {
            Image(.icLockPurchase)
              .resizable()
              .frame(width: 16, height: 18)
            Text("Purchase to unlock")
              .foregroundStyle(Color.white)
              .font(.system(size: 12, weight: .regular))
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
        }
      } else {
        Toggle("", isOn: Binding(
          get: { viewModel.isInterruptionsEnabled },
          set: { newValue in
            HapticManager.shared.impact(style: .light)
            viewModel.isInterruptionsEnabled = newValue
          }
        ))
          .foregroundStyle(Color.white)
          .toggleStyle(SwitchToggleStyle(tint: .purple))
      }
    }
  }
}

#Preview {
  BGView(imageRsc: .bgMain) {
    AppInterruptionsSectionView(viewModel: AppInterruptionViewModel())
  }
}
