//
//  NewBlockSchedulerView.swift
//  AntiSocial
//
//  Created by Claude on 19.01.2025.
//

import SwiftUI
import FamilyControls

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
  
  init(schedule: BlockSchedule?, onSave: @escaping (BlockSchedule) -> Void, onDelete: (() -> Void)?) {
    self.schedule = schedule
    self.onSave = onSave
    self.onDelete = onDelete
  }
  
  var body: some View {
    BGView(imageRsc: .bgMain) {
      VStack(spacing: 16) {
        headerView
//        separatorView
//          .padding(.horizontal, 32)

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
//    .padding()
//    .blurBackground()
  }
  
  private var headerView: some View {
    HStack {
      HStack(spacing: 8) {
        Image(isActive ? .icLocked : .icUnlocked)
          .frame(width: 24, height: 24)
          .padding(8)
        
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
    .padding(.horizontal)
    .padding(.vertical, 8)
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
    }
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
      
      Toggle("", isOn: $isStrictBlock)
        .toggleStyle(SwitchToggleStyle(tint: .purple))
    }
  }
  
  private var deleteButton: some View {
    Button(action: {
      onDelete?()
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
    VStack(spacing: 12) {
      if schedule != nil {
        // For existing schedule, show activate/deactivate toggle
        Toggle(isOn: $isActive) {
          Text(isActive ? "Schedule Active" : "Schedule Inactive")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.white)
        }
        .toggleStyle(SwitchToggleStyle(tint: .green))
        .padding(.horizontal)
        .onChange(of: isActive) { _, newValue in
          // Update the schedule without dismissing
          var startComponents = DateComponents()
          startComponents.hour = startHour
          startComponents.minute = startMinute
          
          var endComponents = DateComponents()
          endComponents.hour = endHour
          endComponents.minute = endMinute
          
          let updatedSchedule = BlockSchedule(
            id: schedule?.id ?? UUID().uuidString,
            name: name.isEmpty ? generateDefaultName() : name,
            startTime: startComponents,
            endTime: endComponents,
            daysOfWeek: selectedDays,
            selection: selection,
            isStrictBlock: isStrictBlock,
            isActive: newValue,
            createdAt: schedule?.createdAt ?? Date(),
            updatedAt: Date()
          )
          
          onSave(updatedSchedule)
        }
      } else {
        // For new schedule, show activate button
        activeButton
      }
    }
    .padding()
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
      //          .padding(.vertical, 20)
      .frame(height: UIScreen.main.bounds.width / 7)
      .frame(width: UIScreen.main.bounds.width / 3 * 2)
      .background(Color.as_gradietn_button_purchase)
      .clipShape(RoundedRectangle(cornerRadius: 9999))
    }
    .disabled(!isValidSchedule)
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
      selectedDays = [2, 3, 4, 5, 6] // Weekdays by default
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
  
  // MARK: - Helper Types
  
  struct WeekDay {
    let day: Int
    let name: String
    let fullName: String
  }
  
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
