//
//  TextScreen.swift
//  AntiSocial
//
//  Created by D C on 08.07.2025.
//


import SwiftUI

struct TextScreen: View {
  @Environment(\.dismiss) var dismiss
  
  let text: String
  let title: String

  var body: some View {
    BGView {
      VStack {
        headerView

        textView

        Spacer()

        okButton

        Spacer()
      }
      .padding(.top, 8)
      .padding(.horizontal, 24)
    }
  }
  
  private var headerView: some View {
    HStack() {
      Button {
        dismiss()
      } label: {
        Image(systemName: "arrow.left")
          .resizable()
          .frame(width: 18, height: 15)
          .foregroundStyle(Color.white)
          .padding(.trailing, 4)
      }
      
      Text(title)
//        .font(.montserrat(size: .middle))
        .foregroundStyle(Color.white)
      
      Spacer()
    }
  }
  
  private var textView: some View {
    VStack {
      ScrollView {
        Text(text)
          .multilineTextAlignment(.leading)
//          .font(.montserrat(size: .small))
          .foregroundColor(Color.white)
      }
    }
  }

  private var okButton: some View {
    GradientButton(title: "Ok") {
      dismiss()
    }
  }
}

#Preview {
  TextScreen(text: TextScreen.terms, title: "Terms")
}

extension TextScreen {
  static let terms =
 """
Terms and Conditions

Last updated: March 18, 2025

"""

  static let privacy =
  """
Privacy Policy

Last updated: March 18, 2025

"""
}
