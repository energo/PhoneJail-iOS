//
//  SimpleButton.swift
//  RitualAI
//
//  Created by D C on 22.04.2025.
//

import SwiftUI

struct ButtonSecondary: View {
  enum Size {
    case small
    case normal
  }
  
  var title: String
  var isEnabled: Bool = true
  var size: Size = .normal
  var action: () -> Void
  
  var body: some View {
    Button {
      action()
    } label: {
      Text("\(title)")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.white)
//        .foregroundStyle(isEnabled ? .white : .black)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
    .frame(maxWidth: .infinity)
    .frame(height: 58)
    .background(
      Color.ri_black_gray
//      Color.gradient_simple_bg
    )
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .inset(by: 1)
        .stroke(
//          Color.init(hex: "0021FF"),
          Color.white.opacity(0.44),
          style: StrokeStyle(
            lineWidth: 2,
            dash: [6, 6]
          )
        )
    )

  }
}

#Preview {
  ZStack {
    Color.init(hex: "29292A")
      .ignoresSafeArea()
    ButtonSecondary(title: "Add Task", action: {})
  }
}
