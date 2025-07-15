//
//  AppMonitorView.swift
//  AntiSocial
//
//  Created by D C on 08.07.2025.
//

import SwiftUI
import RevenueCatUI

struct ProfileScreen: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var authVM: AuthenticationViewModel
  
  @State private var showPaywall = false
  @State private var showDeleteConfirmation = false
  
  @State private var isAboutViewPresented = false
  @State private var isPrivacyPresented = false
  @State private var isTermsPresented = false
  @State private var isShowNotifcations = false
  @State private var canRequestReview = false
  
  //MARK: - Views
  var body: some View {
    BGView(imageRsc: .bgMain) {
      ScrollView {
        VStack(spacing: 16) {
          profileHeader
          planBanner
          settingsSection
        }
        .padding()
      }
      .overlay(alignment: .bottom) {
        backButton
      }
    }
    .fullScreenCover(isPresented: $isPrivacyPresented) {
      TextScreen(text: TextScreen.privacy, title: "Privacy")
    }
    .fullScreenCover(isPresented: $isTermsPresented) {
      TextScreen(text: TextScreen.terms, title: "Terms")
    }
    .fullScreenCover(isPresented: $showPaywall) {
      return PaywallView(displayCloseButton: true)
    }
    .fullScreenCover(isPresented: $isShowNotifcations) {
      NotificationsScreen()
    }
  }
  
  private var deleteButton: some View {
    Button {
      showDeleteConfirmation = true
    } label: {
      Image(systemName: "trash")
        .resizable()
        .frame(width: 18, height: 20)
        .foregroundStyle(Color.td_pinch)
        .padding(.trailing, 4)
    }
    .alert("Delete all data?", isPresented: $showDeleteConfirmation) {
      Button("Delete", role: .destructive) {
        Task {
          do {
            authVM.signOut()
            try await Storage.shared.deleteUser()
          } catch {
            AppLogger.alert("Failed to delete user and data: \(error.localizedDescription)")
          }
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will delete all your data permanently.")
    }
  }
  
  private var profileHeader: some View {
    HStack(spacing: 16) {
      if let initial = authVM.user?.email.first {
        CircleIconInitial(initial: "\(initial)", size: 64)
      } else {
        Image(.icProfile)
          .resizable()
          .frame(width: 64, height: 64)
          .clipShape(Circle())
      }
      
      VStack(alignment: .leading, spacing: 0) {
        Text(authVM.user?.name ?? "no name")
          .font(.system(size: 24, weight: .semibold))
          .foregroundColor(.white)
        
        Text(authVM.user?.email ?? "no email")
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(Color.white)
      }
      
      Spacer()
      
      deleteButton
    }
    .padding()
    .blurBackground()
    .frame(height: 96)
  }
  
  private var planBanner: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("You are on a free plan")
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(.white)
      Text("Upgrade to Pro to unlock unlimited features")
        .font(.system(size: 14, weight: .regular))
        .foregroundColor(.white)
        .padding(.bottom, 12)
      
      purchaseButton
    }
    .padding()
    .background(
      ZStack {
        BackdropBlurView(isBlack: false, radius: 32)
        RoundedRectangle(cornerRadius: 32)
          .fill(Color(hex: "F2AFAF").opacity(31))
          .stroke(Color.white, lineWidth: 1)
      }.opacity(0.3)
    )
    .frame(height: 138)
  }
  
  private var purchaseButton: some View {
    Button(action: {
      showPaywall = true
    }) {
      Text("Try for $0")
        .font(.system(size: 18, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 24)
            .fill(Color.as_gradietn_button_purchase)
            .stroke(Color.white.opacity(0.5),
                    lineWidth: 1)
        )
        .foregroundColor(.white)
        .cornerRadius(24)
        .frame(height: 45)
    }
  }
  
  private var backButton: some View {
    ButtonBack {
      dismiss()
    }
  }
  
  private var separatorView: some View {
    SeparatorView()
  }
  
  private var settingsSection: some View {
    VStack(spacing: 1) {
      settingRow(icon: "bell.fill", text: "Notifications") {
        isShowNotifcations = true
      }
      
      separatorView
      
      if let url = URL(string: "https://apps.apple.com/app/id6747712365") {
        shareButton(url)
      }

      separatorView
      
//      settingRow(icon: "doc.text.fill", text: "Contact Us") {
//        //        openSupportForm()
//      }
//      
//      separatorView
//      
//      settingRow(icon: "questionmark.circle", text: "FAQ") {
//        //        openFAQ()
//      }
//      
//      separatorView
      
      settingRow(icon: "shield.fill", text: "Terms & Policy") {
        isPrivacyPresented = true
      }
      
      separatorView
      
      settingRow(icon: "arrow.clockwise", text: "Restore purchases") {
        Task {
          try await SubscriptionManager.shared.restorePurchases()
        }
      }
      
      separatorView
      
      settingRow(icon: "rectangle.portrait.and.arrow.forward",
                 text: "Log Out",
                 color: .red) {
        loguOut()
      }
    }
    .padding()
    .blurBackground()
  }
  
  private func shareButton(_ url: URL) -> some View {
    ShareLink(item: url) {
      settingRow(icon: "person.2.fill", text: "Invite a friend")
    }
  }

  
  private func settingRow(icon: String,
                          text: String,
                          color: Color = .white,
                          action: @escaping () -> Void = {}) -> some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .foregroundColor(color)
          .frame(width: 24)
        Text(text)
          .foregroundColor(color)
          .font(.body)
        Spacer()
      }
      .padding(.vertical, 12)
      .contentShape(Rectangle()) // улучшает область нажатия
    }
    .buttonStyle(.plain)
  }
  
  //MARK: - Private Methods
  private func loguOut() {
    authVM.signOut()
  }
}

//MARK: - Previews
#Preview {
  ProfileScreen()
    .environmentObject(AuthenticationViewModel(subscriptionManager: SubscriptionManager()))
}
