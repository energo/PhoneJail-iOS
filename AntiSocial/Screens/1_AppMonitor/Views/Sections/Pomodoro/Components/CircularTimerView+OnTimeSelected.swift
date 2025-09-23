//
//  CircularTimerView+OnTimeSelected.swift
//  AntiSocialApp
//
//

import Foundation

extension CircularTimerView {
    func onTimeSelected(_ action: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onTimeSelected = action
        return copy
    }
}
