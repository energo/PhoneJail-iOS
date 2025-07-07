//
//  ChartBar.swift
//  AntiSocial
//
//  Created by D C on 07.07.2025.
//

import Foundation

struct ChartBar: Identifiable {
  let id = UUID()
  let hour: Int
  var focusedMinutes: Int
  var distractedMinutes: Int
}
