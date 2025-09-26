//
//  ViewFrameKey.swift
//  AntiSocial
//
//

import SwiftUI

struct NavigationGuideViewFrameKey: PreferenceKey {
  static var defaultValue: Anchor<CGRect>?
  static func reduce(value: inout Anchor<CGRect>?, nextValue next: () -> Anchor<CGRect>?) {
    value = value ?? next()
  }
}

extension View {
  func reportFrame(in space: CoordinateSpace = .global,
                   into binding: Binding<CGRect>) -> some View {
    background(
      Color.clear
        .anchorPreference(key: NavigationGuideViewFrameKey.self, value: .bounds) { $0 }
    )
  }
}
