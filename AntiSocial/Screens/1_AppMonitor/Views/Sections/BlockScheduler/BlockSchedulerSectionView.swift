//
//  BlockSchedulerSectionView.swift
//  AntiSocial
//
//  Created by Claude on 19.01.2025.
//

import SwiftUI
import FamilyControls
import RevenueCatUI

struct BlockSchedulerSectionView: View {
  @EnvironmentObject var deviceActivityService: DeviceActivityService
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @StateObject private var schedulerService = BlockSchedulerService.shared
  
  @State private var schedules: [BlockSchedule] = []
  @State private var showingAddSchedule = false
  @State private var selectedSchedule: BlockSchedule?
  @State private var showPaywall = false
  
  private let adaptive = AdaptiveValues.current
  
  var activeSchedules: [BlockSchedule] {
    schedules.filter { $0.isActive }
  }
  
  var inactiveSchedules: [BlockSchedule] {
    schedules.filter { !$0.isActive }
  }
  
  var body: some View {
    contentView
      .padding()
      .blurBackground()
      .onAppear {
        loadSchedules()
      }
      .fullScreenCover(isPresented: $showingAddSchedule) {
        NewBlockSchedulerView(
          schedule: nil,
          onSave: { schedule in
            addSchedule(schedule)
            showingAddSchedule = false
          },
          onDelete: nil
        )
      }
      .fullScreenCover(item: $selectedSchedule) { schedule in
//      .sheet(item: $selectedSchedule) { schedule in
        NewBlockSchedulerView(
          schedule: schedule,
          onSave: { updatedSchedule in
            updateSchedule(updatedSchedule)
            // Don't set selectedSchedule = nil here to keep the sheet open
            // The user will dismiss it manually with the X button
          },
          onDelete: {
            deleteSchedule(schedule)
            selectedSchedule = nil
          }
        )
      }
      .fullScreenCover(isPresented: $showPaywall) {
        PaywallView(displayCloseButton: true)
          .onDisappear {
            subscriptionManager.refreshSubscription()
          }
      }
  }
  
  private var contentView: some View {
    VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
      headerView
      separatorView
      
//      if !activeSchedules.isEmpty {
        activeBlocksSection
//      }
      
//      if !inactiveSchedules.isEmpty {
        separatorView
        inactiveBlocksSection
//      }
      
      addButton
    }
  }
  
  private var headerView: some View {
    HStack {
      Image(.icNavSchedule)
        .resizable()
        .adaptiveFrame(width: \.iconLarge, height: \.iconLarge)
        .foregroundColor(.white)
      
      Text("Block Scheduler")
        .foregroundColor(.white)
        .adaptiveFont(\.title2)
        .fontWeight(.semibold)
      
      Spacer()
    }
  }
  
  private var activeBlocksSection: some View {
    VStack(alignment: .leading, spacing: adaptive.spacing.small) {
      HStack {
        Text("Active Blocks (\(activeSchedules.count))")
          .adaptiveFont(\.body)
          .foregroundStyle(Color.white)
        Spacer()
        Image(systemName: "chevron.right")
          .adaptiveFont(\.callout)
          .foregroundStyle(Color.as_gray_light)
      }
      
      ForEach(activeSchedules.prefix(3)) { schedule in
        scheduleRow(schedule: schedule, isActive: true)
      }
    }
  }
  
  private var inactiveBlocksSection: some View {
    VStack(alignment: .leading, spacing: adaptive.spacing.small) {
      HStack {
        Text("Not Active Blocks (\(inactiveSchedules.count))")
          .adaptiveFont(\.body)
          .foregroundStyle(Color.white)
        Spacer()
        Image(systemName: "chevron.right")
          .adaptiveFont(\.callout)
          .foregroundStyle(Color.as_gray_light)
      }
      
      ForEach(inactiveSchedules.prefix(3)) { schedule in
        scheduleRow(schedule: schedule, isActive: false)
      }
    }
  }
  
  private func scheduleRow(schedule: BlockSchedule, isActive: Bool) -> some View {
    Button(action: {
      selectedSchedule = schedule
    }) {
      HStack(spacing: adaptive.spacing.small) {
        // Lock icon
        Image(isActive ? .icLocked : .icUnlocked)
          .resizable()
          .adaptiveFrame(width: \.iconLarge, height: \.iconLarge)
        
        // Schedule details
        VStack(alignment: .leading, spacing: adaptive.spacing.xxSmall) {
          Text(schedule.name)
            .adaptiveFont(\.body)
            .fontWeight(.semibold)
            .foregroundStyle(Color.white)
          
          Text("\(schedule.timeRangeString) • \(schedule.shortDaysString)")
            .adaptiveFont(\.callout)
            .foregroundStyle(Color.as_gray_light)
        }
        
        Spacer()
        
        // App count and icons using reusable component
        AppTokensView(
          tokens: schedule.selection.applicationTokens,
          spacing: adaptive.spacing.xxSmall
        )
      }
    }
  }
  
  private var addButton: some View {
    Button(action: {
      if subscriptionManager.canCreateSchedule() {
        showingAddSchedule = true
      } else {
        showPaywall = true
      }
    }) {
      HStack {
        Spacer()
        Text("Add")
          .adaptiveFont(\.body)
          .fontWeight(.semibold)
          .foregroundStyle(Color.white)
        Spacer()
      }
      .padding(.vertical, adaptive.spacing.small)
      .background(
        RoundedRectangle(cornerRadius: 9999)
          .stroke(Color.as_gradietn_main_button, lineWidth: 2)
      )
      .frame(height: adaptive.componentSizes.buttonHeight)
    }
    .padding(.top, adaptive.spacing.xSmall)
  }
  
  private var separatorView: some View {
    SeparatorView()
  }
  
  // MARK: - Functions
  
  private func loadSchedules() {
    schedules = BlockSchedule.loadAll()
  }
  
  private func addSchedule(_ schedule: BlockSchedule) {
    // Save the schedule
    BlockSchedule.add(schedule)
    
    // Activate it immediately if it's marked as active
    if schedule.isActive {
      schedulerService.activateSchedule(schedule)
    }
    
    // Reload schedules to update UI
    loadSchedules()
  }
  
  private func updateSchedule(_ schedule: BlockSchedule) {
    // Update the schedule
    BlockSchedule.update(schedule)
    
    // Handle activation state change
    if schedule.isActive {
      schedulerService.activateSchedule(schedule)
    } else {
      schedulerService.deactivateSchedule(schedule)
    }
    
    // Reload schedules to update UI
    loadSchedules()
  }
  
  private func deleteSchedule(_ schedule: BlockSchedule) {
    deactivateSchedule(schedule)
    BlockSchedule.delete(id: schedule.id)
    loadSchedules()
  }
  
  private func activateSchedule(_ schedule: BlockSchedule) {
    schedulerService.activateSchedule(schedule)
    loadSchedules()
  }
  
  private func deactivateSchedule(_ schedule: BlockSchedule) {
    schedulerService.deactivateSchedule(schedule)
    loadSchedules()
  }
}

// MARK: - SubscriptionManager Extension
extension SubscriptionManager {
  func canCreateSchedule() -> Bool {
    // Check subscription status for creating schedules
    return isSubscriptionActive
  }
}
