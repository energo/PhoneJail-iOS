//
//  ConfirmationDialogView.swift
//  AntiSocial
//
//  Created by Assistant on 22.08.2025.
//

import SwiftUI

enum DialogType {
  case deactivate
  case delete
  case strictBlock
  
  var title: String {
    switch self {
      case .deactivate:
        return "Exit this block early?"
      case .delete:
        return "Are you sure you want to delete this schedule?"
      case .strictBlock:
        return "Strict blocking means you can't exit a block early. You also can't delete this app or any other app while it's active."
    }
  }
  
  var confirmButtonTitle: String {
    switch self {
      case .deactivate:
        return "Confirm"
      case .delete:
        return "Confirm"
      case .strictBlock:
        return "Confirm"
    }
  }
  
  var confirmButtonColor: LinearGradient {
    Color.as_gradietn_button_purchase
    //        switch self {
    //        case .deactivate:
    //            return Color.red.opacity(0.8)
    //        case .delete:
    //            return Color.red.opacity(0.8)
    //        case .strictBlock:
    //            return Color.as_gradietn_button_purchase
    //        }
  }
}

struct ConfirmationDialogView: View {
  let dialogType: DialogType
  var isBlur: Bool = false
  var fillAvailableSpace: Bool = false
  let onCancel: () -> Void
  let onConfirm: () -> Void
  
  var body: some View {
    if fillAvailableSpace {
      // Fill available space version
      VStack {
        Spacer()
        
        dialogContent
          .padding()
        
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .if(isBlur, transform: { view in
        view.blurBackground(cornerRadius: 0)
      })
      .if(!isBlur, transform: { view in
        view.background(Color.black.opacity(0.95))
      })
    } else {
      dialogContent
        .padding()
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 32))
      
      //      .frame(maxWidth: .infinity, maxHeight: .infinity)
      //      .background(Color.white.opacity(0.07))
    }
  }
  
  private var dialogContent: some View {
    VStack(spacing: 20) {
      Text(dialogType.title)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(Color.white)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
      
      HStack(spacing: 16) {
        Button(action: {
          HapticManager.shared.impact(style: .light)
          onCancel()
        }) {
          Text("Cancel")
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(Color.white)
            .frame(minWidth: UIScreen.main.bounds.width / 4)
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.width / 9)
            .background(
              RoundedRectangle(cornerRadius: 9999)
                .stroke(Color.as_gradietn_main_button, lineWidth: 2)
            )
        }
        
        Button(action: {
          HapticManager.shared.impact(style: .medium)
          onConfirm()
        }) {
          Text(dialogType.confirmButtonTitle)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(Color.white)
            .frame(minWidth: UIScreen.main.bounds.width / 4)
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.width / 9)
            .background(dialogType.confirmButtonColor)
            .clipShape(RoundedRectangle(cornerRadius: 9999))
        }
      }
    }
  }
}
