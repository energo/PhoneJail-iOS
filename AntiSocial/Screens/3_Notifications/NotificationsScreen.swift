//
//  NotificationsScreen.swift
//  AntiSocial
//
//  Created by D C on 08.07.2025.
//


import SwiftUI

struct NotificationsScreen: View {
  @Environment(\.dismiss) var dismiss

  @State private var willEndReminder = false
  @State private var willStartReminder = false
  @State private var screenTimeNotification = false

  var body: some View {
    BGView(imageRsc: .bgMain) {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("Notifications")
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.white)
            .padding(.top, 32)
          
          notificationBlock(
            title: "END BLOCKING SESSION",
            description: "Will End Reminder",
            isOn: $willEndReminder
          )
          
          notificationBlock(
            title: "START BLOCKING SESSION",
            description: "Will Start Reminder",
            isOn: $willStartReminder
          )
          
          notificationBlock(
            title: "SCREENTIME NOTIFICATIONS",
            description: "Get notified when limit is reached",
            isOn: $screenTimeNotification
          )
          
          Spacer()
        }
        .padding()
      }
      .overlay(alignment: .bottom) {
        backButton
      }
    }
  }

  // MARK: - Reusable Notification Row
  private func notificationBlock(title: String,
                                 description: String,
                                 isOn: Binding<Bool>) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.system(size: 14, weight: .regular))
        .foregroundColor(.white)

      HStack {
        Text(description)
          .foregroundColor(.white)
          .font(.system(size: 16, weight: .regular))

        Spacer()

        Toggle("", isOn: Binding(
          get: { isOn.wrappedValue },
          set: { newValue in
            HapticManager.shared.impact(style: .light)
            isOn.wrappedValue = newValue
          }
        ))
          .labelsHidden()
          .toggleStyle(SwitchToggleStyle(tint: .as_blue_toggle))
      }
      .padding()
      .blurBackground()
    }
  }

  // MARK: - Back Button
  private var backButton: some View {
    ButtonBack {
      dismiss()
    }
  }
}

#Preview {
  NotificationsScreen()
}
