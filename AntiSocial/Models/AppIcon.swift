//
//  AppIcon.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import Foundation
import SwiftUI
import UIKit

struct AppIcon: Identifiable {
  let id = UUID()
  let name: String
  let icon: Image
}

enum AppCategory: String, CaseIterable, Identifiable {
  case allInternet = "All Internet"
  case socialMedia = "Social Media"
  case news = "New"
  
  var id: String { rawValue }
  var title: String { rawValue }
  // Можно добавить иконку, если нужно
}

enum AlertCategory: String, CaseIterable, Identifiable {
  case allInternet = "All Internet"
  case socialMedia = "Social Media"
  case news = "New"
  
  var id: String { rawValue }
  var title: String { rawValue }
}
