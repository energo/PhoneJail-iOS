//
//  RoundedPicker.swift
//  AntiSocial
//
//  Created by D C on 21.07.2025.
//


import SwiftUI

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

//struct FrequencyOption: Identifiable, Hashable {
//  let id = UUID()
//  let label: String
//  let minutes: Int
//}
//
//extension FrequencyOption {
//  static  let frequencyOptions = [
//    FrequencyOption(label: "Rarely", minutes: 60),
//    FrequencyOption(label: "Often", minutes: 15),
//    FrequencyOption(label: "Very Often", minutes: 5)
//  ]
//}
//
//struct TimeIntervalOption: Identifiable, Hashable {
//  let id = UUID()
//  let minutes: Int
//  var label: String { "\(minutes) Mins" }
//}
//
//extension TimeIntervalOption {
//  static let timeOptions = [
//    TimeIntervalOption(minutes: 5),
//    TimeIntervalOption(minutes: 10),
//    TimeIntervalOption(minutes: 15),
//    TimeIntervalOption(minutes: 30),
//    TimeIntervalOption(minutes: 60)
//  ]
//}

struct RoundedPicker<T: Identifiable & Hashable>: View {
  let title: String
  let options: [T]
  @Binding var selected: T
  
  var labelProvider: (T) -> String
  
  var body: some View {
    HStack {
      Text(title)
        .foregroundColor(Color.as_white_light)
        .font(.system(size: 14, weight: .regular))
      Menu {
        ForEach(options) { option in
          Button {
            selected = option
          } label: {
            Text(labelProvider(option))
          }
        }
      } label: {
        HStack {
          Text(labelProvider(selected))
            .foregroundColor(.white)
            .font(.system(size: 12, weight: .regular))
          
          Image(systemName: "chevron.up.chevron.down")
            .foregroundColor(.white)
            .font(.system(size: 12))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
      }
      .preferredColorScheme(.dark)
      
      Spacer()
    }
  }
}
