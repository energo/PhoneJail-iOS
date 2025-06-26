//
//  AppBlockingSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct AppBlockingSectionView: View {
  @Binding var hours: Int
  @Binding var minutes: Int
  
  @Binding var categories: [AppCategory]
  @Binding var isStrictBlock: Bool
  var onBlock: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("App Blocking")
        .font(.headline)
        .foregroundStyle(Color.white)
      separatorView

      VStack {
        HStack {
          Text("Duration")
            .foregroundStyle(Color.white)
          Spacer()
        }
        
        TimePickerView()
      }
      
      separatorView
      
      HStack(spacing: 8) {
        ForEach(AppCategory.allCases, id: \.self) { category in
          Button(action: { toggleCategory(category) }) {
            Text(category.title)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(categories.contains(category) ? Color.accentColor : Color.gray.opacity(0.2))
              .cornerRadius(12)
              .foregroundColor(.white)
          }
        }
      }
      Toggle("Strict Block", isOn: $isStrictBlock)
      Button(action: onBlock) {
        HStack {
          Image(systemName: "lock.fill")
          Text("Swipe to Block")
        }
        .padding()
        .background(Color.as_gradietn_time_text)
        .cornerRadius(16)
      }
    }
    .padding()
    .background(bgBlur)
  }
  
  private var separatorView: some View {
    Rectangle()
      .fill(Color(hex: "D9D9D9").opacity(0.13))
      .frame(height: 0.5)
  }
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 20)
        .fill(
          //          Color(hex: "A7A7A7").opacity(0.2)
          Color.white.opacity(0.07)
        )
//        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
    }
  }
  
  private func toggleCategory(_ category: AppCategory) {
    if let idx = categories.firstIndex(of: category) {
      categories.remove(at: idx)
    } else {
      categories.append(category)
    }
  }
}
