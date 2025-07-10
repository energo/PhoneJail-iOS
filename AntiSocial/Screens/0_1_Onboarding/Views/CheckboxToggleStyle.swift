//
//  CheckboxToggleStyle.swift
//  AntiSocial
//
//  Created by D C on 10.07.2025.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button(action: {
      configuration.isOn.toggle()
    }) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
          .resizable()
          .frame(width: 24, height: 24)
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(configuration.isOn ? .white :  .white.opacity(0.1), .white.opacity(0.1))
        
        configuration.label
          .foregroundColor(.white)
          .font(.system(size: 16, weight: .regular))
          .multilineTextAlignment(.leading)
      }
      .padding(.vertical, 4)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
