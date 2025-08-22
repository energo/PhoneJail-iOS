//
//  TimePickerCompact.swift
//  AntiSocial
//
//  Created by D C on 22.08.2025.
//

import SwiftUI

struct TimePickerCompact: View {
  @Binding var hour: Int
  @Binding var minute: Int
  @State private var showingPicker = false
  
  var timeString: String {
    let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
    let period = hour < 12 ? "AM" : "PM"
    return String(format: "%d:%02d %@", displayHour, minute, period)
  }
  
  var body: some View {
    Button(action: {
      showingPicker = true
    }) {
      Text(timeString)
        .font(.system(size: 15, weight: .regular, design: .monospaced))
        .foregroundStyle(Color.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      
    }
    .sheet(isPresented: $showingPicker) {
      TimePickerSheet(hour: $hour, minute: $minute, isPresented: $showingPicker)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
  }
}
