//
//  FamilyActivityPickerWrapper.swift
//  AntiSocial
//
//  Created by D C on 28.08.2025.
//

import SwiftUI
import FamilyControls

struct FamilyActivityPickerWrapper: View {
    @Binding var isPresented: Bool
    @Binding var selection: FamilyActivitySelection
    
    var body: some View {
        Color.clear
            .familyActivityPicker(
                isPresented: $isPresented,
                selection: $selection
            )
    }
}

struct BackgroundKillView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            uiView.superview?.superview?.backgroundColor = .clear
        }
    }
}
