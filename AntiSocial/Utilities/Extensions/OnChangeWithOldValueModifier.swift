//
//  OnChangeWithOldValueModifier.swift
//  AntiSocial
//
//

import SwiftUI

// MARK: - Кастомный модификатор для iOS < 17
private struct OnChangeWithOldValueModifier<Value: Equatable>: ViewModifier {
  let value: Value
  let action: (Value, Value) -> Void

  @State private var oldValue: Value?

  func body(content: Content) -> some View {
    content
      .onAppear {
        oldValue = value
      }
      .onChange(of: value) { newValue in
        if let oldValue = oldValue, oldValue != newValue {
          action(oldValue, newValue)
        }
        self.oldValue = newValue
      }
  }
}

// MARK: - Расширение View для универсального onChange
extension View {
  func onChangeWithOldValue<Value: Equatable>(
    of value: Value,
    perform action: @escaping (_ oldValue: Value, _ newValue: Value) -> Void
  ) -> some View {
    if #available(iOS 17, *) {
      return self.onChange(of: value, initial: false, action)
    } else {
      return self.modifier(OnChangeWithOldValueModifier(value: value, action: action))
    }
  }
}

