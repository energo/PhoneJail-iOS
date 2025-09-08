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
  @EnvironmentObject var deviceActivityService: ShieldService
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @EnvironmentObject var scheduleNotificationHandler: ScheduleNotificationHandler
  @StateObject private var schedulerService = BlockSchedulerService.shared
  
  @State private var showingAddSchedule = false
  @State private var selectedSchedule: BlockSchedule?
  @State private var showPaywall = false
  @State private var expandedListType: ScheduleListType?
  
  private let adaptive = AdaptiveValues.current
  
  var activeBlockedSchedules: [BlockSchedule] {
    schedulerService.allSchedules.filter { $0.isActive && $0.isBlocked }
  }
  
  var activeNotBlockedSchedules: [BlockSchedule] {
    schedulerService.allSchedules.filter { $0.isActive && !$0.isBlocked }
  }
  
  var inactiveSchedules: [BlockSchedule] {
    schedulerService.allSchedules.filter { !$0.isActive }
  }
  
  var body: some View {
    contentView
      .padding(20)
      .blurBackground()
      .onAppear {
        schedulerService.reloadSchedules()
      }
      .onReceive(scheduleNotificationHandler.$lastUpdateTimestamp) { _ in
        // Force reload when schedule notification handler triggers an update
        schedulerService.reloadSchedules()
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
      .fullScreenCover(item: $expandedListType) { listType in
        ExpandedScheduleListView(
          listType: listType,
          activeBlockedSchedules: activeBlockedSchedules,
          activeNotBlockedSchedules: activeNotBlockedSchedules,
          inactiveSchedules: inactiveSchedules,
          onSelectSchedule: { schedule in
            expandedListType = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              selectedSchedule = schedule
            }
          },
          onClose: {
            expandedListType = nil
          }
        )
      }
  }
  
  private var contentView: some View {
    VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
      headerView
      separatorView
      
      if activeBlockedSchedules.isEmpty &&
          activeNotBlockedSchedules.isEmpty &&
          inactiveSchedules.isEmpty
      {
        emptyView
      } else {
        activeBlocksSection
        separatorView
        inactiveBlocksSection
      }
      addButton
    }
  }
  
  private var emptyView: some View {
    VStack(alignment: .center) {
      Image(.icNavScheduleBig)
        .resizable()
        .frame(width: 72, height: 72)

      Text("Phone Jail lets you schedule blocks ahead of time. Tap the button below to set up your first one.")
        .foregroundColor(.white)
        .adaptiveFont(\.subheadline)
        .fontWeight(.regular)
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
      Button(action: {
        if activeBlockedSchedules.count > 3 {
          HapticManager.shared.impact(style: .light)
          expandedListType = .active
        }
      }) {
        HStack {
          Text("Active Blocks (\(activeBlockedSchedules.count))")
            .adaptiveFont(\.body)
            .foregroundStyle(Color.white)
          Spacer()
          if activeBlockedSchedules.count > 3 {
            Image(systemName: "chevron.right")
              .adaptiveFont(\.callout)
              .foregroundStyle(Color.as_gray_light)
          }
        }
      }
      .disabled(activeBlockedSchedules.count <= 3)
      
      // Show currently blocking schedules first
      ForEach(activeBlockedSchedules.prefix(3)) { schedule in
        scheduleRow(schedule: schedule)
      }
    }
  }
  
  private var inactiveBlocksSection: some View {
    VStack(alignment: .leading, spacing: adaptive.spacing.small) {
      Button(action: {
        let totalCount = inactiveSchedules.count + activeNotBlockedSchedules.count
        if totalCount > 3 {
          HapticManager.shared.impact(style: .light)
          expandedListType = .inactive
        }
      }) {
        HStack {
          Text("Not Active Blocks (\(inactiveSchedules.count + activeNotBlockedSchedules.count))")
            .adaptiveFont(\.body)
            .foregroundStyle(Color.white)
          Spacer()
          if (inactiveSchedules.count + activeNotBlockedSchedules.count) > 3 {
            Image(systemName: "chevron.right")
              .adaptiveFont(\.callout)
              .foregroundStyle(Color.as_gray_light)
          }
        }
      }
      .disabled((inactiveSchedules.count + activeNotBlockedSchedules.count) <= 3)
      
      // Show active but not currently blocking first (max 3)
      ForEach(activeNotBlockedSchedules.prefix(3)) { schedule in
        scheduleRow(schedule: schedule)
      }
      
      // Then show inactive schedules if there's room (max 3 total in section)
      let remainingSlots = 3 - activeNotBlockedSchedules.prefix(3).count
      if remainingSlots > 0 {
        ForEach(inactiveSchedules.prefix(remainingSlots)) { schedule in
          scheduleRow(schedule: schedule)
            .opacity(0.5) // Make inactive schedules semi-transparent
        }
      }
    }
  }
  
  private func scheduleRow(schedule: BlockSchedule) -> some View {
    Button(action: {
      selectedSchedule = schedule
    }) {
      HStack(spacing: adaptive.spacing.small) {
        // Lock icon - show different states
        Group {
          if schedule.isActive && schedule.isBlocked {
            // Currently blocking - red locked icon
            Image(.icLocked)
              .resizable()
          } else if schedule.isActive && !schedule.isBlocked {
            // Active but not blocking now - normal locked icon
            Image(.icUnlocked)
              .resizable()
          } else {
            // Inactive - unlocked icon
            Image(.icUnlocked)
              .resizable()
          }
        }
        .adaptiveFrame(width: \.iconLarge, height: \.iconLarge)
        
        // Schedule details
        VStack(alignment: .leading, spacing: adaptive.spacing.xxSmall) {
          Text(schedule.name)
            .adaptiveFont(\.body)
            .fontWeight(.semibold)
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.leading)
          
          Text("\(schedule.timeRangeString) • \(schedule.shortDaysString)")
            .adaptiveFont(\.callout)
            .foregroundStyle(Color.as_gray_light)
        }
        
        Spacer()
        
        // App count and icons using reusable component
        if !schedule.selection.applicationTokens.isEmpty || !schedule.selection.categoryTokens.isEmpty {
          UnifiedTokensView(
            familyActivitySelection: schedule.selection,
            spacing: adaptive.spacing.xxSmall,
            tokenTypes: [.applications, .categories]
          )
        }
      }
    }
  }
  
  private var addButton: some View {
    Button(action: {
      HapticManager.shared.impact(style: .light)
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
  
  private func addSchedule(_ schedule: BlockSchedule) {
    // Save the schedule
    BlockSchedule.add(schedule)
    
    // Activate it immediately if it's marked as active
    if schedule.isActive {
      schedulerService.activateSchedule(schedule)
    } else {
      // Still reload to show the new schedule
      schedulerService.reloadSchedules()
    }
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
    // No need to reload manually - schedulerService methods already do it
  }
  
  private func deleteSchedule(_ schedule: BlockSchedule) {
    schedulerService.deactivateSchedule(schedule)
    BlockSchedule.delete(id: schedule.id)
    schedulerService.reloadSchedules()
  }
  
  private func activateSchedule(_ schedule: BlockSchedule) {
    schedulerService.activateSchedule(schedule)
    // No need to reload manually - activateSchedule already does it
  }
  
  private func deactivateSchedule(_ schedule: BlockSchedule) {
    schedulerService.deactivateSchedule(schedule)
    // No need to reload manually - deactivateSchedule already does it
  }
}

// MARK: - SubscriptionManager Extension
extension SubscriptionManager {
  func canCreateSchedule() -> Bool {
    // Check subscription status for creating schedules
    return isSubscriptionActive
  }
}
