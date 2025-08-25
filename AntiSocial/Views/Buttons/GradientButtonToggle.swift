//
//  GradientButtonToggle.swift
//   
//
//  Created by D C on 24.03.2025.
//

import SwiftUI

struct GradientButtonToggle: View {
  var title: String
  @Binding var isEnabled: Bool

  var body: some View {
    Toggle(isOn: $isEnabled) {
      Text(title)
        .font(.primary())
        .foregroundStyle(Color.white)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal)
//    .tint(Color(hex: "A7A7A7").opacity(0.21))
    .frame(height: 48)
    .background(Color.gradient_bg_not_active)
    .cornerRadius(30)
    .onChangeWithOldValue(of: isEnabled, perform: { oldValue, newValue in
          HapticManager.shared.impact(style: .light)
          HapticManager.shared.isEnabled = newValue
      })
  }
}

#Preview {
  GradientButtonToggle(title: "Haptics", isEnabled: .constant(true))
}
