//
//  UIKitAppear.swift
//  AntiSocial
//
//  Created by D C on 26.09.2025.
//

import UIKit
import SwiftUI

struct UIKitAppear: UIViewControllerRepresentable {
    let action: () -> Void
    func makeUIViewController(context: Context) -> UIAppearViewController {
       let vc = UIAppearViewController()
        vc.action = action
        return vc
    }
    func updateUIViewController(_ controller: UIAppearViewController, context: Context) {
    }
}

class UIAppearViewController: UIViewController {
    var action: () -> Void = {}
    override func viewDidLoad() {
        view.addSubview(UILabel())
    }
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline:.now()) { [weak self] in
            self?.action()
        }
        
    }
}

public extension View {
    func uiKitOnAppear(_ perform: @escaping () -> Void) -> some View {
        self.background(UIKitAppear(action: perform))
    }
}
