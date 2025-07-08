//
//  AppMonitorView.swift
//  AntiSocial
//
//  Created by D C on 08.07.2025.
//

import SwiftUI


struct ProfileScreen: View {
  
  //MARK: - Views
  var body: some View {
    BGView(imageRsc: .bgMain) {
      VStack(spacing: 16) {
        profileHeader
        planBanner
        settingsSection
      }
      .padding()
    }
  }
  
  private var profileHeader: some View {
    HStack(spacing: 16) {
      Image("user_placeholder") // Replace with actual user image
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 52, height: 52)
        .clipShape(Circle())
      
      VStack(alignment: .leading, spacing: 4) {
        Text("Jane Dou")
          .font(.headline)
          .foregroundColor(.white)
        Text("janedou@gmail.com")
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.7))
      }
      
      Spacer()
    }
    .padding()
    .blurBackground()
  }
  
  private var planBanner: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("You are on a free plan")
        .font(.subheadline)
        .foregroundColor(.white)
      Text("Upgrade to Pro to unlock unlimited features")
        .font(.footnote)
        .foregroundColor(.white.opacity(0.7))
      
      Button(action: {
        // Upgrade action
      }) {
        Text("Try for $0")
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity)
          .padding()
          .background(
            LinearGradient(
              gradient: Gradient(colors: [Color.pink, Color.purple]),
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .foregroundColor(.white)
          .cornerRadius(16)
      }
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
    
  }
  
  private var settingsSection: some View {
    VStack(spacing: 1) {
      settingRow(icon: "bell.fill", text: "Notifications") {
        print("Open notifications settings")
      }
      settingRow(icon: "person.2.fill", text: "Invite a friend") {
        //        shareInviteLink()
      }
      settingRow(icon: "doc.text.fill", text: "Contact Us") {
        //        openSupportForm()
      }
      settingRow(icon: "questionmark.circle", text: "FAQ") {
        //        openFAQ()
      }
      settingRow(icon: "shield.fill", text: "Terms & Policy") {
        //        openURL("https://example.com/terms")
      }
      settingRow(icon: "arrow.clockwise", text: "Restore purchases") {
        //        restorePurchases()
      }
      
      settingRow(icon: "rectangle.portrait.and.arrow.forward", text: "Log Out") {
        //        loguout()
      }
      .foregroundColor(.red)
      
    }
    .padding()
    .blurBackground()
  }
  
  
  private func settingRow(icon: String, text: String, action: @escaping () -> Void = {}) -> some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .foregroundColor(.white)
          .frame(width: 24)
        Text(text)
          .foregroundColor(.white)
          .font(.body)
        Spacer()
      }
      .padding(.vertical, 12)
      .contentShape(Rectangle()) // улучшает область нажатия
    }
    .buttonStyle(.plain)
  }
  
  //MARK: - Private Methods
  
}

//MARK: - Previews
#Preview {
  ProfileScreen()
}
