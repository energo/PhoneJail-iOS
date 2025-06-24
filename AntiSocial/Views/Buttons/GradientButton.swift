//
//  ActionButton.swift
//   
//
//  Created by D C on 06.03.2025.
//

import SwiftUI

struct GradientButton: View {
  var title: String
  var isEnabled: Bool = true
  var action: () -> Void
  
  var body: some View {
    Button {
      action()
    } label: {
      Text("\(title)")
        .font(.primary())
        .foregroundStyle(isEnabled ? .white : .black)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
    .frame(maxWidth: .infinity)
    .frame(height: 48)
    .background(isEnabled ? AnyView(Color.gradient_button_action) : AnyView(Color.td_pinch))
    .cornerRadius(30)
  }
}

#Preview {
  GradientButton(title: "Save", action: {})
}
