//
//  ScreenTimeSelectAppsModel.swift
//  ScreenTimeTestApp
//
//  Created by D C on 11.02.2025.
//

import SwiftUI
import FamilyControls

class SelectAppsModel: ObservableObject {
  enum Mode {
    case alert, interruptions
  }
  
  let mode: Mode
  
  @AppStorage("isAlertEnabled") var isAlertEnabled: Bool = false
  @AppStorage("isInterruptionsEnabled") var isInterruptionsEnabled: Bool = false
  
  @Published var activitySelection: FamilyActivitySelection {
    didSet {
      switch mode {
        case .alert:
          SharedData.selectedAlertActivity = activitySelection
        case .interruptions:
          SharedData.selectedInterruptionsActivity = activitySelection
      }
    }
  }
  
  var isEnabled: Bool {
    get {
      switch mode {
        case .alert: return isAlertEnabled
        case .interruptions: return isInterruptionsEnabled
      }
    }
    set {
      switch mode {
        case .alert: isAlertEnabled = newValue
        case .interruptions: isInterruptionsEnabled = newValue
      }
    }
  }
  
  //MARK: - Init Methods
  init(mode: Mode,
       defaultSelection: FamilyActivitySelection = FamilyActivitySelection(includeEntireCategory: false))
  {
    self.mode = mode
    switch mode {
      case .alert:
        self.activitySelection = SharedData.selectedAlertActivity ?? defaultSelection
      case .interruptions:
        self.activitySelection = SharedData.selectedInterruptionsActivity ?? defaultSelection
    }
  }
}
