//
//  CircleIconInitial.swift
//  AntiSocial
//
//  Created by D C on 08.07.2025.
//


import SwiftUI

struct CircleIconInitial: View {
    var initial: String
    var backgroundColor: Color = .gray
    var foregroundColor: Color = .white
    var size: CGFloat = 40
    
    var body: some View {
        Text(initial.uppercased())
            .font(.system(size: size / 2))
            .foregroundColor(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

