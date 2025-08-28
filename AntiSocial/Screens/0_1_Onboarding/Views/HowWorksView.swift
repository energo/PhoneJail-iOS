//
//  HowWorksView.swift
//  AntiSocial
//
//  Created by D C on 08.08.2025.
//



import SwiftUI

struct HowWorks: Hashable {
  let title: String
  let titleIcon: ImageResource
  let description: String
}

extension HowWorks {
  static let options: [HowWorks] = [ .init(title: "Block Distracting Apps",
                                           titleIcon: .onbgHwBlock,
                                         description: "Block time-wasting apps before they hijack your day."),
                                   .init(title: "Manage Your Screentime",
                                         titleIcon: .onbgHwManage,
                                         description: "See where your time really goes. Screentime alerts remind you of what actually matters."),
                                   .init(title: "Interrupt Doomscrolling",
                                         titleIcon: .onbgHwInterrupt,
                                         description: "Break the cycle before it breaks you. App interruptions snap you out of pointless scrolling")
  ]
}

struct HowWorksView: View {
  let options = HowWorks.options
  @State private var animatedItems: Set<Int> = []
  
  var body: some View {
    VStack(spacing: 12) {
      ForEach(Array(options.enumerated()), id: \.element) { index, option in
        VStack(alignment: .leading) {
          HStack {
            Image(option.titleIcon)
              .resizable()
              .frame(width: 24, height: 24)
            
            Text(option.title)
              .foregroundColor(.white)
              .font(.system(size: 18, weight: .semibold))
            Spacer()
          }
          
          Text(option.description)
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
        }
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 30)
            .fill(Color.white.opacity(0.07))
        )
        .offset(y: animatedItems.contains(index) ? 0 : -50)
        .opacity(animatedItems.contains(index) ? 1 : 0)
        .animation(
          .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
            .delay(Double(index) * 0.15),
          value: animatedItems.contains(index)
        )
      }
    }
    .padding(.horizontal, 16)
    .onAppear {
      // Trigger animations with staggered delay
      // Start after a small delay to ensure the parent view is visible
      for index in 0..<options.count {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(index) * 0.12) {
          animatedItems.insert(index)
        }
      }
    }
    .onDisappear {
      // Reset animation state when view disappears
      animatedItems.removeAll()
    }
  }
}
