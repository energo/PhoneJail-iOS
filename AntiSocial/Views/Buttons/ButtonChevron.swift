//
//  FCButtonActive 2.swift
//  RitualAI
//
//  Created by D C on 29.04.2025.
//


import SwiftUI

struct ButtonChevron: View {
  let title: String?
  
  var imageLeft: Image?
  var imageRight: Image?

  var colorBackground: Color = .clear
  var colorTxt: Color = Color.td_black_stroke
  var height: CGFloat = 58
  var showStroke: Bool = false
  var cornerRadius: CGFloat = 20
  
  let action: CompletionVoid
  
  var body: some View {
    contentView
      .frame(maxWidth: .infinity)
      .frame(height: height)
      .background(colorBackground)
      .cornerRadius(cornerRadius)
      .overlay(
        overlayView // Условное добавление overlay
      )
  }
  
  private var contentView: some View {
    Button(action: action) {
      HStack {
        
        if let image = imageLeft {
          image
            .padding(.vertical)
            .foregroundColor(colorTxt)
        } else {
          Spacer()
        }
        
        if let title = title {
          Text(title)
          //                        .bold()
            .font(.system(size: 16, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundColor(colorTxt)
            .padding(.vertical)
        }
                
        if let image = imageRight {
          image
            .padding(.vertical)
            .foregroundColor(colorTxt)
        } else {
          Spacer()
        }
      }
      .padding(.horizontal, 4)
    }
  }
  
  private var overlayView: some View {
    Group {
      if showStroke {
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.white, lineWidth: 1)
      } else {
        Color.clear
      }
    }
  }
}
