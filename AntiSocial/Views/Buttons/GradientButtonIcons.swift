//
//  GradientButtonIcons.swift
//   
//
//

import SwiftUI

struct GradientButtonIcons: View {
  var title: String
  var action: () -> Void
  var leftIcon: ImageResource
  var rightIcon: ImageResource? = nil

  var bgGradient = Color.gradient_bg_not_active
  
  var body: some View {
    Button {
      action()
    } label: {
      HStack {
        Label {
          Text("\(title)")
            .font(.primary())
            .foregroundStyle(Color.white)
        } icon: {
          Image(leftIcon)
            .resizable()
            .frame(width: 19, height: 19)
        }
        .padding(.leading, 12)

        Spacer()

        if rightIcon != nil {
          ZStack {
            Circle()
              .strokeBorder(Color.td_purple, lineWidth: 2)
              .aspectRatio(1, contentMode: .fit)
              .background(
                Circle().foregroundStyle(
                  Color.gradient_bg_not_active
                )
              )
              .frame(width: 26, height: 26)

            Image(rightIcon!)
              .resizable()
              .frame(width: 14, height: 12)
          }
          .padding(.trailing, 12)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 48)
    .background(bgGradient)
    .cornerRadius(30)
  }
}

#Preview {
  GradientButton(title: "Save", action: {})
}
