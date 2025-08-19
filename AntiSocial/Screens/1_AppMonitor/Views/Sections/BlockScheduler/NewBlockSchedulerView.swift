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
    
    init(schedule: BlockSchedule?, onSave: @escaping (BlockSchedule) -> Void, onDelete: (() -> Void)?) {
        self.schedule = schedule
        self.onSave = onSave
        self.onDelete = onDelete
    }
    
    var body: some View {
        BGView(imageRsc: .bgMain) {
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        contentView
                    }
                    .padding()
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
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "lock.open.fill")
                    .foregroundStyle(Color.green)
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.2))
                    )
                
                Text(schedule != nil ? name : "New Block Scheduler")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            
            Spacer()
            
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var contentView: some View {
        VStack(spacing: 24) {
            if schedule != nil {
                nameSection
                separatorView
            }
            
            timeBlockRangeSection
            separatorView
            
            daysOfWeekSection
            separatorView
            
            whatToBlockSection
            separatorView
            
            strictBlockSection
            
            if schedule != nil && onDelete != nil {
                deleteButton
            }
        }
        .padding()
        .blurBackground()
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var timeBlockRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Block Range")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.white)
            
            HStack(spacing: 24) {
                // Start time
                VStack(spacing: 8) {
                    Text("Start")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.as_gray_light)
                    
                    TimePickerCompact(hour: $startHour, minute: $startMinute)
                }
                
                Text("-")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.white)
                
                // End time
                VStack(spacing: 8) {
                    Text("End")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.as_gray_light)
                    
                    TimePickerCompact(hour: $endHour, minute: $endMinute)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var daysOfWeekSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                        
                        Text("\(selection.applicationTokens.count)")
                            .foregroundStyle(Color.as_white_light)
                        
                        if !selection.applicationTokens.isEmpty {
                            stackedAppIcons
                        }
                        
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.as_red)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 9999)
                    .stroke(Color.as_red, lineWidth: 2)
            )
        }
    }
    
    private var bottomButtons: some View {
        Button(action: {
            if schedule != nil {
                saveSchedule(isActive: schedule?.isActive ?? false)
            } else {
                saveSchedule(isActive: true)
            }
        }) {
            HStack {
                Spacer()
                Text(schedule != nil ? "Save Changes" : "Activate")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white)
                Spacer()
            }
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [Color(hex: "C87BFF"), Color(hex: "FF7B9C")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 9999))
        }
        .padding()
        .disabled(!isValidSchedule)
    }
    
    private var stackedAppIcons: some View {
        let tokens = Array(selection.applicationTokens.prefix(4))
        
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
    
    private func saveSchedule(isActive: Bool) {
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
            isActive: isActive,
            createdAt: schedule?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        onSave(newSchedule)
        dismiss()
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

// MARK: - Compact Time Picker
struct TimePickerCompact: View {
    @Binding var hour: Int
    @Binding var minute: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(String(format: "%d", hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)))
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white)
            
            Text(":")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white)
            
            Text(String(format: "%02d", minute))
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white)
            
            Text(hour < 12 ? "AM" : "PM")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.as_gray_light)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            // In a real implementation, this would show a time picker
            // For now, we'll just cycle through some values
            minute = (minute + 15) % 60
            if minute == 0 {
                hour = (hour + 1) % 24
            }
        }
    }
}