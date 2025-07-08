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

        backButton
      }
      .padding()
    }
  }

  // MARK: - Reusable Notification Row

  private func notificationBlock(title: String, description: String, isOn: Binding<Bool>) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.caption)
        .foregroundColor(.white.opacity(0.7))

      HStack {
        Text(description)
          .foregroundColor(.white)
          .font(.body)

        Spacer()

        Toggle("", isOn: isOn)
          .labelsHidden()
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(Color.white.opacity(0.05))
          .blurBackground()
      )
    }
  }

  // MARK: - Back Button

  private var backButton: some View {
    Button(action: {
      dismiss()
    }) {
      Text("Back")
        .font(.system(size: 18, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 24)
            .fill(Color.white.opacity(0.1))
        )
        .foregroundColor(.white)
    }
  }
}
