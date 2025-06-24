//
//  GradientButton 2.swift
//  RitualAI
//
//  Created by D C on 17.04.2025.
//


import SwiftUI

struct ButtonMain: View {
    enum Size {
        case small
        case normal
        case compact // Новый стиль
    }
    
    var title: String
    var isEnabled: Bool = true
    var size: Size = .normal
    var bgColor: Color = .white
    var txtColor: Color = .black
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(txtColor)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
        .frame(height: frameHeight)
        .background(bgColor)
        .cornerRadius(cornerRadius)
    }
    
    private var frameHeight: CGFloat {
        switch size {
        case .small:
            58
        case .normal:
            58
        case .compact:
            41
        }
    }
    
    private var cornerRadius: CGFloat {
        switch size {
        case .small:
            20
        case .normal:
            12
        case .compact:
            13
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "29292A")
            .ignoresSafeArea()
        VStack(spacing: 16) {
            ButtonMain(title: "Save Small", size: .small, action: {})
            ButtonMain(title: "Save Normal", size: .normal, action: {})
            ButtonMain(title: "Save Compact", size: .compact, action: {})
        }
        .padding()
    }
}
