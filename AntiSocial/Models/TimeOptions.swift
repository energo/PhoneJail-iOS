//
//  TimeOptions.swift
//  AntiSocial
//
//  Created by D C on 31.07.2025.
//

import Foundation

// Shared structures for time options used across the app and extensions

struct FrequencyOption: Identifiable, Hashable, Codable {
  var id: UUID = UUID()
  let label: String
  let minutes: Int
}

extension FrequencyOption {
  static let frequencyOptions = [
    FrequencyOption(label: "Rarely", minutes: 60),
    FrequencyOption(label: "Often", minutes: 15),
    FrequencyOption(label: "Very Often", minutes: 2)
  ]
  
  static func option(for minutes: Int) -> FrequencyOption {
    frequencyOptions.first(where: { $0.minutes == minutes }) ?? frequencyOptions[0]
  }
}

extension FrequencyOption: RawRepresentable {
  init?(rawValue: Int) {
    self = FrequencyOption.option(for: rawValue)
  }
  
  var rawValue: Int { minutes }
}

struct TimeIntervalOption: Identifiable, Hashable, Codable {
  var id = UUID()
  let minutes: Int
  var label: String { "\(minutes) Mins" }
}

extension TimeIntervalOption {
  static let timeOptions = [
    TimeIntervalOption(minutes: 2),
    TimeIntervalOption(minutes: 5),
    TimeIntervalOption(minutes: 10),
    TimeIntervalOption(minutes: 15),
    TimeIntervalOption(minutes: 30),
    TimeIntervalOption(minutes: 60)
  ]
  
  static func option(for minutes: Int) -> TimeIntervalOption {
    timeOptions.first(where: { $0.minutes == minutes }) ?? timeOptions[0]
  }
}

extension TimeIntervalOption: RawRepresentable {
  init?(rawValue: Int) {
    self = TimeIntervalOption.option(for: rawValue)
  }
  
  var rawValue: Int { minutes }
}