//
//  AppTokensView.swift
//  AntiSocial
//
//  Created by Claude on 20.01.2025.
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct AppTokensView: View {
    let tokens: Set<ApplicationToken>
    var maxIcons: Int = 4
    var iconSize: CGFloat = 20
    var overlap: CGFloat = -8
    var showCount: Bool = true
    var countFont: Font = .system(size: 14, weight: .regular)
    var countColor: Color = Color.as_white_light
    var spacing: CGFloat = 4
    
    private var tokensArray: [ApplicationToken] {
        Array(tokens.prefix(maxIcons))
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            if showCount {
                Text("\(tokens.count)")
                    .font(countFont)
                    .foregroundStyle(countColor)
            }
            
            if !tokens.isEmpty {
                stackedIcons
            }
        }
    }
    
    private var stackedIcons: some View {
        HStack(spacing: overlap) {
            ForEach(tokensArray.indices, id: \.self) { index in
                let token = tokensArray[index]
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
//                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
//                    .zIndex(Double(tokensArray.count - index)) // Left icon on top
                    .zIndex(Double(index)) // Right icon on top
            }
        }
    }
}

// MARK: - Convenience initializer for categories
struct CategoryTokensView: View {
    let tokens: Set<ActivityCategoryToken>
    var maxIcons: Int = 4
    var iconSize: CGFloat = 20
    var overlap: CGFloat = -8
    var showCount: Bool = true
    var countFont: Font = .system(size: 14, weight: .regular)
    var countColor: Color = Color.as_white_light
    var spacing: CGFloat = 4
    
    private var tokensArray: [ActivityCategoryToken] {
        Array(tokens.prefix(maxIcons))
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            if showCount {
                Text("\(tokens.count)")
                    .font(countFont)
                    .foregroundStyle(countColor)
            }
            
            if !tokens.isEmpty {
                stackedIcons
            }
        }
    }
    
    private var stackedIcons: some View {
        HStack(spacing: overlap) {
            ForEach(tokensArray.indices, id: \.self) { index in
                let token = tokensArray[index]
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .zIndex(Double(index)) // Left icon on top
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Example with default settings
        AppTokensView(tokens: [])
        
        // Example with custom settings
        AppTokensView(
            tokens: [],
            iconSize: 24,
            overlap: -10,
            showCount: false
        )
        
        // Category tokens example
        CategoryTokensView(tokens: [])
    }
    .padding()
    .background(Color.black)
}
