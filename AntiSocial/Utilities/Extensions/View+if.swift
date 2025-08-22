//
//  View+if.swift
//  AntiSocial
//
//  Created by D C on 22.08.2025.
//

import SwiftUI

extension View {
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}
