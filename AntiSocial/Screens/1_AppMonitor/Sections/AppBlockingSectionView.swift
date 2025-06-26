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
  
  @State var isUnlocked: Bool = false
  
  var onBlock: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerVeiw
      separatorView
      durationSection
      separatorView
      whatToBlockView
      separatorView
      stricktBlockView
      separatorView
      swipeBlockView
    }
    .padding()
    .background(bgBlur)
  }
  
  private var swipeBlockView: some View {
    SlideToTurnOnView(isUnlocked: $isUnlocked)
//    Button(action: onBlock) {
//      HStack {
//        Image(systemName: "lock.fill")
//        Text("Swipe to Block")
//      }
//      .padding()
//      .background(Color.as_gradietn_time_text)
//      .cornerRadius(16)
//    }
  }
  
  private var stricktBlockView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Toggle("Strict Block", isOn: $isStrictBlock)
        .foregroundStyle(Color.white)
    }
  }
  
  private var whatToBlockView: some View {
    VStack(alignment: .leading, spacing: 16) {
      
      Text("What to Block")
        .foregroundStyle(Color.white)
      
      HStack(spacing: 8) {
        ForEach(AppCategory.allCases, id: \.self) { category in
          Button(action: { toggleCategory(category) }) {
            Text(category.title)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(categories.contains(category) ? Color.white.opacity(0.85) : Color.gray.opacity(0.2))
              .cornerRadius(30)
              .foregroundColor(.black)
              .font(.system(size: 15, weight: .light))
          }
        }
      }
    }
  }
  
  private var headerVeiw: some View {
    Text("App Blocking")
      .font(.headline)
      .foregroundStyle(Color.white)
  }
  
  private var durationSection: some View {
    VStack {
      HStack {
        Text("Duration")
          .foregroundStyle(Color.white)
        Spacer()
      }
      
      TimePickerView()
    }
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
          Color.white.opacity(0.07)
        )
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
