//
//  ChartBar.swift
//  AntiSocial
//
//  Created by D C on 07.07.2025.
//

import Foundation

struct ChartBar: Identifiable {
  var id: Int { hour } // <-- фикс
  let hour: Int
  var focusedMinutes: Int
  var distractedMinutes: Int
}

