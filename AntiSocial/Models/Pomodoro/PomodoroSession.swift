//
//  PomodoroSession.swift
//  AntiSocial
//
//  Created by Assistant.
//

import Foundation

/// Umbrella model describing a full Pomodoro session (focus + break phases)
final class PomodoroSession: ObservableObject {
  enum Phase: String, Codable { case none, focus, `break` }
  enum EndReason: String, Codable { case autoTimer, manualStop }

  // Identity
  var id: String = UUID().uuidString

  // Current runtime state
  @Published var isRunning: Bool = false
  @Published var currentPhase: Phase = .none
  @Published var isBlockingPhase: Bool = true

  // Timeline
  @Published var startedAt: Date? = nil
  @Published var unlockAt: Date? = nil

  // Last termination info
  @Published var stoppedByUser: Bool = false
  @Published var lastEndReason: EndReason? = nil
  @Published var lastEndedAt: Date? = nil

  init() {}

  func start(phase: Phase, unlockAt: Date, isBlockingPhase: Bool) {
    self.isRunning = true
    self.currentPhase = phase
    self.startedAt = Date()
    self.unlockAt = unlockAt
    self.isBlockingPhase = isBlockingPhase
    self.stoppedByUser = false
    self.lastEndReason = nil
    self.lastEndedAt = nil
  }

  func end(reason: EndReason) {
    self.isRunning = false
    self.stoppedByUser = (reason == .manualStop)
    self.lastEndReason = reason
    self.lastEndedAt = Date()
    self.currentPhase = .none
  }
}
