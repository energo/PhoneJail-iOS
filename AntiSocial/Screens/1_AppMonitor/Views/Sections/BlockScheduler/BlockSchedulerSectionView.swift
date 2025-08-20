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
            .sheet(isPresented: $showingAddSchedule) {
                NewBlockSchedulerView(
                    schedule: nil,
                    onSave: { schedule in
                        addSchedule(schedule)
                        showingAddSchedule = false
                    },
                    onDelete: nil
                )
            }
            .sheet(item: $selectedSchedule) { schedule in
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
        VStack(alignment: .leading, spacing: 16) {
            headerView
            separatorView
                        
            if !activeSchedules.isEmpty {
                activeBlocksSection
            }
            
            if !inactiveSchedules.isEmpty {
                inactiveBlocksSection
            }
            
            addButton
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.white)
            
            Text("Block Scheduler")
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .semibold))
            
            Spacer()
        }
    }
    
    private var activeBlocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Blocks (\(activeSchedules.count))")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.as_gray_light)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.as_gray_light)
            }
            
            ForEach(activeSchedules.prefix(3)) { schedule in
                scheduleRow(schedule: schedule, isActive: true)
            }
        }
    }
    
    private var inactiveBlocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Not Active Blocks (\(inactiveSchedules.count))")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.as_gray_light)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
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
            HStack {
                // Lock icon
                Image(systemName: isActive ? "lock.fill" : "lock.open")
                    .foregroundStyle(isActive ? Color.as_red : Color.green)
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(isActive ? Color.as_red.opacity(0.2) : Color.green.opacity(0.2))
                    )
                
                // Schedule details
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                    
                    Text("\(schedule.timeRangeString) • \(schedule.shortDaysString)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.as_gray_light)
                }
                
                Spacer()
                
                // App count and icons
                HStack(spacing: 8) {
                    Text("\(schedule.selection.applicationTokens.count)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.as_white_light)
                    
                    stackedAppIcons(for: schedule)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func stackedAppIcons(for schedule: BlockSchedule) -> some View {
        let tokens = Array(schedule.selection.applicationTokens.prefix(4))
        
        return ZStack {
            ForEach(tokens.indices, id: \.self) { index in
                let token = tokens[index]
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: 20, height: 20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .offset(x: CGFloat(-(tokens.count - 1 - index)) * 12)
                    .zIndex(Double(index))
            }
        }
        .frame(width: CGFloat(20 + (tokens.count - 1) * 12), height: 20)
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white)
                Spacer()
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 9999)
                    .stroke(Color.as_gradietn_main_button, lineWidth: 2)
            )
        }
        .padding(.top, 8)
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
