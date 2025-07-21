//
//  ScreenTimeSelectAppsModel.swift
//  ScreenTimeTestApp
//
//  Created by D C on 11.02.2025.
//

import SwiftUI
import FamilyControls

class SelectAppsModel: ObservableObject {
  @Published var activitySelection = FamilyActivitySelection.init(includeEntireCategory: false) {
    didSet {
      print("activitySelection \(activitySelection)")
      print("activitySelection applications \(activitySelection.applications.first?.localizedDisplayName ?? "activitySelection applications !!! empty")")

      SharedData.selectedFamilyActivity = activitySelection
    }
  }
  
  init(activitySelection: FamilyActivitySelection = FamilyActivitySelection.init(includeEntireCategory: false)) {
    self.activitySelection = SharedData.selectedFamilyActivity ?? activitySelection
  }
}
