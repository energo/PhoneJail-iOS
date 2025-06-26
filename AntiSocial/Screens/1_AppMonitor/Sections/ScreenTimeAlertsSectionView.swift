//
//  ScreenTimeAlertsSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct ScreenTimeAlertsSectionView: View {
  @Binding var selectedAlertCategories: [AlertCategory]
  @Binding var notifyInterval: TimeInterval
  @Binding var isAlertEnabled: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Screentime Alerts")
        .font(.headline)
        .foregroundStyle(Color.white)
      
      HStack(spacing: 8) {
        ForEach(AlertCategory.allCases, id: \.self) { category in
          Button(action: { toggleCategory(category) }) {
            Text(category.title)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(selectedAlertCategories.contains(category) ? Color.white.opacity(0.85) : Color.gray.opacity(0.2))
              .cornerRadius(30)
              .foregroundColor(.black)
              .font(.system(size: 15, weight: .light))
          }
        }
      }
      
      HStack {
        Text("Notify Me Every")
          .foregroundStyle(Color.white)
        Spacer()
        Picker("", selection: $notifyInterval) {
          ForEach([10, 20, 30, 60], id: \.self) { value in
            Text("\(value) Mins").tag(TimeInterval(value * 60))
          }
        }
        .pickerStyle(.menu)
      }
      Toggle(isOn: $isAlertEnabled) {
        EmptyView()
      }
      .toggleStyle(SwitchToggleStyle(tint: .purple))
    }
    .padding()
    .background(bgBlur)
  }
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 20)
        .fill(
          Color.white.opacity(0.07)
        )
    }
  }
  
  private func toggleCategory(_ category: AlertCategory) {
    if let idx = selectedAlertCategories.firstIndex(of: category) {
      selectedAlertCategories.remove(at: idx)
    } else {
      selectedAlertCategories.append(category)
    }
  }
}
