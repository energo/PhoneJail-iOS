//
//  MainGoalQuizView.swift
//  AntiSocial
//
//  Created by D C on 10.07.2025.
//


import SwiftUI

struct MainGoalQuizView: View {
  @Binding var selectedGoal: String?
  
  let options = [
    "Stop doomscrolling",
    "Improve focus",
    "Reduce screentime",
    "Break your social media addiction",
    "Manage ADHD",
    "Be more mindful",
    "Increase productivity",
    "Eliminate unwanted distractions"
  ]
  
  var body: some View {
    VStack(spacing: 12) {
      Text("I want to...")
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)

      ForEach(options, id: \.self) { option in
        Button(action: {
          selectedGoal = option
        }) {
          HStack {
            Image(systemName: selectedGoal == option ? "largecircle.fill.circle" : "circle")
              .foregroundColor(.white)
            Text(option)
              .foregroundColor(.white)
              .padding(.leading, 4)
            Spacer()
          }
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 30)
              .fill(Color.white.opacity(0.07))
          )
        }
      }
    }
    .padding(.horizontal, 16)
  }
}
