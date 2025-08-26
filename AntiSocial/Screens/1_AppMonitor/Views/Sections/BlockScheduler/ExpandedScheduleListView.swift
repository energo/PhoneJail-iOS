//
//  ExpandedScheduleListView.swift
//  AntiSocial
//
//  Created by Claude on 26.01.2025.
//

import SwiftUI
import FamilyControls

enum ScheduleListType: String, Identifiable {
  case active
  case inactive
  
  var id: String { rawValue }
  
  var title: String {
    switch self {
      case .active:
        return "Active Blocks"
      case .inactive:
        return "Not Active Blocks"
    }
  }
}

struct ExpandedScheduleListView: View {
  let listType: ScheduleListType
  let activeBlockedSchedules: [BlockSchedule]
  let activeNotBlockedSchedules: [BlockSchedule]
  let inactiveSchedules: [BlockSchedule]
  let onSelectSchedule: (BlockSchedule) -> Void
  let onClose: () -> Void
  
  private let adaptive = AdaptiveValues.current
  @Environment(\.dismiss) private var dismiss
  
  var schedulesToShow: [BlockSchedule] {
    switch listType {
      case .active:
        return activeBlockedSchedules
      case .inactive:
        // Show active but not blocked first, then inactive
        return activeNotBlockedSchedules + inactiveSchedules
    }
  }
  
  var body: some View {
    BGView(imageRsc: .bgMain) {
      VStack(spacing: 16) {
        headerView
        
        
        contentView
          .padding(20)
          .blurBackground()
          .padding(.horizontal, adaptive.spacing.medium)
          .padding(.vertical, adaptive.spacing.small)

      }
    }
  }
  
  private var contentView: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(spacing: adaptive.spacing.small) {
        if listType == .active {
          // Show all active blocked schedules
          ForEach(activeBlockedSchedules) { schedule in
            scheduleRow(schedule: schedule)
          }
        } else {
          // Show active but not blocked first
          ForEach(activeNotBlockedSchedules) { schedule in
            scheduleRow(schedule: schedule)
          }
          
          // Then show inactive schedules
          ForEach(inactiveSchedules) { schedule in
            scheduleRow(schedule: schedule)
              .opacity(0.5)
          }
        }
        
        Spacer()
      }
      .padding()
    }
  }
  
  private var headerView: some View {
    HStack {
      Text(listType.title)
        .font(.system(size: 24, weight: .semibold))
        .foregroundStyle(Color.white)
      
      Spacer()
      
      Button(action: { dismiss() }) {
        Image(.icNavClose)
          .frame(width: 24, height: 24)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
  }
  
  private func scheduleRow(schedule: BlockSchedule) -> some View {
    Button(action: {
      onSelectSchedule(schedule)
      dismiss()
    }) {
      HStack(spacing: adaptive.spacing.small) {
        // Lock icon - show different states
        Group {
          if schedule.isActive && schedule.isBlocked {
            Image(.icLocked)
              .resizable()
          } else if schedule.isActive && !schedule.isBlocked {
            Image(.icUnlocked)
              .resizable()
          } else {
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
          
          Text("\(schedule.timeRangeString) • \(schedule.shortDaysString)")
            .adaptiveFont(\.callout)
            .foregroundStyle(Color.as_gray_light)
        }
        
        Spacer()
        
        // App count and icons
        AppTokensView(
          tokens: schedule.selection.applicationTokens,
          spacing: adaptive.spacing.xxSmall
        )
      }
    }
  }
}
