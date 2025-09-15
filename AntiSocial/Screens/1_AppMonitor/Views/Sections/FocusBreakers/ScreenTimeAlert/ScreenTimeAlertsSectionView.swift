//
//  ScreenTimeAlertsSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI
import FamilyControls
import ManagedSettings
import RevenueCatUI

struct ScreenTimeAlertsSectionView: View {
  @ObservedObject var viewModel: ScreenTimeAlertViewModel
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @State private var showPaywall = false
  
  var body: some View {
    contentView
      .task {
        await viewModel.onAppear()        
      }
      .onChangeWithOldValue(of: viewModel.model.activitySelection, perform: { _, _ in
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
  }
  
  private var notifyView: some View {
    RoundedPicker(
      title: "Notify me every",
      options: TimeIntervalOption.timeOptions,
      selected: $viewModel.selectedTime,
      labelProvider: { $0.label }
    )
  }
  
  private var whatToMonitorView: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 24) {
        headerView
        SeparatorView()
        selectAppView
        notifyView
        bottomTextView
      }
//      bottomTextView
//        .padding(.top, 4)
//        .padding(.bottom, 12)
    }
  }
  
  private var headerView: some View {
    HStack() {
      Text("Motivational Notifications")
        .foregroundColor(.white)
        .font(.system(size: 16, weight: .regular))
        .layoutPriority(9999)
      
      Spacer()
      
      startMonitorButton
    }
  }
  
  private var bottomTextView: some View {
    Text("Phone Jail will send you motivational notifications to help get you off your phone")
      .foregroundColor(Color.as_light_blue)
      .font(.system(size: 10, weight: .regular))
  }
  
  private var selectAppView: some View {
    Button(action: {
      viewModel.showSelectApps()
    }) {
        HStack(spacing: 8) {
          Text("Apps")
            .foregroundColor(.white)
            .font(.system(size: 15, weight: .regular))
          
          Spacer()
          
          UnifiedTokensView(
            familyActivitySelection: viewModel.model.activitySelection,
            spacing: 8,
            tokenTypes: [.applications, .categories]
          )
          
          Image(systemName: "chevron.right")
            .foregroundColor(Color.as_white_light)
        }
    }
    .fullScreenCover(isPresented: $viewModel.pickerIsPresented) {
      FamilyActivityPickerWrapper(
        isPresented: $viewModel.pickerIsPresented,
        selection: $viewModel.model.activitySelection
      )
    }
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
    return Group {
      let canUse = subscriptionManager.canUseAlertsToday()
      
      if !canUse && !viewModel.isAlertEnabled {
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
        CustomToggleButton(isOn: Binding(
          get: { viewModel.isAlertEnabled },
          set: { newValue in
            HapticManager.shared.impact(style: .light)
            viewModel.isAlertEnabled = newValue
          }
        ),
                           onText: "On",
                           offText: "Off",
                           shouldValidate: true,
                           validationCheck: { viewModel.hasSelectedApps() })
        .frame(width: 80)

//        Toggle("", isOn: Binding(
//          get: { viewModel.isAlertEnabled },
//          set: { newValue in
//            HapticManager.shared.impact(style: .light)
//            viewModel.isAlertEnabled = newValue
//          }
//        ))
//        .foregroundStyle(Color.white)
//        .toggleStyle(SwitchToggleStyle(tint: .purple))
      }
    }
  }
}

//MARK: - Preview
#Preview {
  BGView(imageRsc: .bgMain) {
    ScreenTimeAlertsSectionView(viewModel: ScreenTimeAlertViewModel())
      .environmentObject(SubscriptionManager())
  }
}
