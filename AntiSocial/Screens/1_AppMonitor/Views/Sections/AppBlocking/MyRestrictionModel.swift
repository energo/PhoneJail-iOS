//
//  MyRestrictionModel.swift
//  AntiSocial
//
//  Created by D C on 03.07.2025.
//

import SwiftUI

class MyRestrictionModel: ObservableObject {
  @Published var inRestrictionMode = false
  @Published var startHour = 0
  @Published var startMin = 0
  @Published var endHour = 0
  @Published var endMins = 0
  @Published var startTime = ""
  @Published var endTime = ""
}
