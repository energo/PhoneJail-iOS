//
//  ToggleBtn.swift
//  RitualAI
//
//  Created by D C on 28.04.2025.
//


import SwiftUI

struct ToggleBtn: View {
  @Binding var isOn: Bool
  
  private let width: CGFloat = 39
  private let height: CGFloat = 23
  private let circleSize: CGFloat = 16
  private let padding: CGFloat = 3.5
  
  var body: some View {
    ZStack {
      Capsule()
        .stroke(Color.white, lineWidth: 1)
        .frame(width: width, height: height)
        .background(
//          Color(hex: "A7A7A7").opacity(0.21)
          Color.clear
            .clipShape(Capsule())
        )
      
      Circle()
        .fill(Color.white)
        .frame(width: circleSize, height: circleSize)
        .offset(x: isOn ? offsetOn : offsetOff)
        .animation(.easeInOut(duration: 0.25), value: isOn)
    }
    .onTapGesture {
      isOn.toggle()
    }
  }
  
  private var offsetOn: CGFloat {
    (width - circleSize) / 2 - padding
  }
  
  private var offsetOff: CGFloat {
    -(width - circleSize) / 2 + padding
  }
}

#Preview {
  HStack {
    Spacer()
    ToggleBtn(isOn: .constant(false))
    Spacer()
  }
  .background(Color.blue)
  .padding()
}
