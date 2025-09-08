//
//  ContentView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct TimePickerView: View {
  var steps: Int = 10
  
  @Binding var value1: Int
  @Binding var value2: Int
  
  @State var start1: Int = 0
  @State var end1: Int = 24
  
  @State var start2: Int = 0
  @State var end2: Int = 60
  
  
  @State var selectedSegment: Int = 0
  @State var style: SegmentStyle = .styleOne
  
  var body: some View {
    VStack(spacing: 0) {
      
      ZStack {
        RoundedRectangle(cornerRadius: 30)
          .fill(Color.white.opacity(0.07))
          .frame(width: 60, height: 112)
          .overlay(alignment: .center) {
            Rectangle()
              .fill(Color(hex: "D9D9D9").opacity(0.13))
              .frame(width: 30, height: 0.5)
          }

        VStack {
          CustomPickerView(actualValue: $value1,
                           fromValue: start1,
                           toValue: end1,
                           steps: 1,
                           style: .styleTwo,
                           selectedExtraText: "h")
          
          CustomPickerView(actualValue: $value2,
                           fromValue: start2,
                           toValue: end2,
                           steps: 1,
                           valueStep: 5,
                           style: .styleTwo,
                           selectedExtraText: "m")
        }
      }
    }
    
  }
}
