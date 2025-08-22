//
//  TimePickerSheet.swift
//  AntiSocial
//
//  Created by D C on 22.08.2025.
//

import SwiftUI

struct TimePickerSheet: View {
    @Binding var hour: Int
    @Binding var minute: Int
    @Binding var isPresented: Bool
    
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .onAppear {
                        // Set initial date from hour and minute
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                        components.hour = hour
                        components.minute = minute
                        if let date = Calendar.current.date(from: components) {
                            selectedDate = date
                        }
                    }
                    .onChange(of: selectedDate) { _, newDate in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        hour = components.hour ?? 0
                        minute = components.minute ?? 0
                    }
                
                Spacer()
            }
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundStyle(Color.blue)
                }
            }
        }
    }
}
