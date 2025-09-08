//
//  FamilyActivityPickerWrapper.swift
//  AntiSocial
//
//  Created by D C on 28.08.2025.
//

import SwiftUI
import FamilyControls

/// Обертка для FamilyActivityPicker в соответствии с официальной документацией Apple
/// https://developer.apple.com/documentation/familycontrols/familyactivitypicker
struct FamilyActivityPickerWrapper: View {
    @Binding var isPresented: Bool
    @Binding var selection: FamilyActivitySelection
    
    var body: some View {
      NavigationStack {
        FamilyActivityPicker(selection: $selection)
          .toolbar {
            ToolbarItem(placement: .bottomBar) {
              Button(action: {
                isPresented = false
              }) {
                Image(systemName: "xmark.circle.fill")
                  .padding(.horizontal)
                  .foregroundStyle(Color.red)
              }
            }
            
            ToolbarItem(placement: .bottomBar) {
              Button(action: {
                isPresented = false
              }) {
                Image(systemName: "checkmark.circle.fill")
                  .padding(.horizontal)
                  .foregroundStyle(Color.green)
              }
            }
          }
      }
    }
}
