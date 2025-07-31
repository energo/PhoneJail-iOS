//
//  RoundedPicker.swift
//  AntiSocial
//
//  Created by D C on 21.07.2025.
//


import SwiftUI

struct RoundedPicker<T: Identifiable & Hashable>: View {
  let title: String
  let options: [T]
  @Binding var selected: T
  
  var labelProvider: (T) -> String
  
  var body: some View {
    HStack {
      Text(title)
        .foregroundColor(Color.as_white_light)
        .font(.system(size: 14, weight: .regular))
      Menu {
        ForEach(options) { option in
          Button {
            selected = option
          } label: {
            Text(labelProvider(option))
          }
        }
      } label: {
        HStack {
          Text(labelProvider(selected))
            .foregroundColor(.white)
            .font(.system(size: 12, weight: .regular))
          
          Image(systemName: "chevron.up.chevron.down")
            .foregroundColor(.white)
            .font(.system(size: 12))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
      }
      .preferredColorScheme(.dark)
      
      Spacer()
    }
  }
}
