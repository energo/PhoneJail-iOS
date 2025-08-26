//
//  NewBlockSchedulerView.swift
//  AntiSocial
//
//  Created by Claude on 19.01.2025.
//

import SwiftUI
import FamilyControls

struct WeekDay {
  let day: Int
  let name: String
  let fullName: String
}

struct NewBlockSchedulerView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var deviceActivityService: DeviceActivityService
  
  let schedule: BlockSchedule?
  let onSave: (BlockSchedule) -> Void
  let onDelete: (() -> Void)?
  
  @State private var name: String = ""
  @State private var startHour: Int = 12
  @State private var startMinute: Int = 0
  @State private var endHour: Int = 13
  @State private var endMinute: Int = 0
  @State private var selectedDays: Set<Int> = []
  @State private var selection: FamilyActivitySelection = FamilyActivitySelection()
  @State private var isStrictBlock: Bool = false
  @State private var showingActivityPicker = false
  @State private var isActive: Bool = false
  @State private var hasUnsavedChanges: Bool = false
  @State private var activeDialog: DialogType? = nil
  
  init(schedule: BlockSchedule?, onSave: @escaping (BlockSchedule) -> Void, onDelete: (() -> Void)?) {
    self.schedule = schedule
    self.onSave = onSave
    self.onDelete = onDelete
  }
  
  var body: some View {
    BGView(imageRsc: .bgMain) {
      VStack(spacing: 16) {
        headerView
          .padding(.horizontal, 32)

        separatorView
          .padding(.horizontal, 32)

        ScrollView {
          VStack(spacing: 24) {
            contentView
          }
          .padding(.horizontal, 32)
        }
        
        bottomButtons
      }
    }
    .onAppear {
      loadScheduleData()
    }
    .familyActivityPicker(
      isPresented: $showingActivityPicker,
      selection: $selection
    )
    .onChange(of: name) { _, _ in
      autoSaveIfNeeded()
    }
    .onChange(of: startHour) { _, newValue in
      updateEndTimeIfNeeded()
      autoSaveIfNeeded()
    }
    .onChange(of: startMinute) { _, newValue in
      updateEndTimeIfNeeded()
      autoSaveIfNeeded()
    }
    .onChange(of: endHour) { _, _ in
      autoSaveIfNeeded()
    }
    .onChange(of: endMinute) { _, _ in
      autoSaveIfNeeded()
    }
    .onChange(of: selectedDays) { _, _ in
      autoSaveIfNeeded()
    }
    .onChange(of: selection) { _, _ in
      autoSaveIfNeeded()
    }
    .onChange(of: isStrictBlock) { _, _ in
      autoSaveIfNeeded()
    }
  }
  
  private var contentView: some View {
    VStack(spacing: 16) {
      nameSection
      separatorView
      
      timeBlockRangeSection
      separatorView
      
      daysOfWeekSection
      separatorView
      
      whatToBlockSection
      separatorView
      
      strictBlockSection
      
      if schedule != nil && onDelete != nil {
        separatorView
        deleteButton
      }
    }
  }
  
  private var headerView: some View {
    HStack {
      HStack(spacing: 8) {
//        Image(isActive ? .icLocked : .icUnlocked)
//          .frame(width: 24, height: 24)
//          .padding(8)
        Group {
          if schedule?.isActive ?? false && schedule?.isBlocked ?? false {
            // Currently blocking - red locked icon
            Image(.icLocked)
              .resizable()
              .frame(width: 24, height: 24)
              .padding(8)

          } else if schedule?.isActive ?? false && !(schedule?.isBlocked ?? false) {
            // Active but not blocking now - normal locked icon
            Image(.icUnlocked)
              .resizable()
              .frame(width: 24, height: 24)
              .padding(8)

          } else {
            // Inactive - unlocked icon
            Image(.icUnlocked)
              .resizable()
              .frame(width: 24, height: 24)
              .padding(8)
              .opacity(0.5)
          }
        }
        
        Text(schedule != nil ? name : "New Block Scheduler")
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(Color.white)
      }
      
      Spacer()
      
      Button(action: { dismiss() }) {
        Image(.icNavClose)
          .frame(width: 24, height: 24)
      }
    }
  }
  
  private var nameSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Schedule Name")
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(Color.white)
      
      TextField("e.g., Work Hours, Study Time", text: $name)
        .textFieldStyle(PlainTextFieldStyle())
        .font(.system(size: 16))
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
  }
  
  private var timeBlockRangeSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Time Block Range")
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(Color.white)
      
      HStack(spacing: 24) {
        TimePickerCompact(hour: $startHour,
                          minute: $startMinute)
        
        Text("-")
          .font(.system(size: 15, weight: .regular))
          .foregroundStyle(Color.white)
        
        TimePickerCompact(hour: $endHour,
                          minute: $endMinute)
      }
      .frame(maxWidth: .infinity)
      .background(Color.white.opacity(0.07))
      .clipShape(RoundedRectangle(cornerRadius: 30))
      
      // Show warning if duration is too short
      if !isDurationValid {
        HStack(spacing: 4) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 12))
          Text("Minimum duration is 15 minutes")
            .font(.system(size: 12))
        }
        .foregroundStyle(Color.orange)
        .padding(.top, 4)
      }
    }
  }
  
  private var isDurationValid: Bool {
    let startMinutes = startHour * 60 + startMinute
    let endMinutes = endHour * 60 + endMinute
    
    let duration: Int
    if endMinutes >= startMinutes {
      duration = endMinutes - startMinutes
    } else {
      // Overnight schedule
      duration = (24 * 60 - startMinutes) + endMinutes
    }
    
    return duration >= 15
  }
  
  private var daysOfWeekSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Days Of Week")
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(Color.white)
      
      HStack(spacing: 8) {
        ForEach(weekDays, id: \.day) { weekDay in
          dayButton(weekDay)
        }
      }
    }
  }
  
  private var whatToBlockSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("What To Block")
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(Color.white)
      
      VStack(spacing: 12) {
        // Apps
        Button(action: { showingActivityPicker = true }) {
          HStack {
            Text("Apps")
              .foregroundStyle(Color.white)
            
            Spacer()
            
            AppTokensView(
              tokens: selection.applicationTokens,
              spacing: 4
            )
            
            Image(systemName: "chevron.right")
              .foregroundStyle(Color.as_white_light)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(Color.white.opacity(0.07))
          .clipShape(RoundedRectangle(cornerRadius: 30))
        }
        
        // Categories
        if !selection.categoryTokens.isEmpty {
          HStack {
            Text("Categories")
              .foregroundStyle(Color.white)
            
            Spacer()
            
            Text("\(selection.categoryTokens.count)")
              .foregroundStyle(Color.as_white_light)
            
            Image(systemName: "chevron.right")
              .foregroundStyle(Color.as_white_light)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(Color.white.opacity(0.07))
          .clipShape(RoundedRectangle(cornerRadius: 30))
        }
      }
    }
  }
  
  private var strictBlockSection: some View {
    HStack {
      Text("Strict Block")
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(Color.white)
      
      Spacer()
      
      Toggle("", isOn: Binding(
        get: { isStrictBlock },
        set: { newValue in
          HapticManager.shared.impact(style: .medium)
          if newValue && !isStrictBlock {
            // Show confirmation dialog when enabling
            activeDialog = .strictBlock
          } else if !newValue {
            // Allow disabling without confirmation
            isStrictBlock = false
            autoSaveIfNeeded()
          }
        }
      ))
        .toggleStyle(SwitchToggleStyle(tint: .purple))
    }
  }
  
  private var deleteButton: some View {
    Button(action: {
      activeDialog = .delete
    }) {
      HStack {
        Spacer()
        Text("Delete Schedule")
          .font(.system(size: 16, weight: .regular))
          .underline()
          .foregroundStyle(Color.as_red)
        Spacer()
      }
      .padding(.vertical, 16)
    }
  }
  
  private var bottomButtons: some View {
    Group {
      if let dialog = activeDialog {
        // Show confirmation dialog
        ConfirmationDialogView(
          dialogType: dialog,
          onCancel: {
            activeDialog = nil
          },
          onConfirm: {
            handleDialogConfirmation(dialog)
          }
        )
        .padding()
      } else {
        VStack(spacing: 12) {
          if schedule != nil {
            // For existing schedule, show take a break button if active
            if isActive {
              takeBreakButton
            } else {
              activateExistingButton
            }
          } else {
            // For new schedule, show activate button
            activeButton
          }
        }
        .padding()
      }
    }
  }
  
  private var activeButton: some View {
    Button(action: {
      activateAndSaveSchedule()
    }) {
      HStack {
        Spacer()
        Text("Activate")
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(Color.white)
        Spacer()
      }
      .frame(height: UIScreen.main.bounds.width / 7)
      .frame(width: UIScreen.main.bounds.width / 3 * 2)
      .background(Color.as_gradietn_button_purchase)
      .clipShape(RoundedRectangle(cornerRadius: 9999))
    }
    .disabled(!isValidSchedule)
  }
  
  private var takeBreakButton: some View {
    Button(action: {
      activeDialog = .deactivate
    }) {
      HStack {
        Spacer()
        Text("Take a break")
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(Color.white)
        Spacer()
      }
      .frame(height: UIScreen.main.bounds.width / 7)
      .frame(width: UIScreen.main.bounds.width / 3 * 2)
      .background(Color.as_gradietn_button_purchase)
      .clipShape(RoundedRectangle(cornerRadius: 9999))
    }
  }
  
  private var activateExistingButton: some View {
    Button(action: {
      isActive = true
      autoSaveIfNeeded()
    }) {
      HStack {
        Spacer()
        Text("Activate")
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(Color.white)
        Spacer()
      }
      .frame(height: UIScreen.main.bounds.width / 7)
      .frame(width: UIScreen.main.bounds.width / 3 * 2)
      .background(Color.as_gradietn_button_purchase)
      .clipShape(RoundedRectangle(cornerRadius: 9999))
    }
  }
  
  private func handleDialogConfirmation(_ dialog: DialogType) {
    switch dialog {
    case .deactivate:
      isActive = false
      autoSaveIfNeeded()
    case .delete:
      onDelete?()
      dismiss()
    case .strictBlock:
      isStrictBlock = true
      autoSaveIfNeeded()
    }
    activeDialog = nil
  }
  
  private func dayButton(_ weekDay: WeekDay) -> some View {
    Button(action: {
      if selectedDays.contains(weekDay.day) {
        selectedDays.remove(weekDay.day)
      } else {
        selectedDays.insert(weekDay.day)
      }
    }) {
      Text(weekDay.name)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(selectedDays.contains(weekDay.day) ? Color.black : Color.white)
        .frame(width: 42, height: 42)
        .background(
          Circle()
            .fill(selectedDays.contains(weekDay.day) ? Color.white : Color.white.opacity(0.1))
        )
    }
  }
  
  private var separatorView: some View {
    SeparatorView()
  }
  
  private var isValidSchedule: Bool {
    if schedule != nil && name.isEmpty {
      return false
    }
    
    // Check duration is at least 15 minutes
    let startMinutes = startHour * 60 + startMinute
    let endMinutes = endHour * 60 + endMinute
    
    let duration: Int
    if endMinutes >= startMinutes {
      duration = endMinutes - startMinutes
    } else {
      // Overnight schedule
      duration = (24 * 60 - startMinutes) + endMinutes
    }
    
    if duration < 15 {
      return false // Schedule too short
    }
    
    return !selectedDays.isEmpty && !selection.applicationTokens.isEmpty
  }
  
  // MARK: - Functions
  
  private func loadScheduleData() {
    if let schedule = schedule {
      name = schedule.name
      startHour = schedule.startTime.hour ?? 12
      startMinute = schedule.startTime.minute ?? 0
      endHour = schedule.endTime.hour ?? 13
      endMinute = schedule.endTime.minute ?? 0
      selectedDays = schedule.daysOfWeek
      selection = schedule.selection
      isStrictBlock = schedule.isStrictBlock
      isActive = schedule.isActive
    } else {
      // Default values for new schedule
      name = generateDefaultName()
      
      // Set default time to current time + 10 minutes for start, +1 hour for end
      let calendar = Calendar.current
      let now = Date()
      let in10Minutes = calendar.date(byAdding: .minute, value: 10, to: now) ?? now
      let in1Hour10Minutes = calendar.date(byAdding: .minute, value: 70, to: now) ?? now
      
      let startComponents = calendar.dateComponents([.hour, .minute], from: in10Minutes)
      let endComponents = calendar.dateComponents([.hour, .minute], from: in1Hour10Minutes)
      
      startHour = startComponents.hour ?? 12
      startMinute = startComponents.minute ?? 0
      endHour = endComponents.hour ?? 13
      endMinute = endComponents.minute ?? 0
      
      // Set default day to today only
      let todayWeekday = calendar.component(.weekday, from: now)
      selectedDays = [todayWeekday]
    }
  }
  
  private func generateDefaultName() -> String {
    let schedules = BlockSchedule.loadAll()
    let existingNames = Set(schedules.map { $0.name })
    
    // Try common names first
    let commonNames = ["Social Media", "Work", "Study", "Sleep", "Focus Time", "Break Time"]
    for name in commonNames {
      if !existingNames.contains(name) {
        return name
      }
    }
    
    // Generate numbered schedule
    var counter = 1
    while existingNames.contains("Schedule \(counter)") {
      counter += 1
    }
    return "Schedule \(counter)"
  }
  
  private func activateAndSaveSchedule() {
    saveScheduleWithStatus(isActive: true)
    dismiss()
  }
  
  private func saveScheduleWithStatus(isActive activeStatus: Bool) {
    var startComponents = DateComponents()
    startComponents.hour = startHour
    startComponents.minute = startMinute
    
    var endComponents = DateComponents()
    endComponents.hour = endHour
    endComponents.minute = endMinute
    
    let newSchedule = BlockSchedule(
      id: schedule?.id ?? UUID().uuidString,
      name: schedule != nil ? name : (name.isEmpty ? generateDefaultName() : name),
      startTime: startComponents,
      endTime: endComponents,
      daysOfWeek: selectedDays,
      selection: selection,
      isStrictBlock: isStrictBlock,
      isActive: activeStatus,
      createdAt: schedule?.createdAt ?? Date(),
      updatedAt: Date()
    )
    
    onSave(newSchedule)
  }
  
  private func updateEndTimeIfNeeded() {
    // Calculate the current duration
    let startMinutes = startHour * 60 + startMinute
    let endMinutes = endHour * 60 + endMinute
    
    let duration: Int
    if endMinutes >= startMinutes {
      duration = endMinutes - startMinutes
    } else {
      // Overnight schedule
      duration = (24 * 60 - startMinutes) + endMinutes
    }
    
    // If duration is less than 15 minutes, auto-adjust end time to be 15 minutes after start
    if duration < 15 {
      let newEndTotalMinutes = startMinutes + 15
      
      if newEndTotalMinutes < 24 * 60 {
        // Same day
        endHour = newEndTotalMinutes / 60
        endMinute = newEndTotalMinutes % 60
      } else {
        // Next day
        let nextDayMinutes = newEndTotalMinutes - (24 * 60)
        endHour = nextDayMinutes / 60
        endMinute = nextDayMinutes % 60
      }
    }
  }
  
  private func autoSaveIfNeeded() {
    guard schedule != nil else { return }
    guard isValidSchedule else { return }
    
    saveScheduleWithStatus(isActive: isActive)
    hasUnsavedChanges = false
    
    // Notify the service to reload schedules
    BlockSchedulerService.shared.reloadSchedules()
  }
  
  // MARK: - Helper Types
  private var weekDays: [WeekDay] {
    [
      WeekDay(day: 1, name: "Sun", fullName: "Sunday"),
      WeekDay(day: 2, name: "Mon", fullName: "Monday"),
      WeekDay(day: 3, name: "Tue", fullName: "Tuesday"),
      WeekDay(day: 4, name: "Wed", fullName: "Wednesday"),
      WeekDay(day: 5, name: "Thu", fullName: "Thursday"),
      WeekDay(day: 6, name: "Fri", fullName: "Friday"),
      WeekDay(day: 7, name: "Sat", fullName: "Saturday")
    ]
  }
}

#Preview {
  NewBlockSchedulerView(
    schedule: nil,
    onSave: { _ in
    },
    onDelete: nil
  )
  .environmentObject(DeviceActivityService.shared)
}
