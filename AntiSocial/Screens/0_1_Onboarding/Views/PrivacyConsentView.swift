//
//  PrivacyConsentView.swift
//  AntiSocial
//
//  Created by D C on 10.07.2025.
//


import SwiftUI

struct PrivacyConsentView: View {
  @Binding var agreedToStorage: Bool
  @Binding var agreedToProcessing: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Your privacy is important to us. That’s why we want to make sure that your use of Phone Jail, happens in a healthy way.")
        .font(.system(size: 14, weight: .regular))
        .foregroundColor(.white)
      
      
      tappableText
      
      Toggle(isOn: $agreedToStorage) {
        Text("Yes, you have my permission to store my private data on Phone Jail servers.")
          .foregroundColor(.white)
          .font(.system(size: 16, weight: .regular))
      }
      .toggleStyle(CheckboxToggleStyle())

      Toggle(isOn: $agreedToProcessing) {
        Text("Yes, Phone Jail may process my data to improve app’s functionality.")
          .foregroundColor(.white)
          .font(.system(size: 16, weight: .regular))
      }
      .toggleStyle(CheckboxToggleStyle())
    }
    .padding(.horizontal, 24)
  }
  
  private var tappableText: some View {
    HStack(spacing: 0) {
      Text("For more information on how we use your data and your rights, read our ")
        .font(.system(size: 14, weight: .regular))
        .foregroundColor(.white)
      +
      Text("[Privacy Policy](https://example.com/privacy)")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(Color.as_hyper_link)
        .underline()
      +
      
      Text(" and ")
        .font(.system(size: 14, weight: .regular))
        .foregroundColor(.white)
      +
      Text("[Terms of Service.](https://example.com/terms)")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(Color.as_hyper_link)
        .underline()
    }
  }
}
