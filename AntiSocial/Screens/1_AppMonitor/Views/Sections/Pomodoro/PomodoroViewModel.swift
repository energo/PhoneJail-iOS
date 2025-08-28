//
//  PomodoroViewModel.swift
//  AntiSocial
//
//  Created by Assistant on 2025.
//

import SwiftUI
import Combine
import FamilyControls

class PomodoroViewModel: ObservableObject {
    @Published var selectedMinutes: Int = 25
    @Published var isRunning: Bool = false
    @Published var timeRemaining: String = "00:00"
    
    private let pomodoroService = PomodoroBlockService.shared
    private var cancellables = Set<AnyCancellable>()
    
    let presetOptions = [5, 10, 15, 25, 30, 45, 60, 90]
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind service state to view model
        pomodoroService.$isActive
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRunning)
        
        // Format remaining time
        pomodoroService.$remainingSeconds
            .receive(on: DispatchQueue.main)
            .map { seconds in
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                return String(format: "%02d:%02d", minutes, remainingSeconds)
            }
            .assign(to: &$timeRemaining)
    }
    
    func startPomodoro() {
        pomodoroService.start(minutes: selectedMinutes, allowWebBlock: true)
    }
    
    func stopPomodoro() {
        pomodoroService.stop()
    }
    
    func togglePomodoro() {
        if isRunning {
            stopPomodoro()
        } else {
            startPomodoro()
        }
    }
}