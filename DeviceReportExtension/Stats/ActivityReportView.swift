//
//  ActivityReportView.swift
//  AntiSocial
//
//  Created by D C on 07.07.2025.
//

import SwiftUI
import DeviceActivity

struct ActivityReportView: View {
  // Храним выбранную дату
  @State private var selectedDate: Date = Date()
  @State private var refreshTrigger = false
  @State private var lifetimeFocusedTime: TimeInterval = 0
  @Environment(\.scenePhase) var scenePhase
  
  // Контекст отчёта (может быть .totalActivity или ваш собственный)
  let context: DeviceActivityReport.Context = .statsActivity
  
  // Вычисляем фильтр для выбранной даты
  var filter: DeviceActivityFilter {
    DeviceActivityFilter(
      segment: .daily(
        during: Calendar.current.dateInterval(of: .day, for: selectedDate)!
      ),
      users: .all,
      devices: .init([.iPhone])
    )
  }
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      
      HStack {
        Image(.icNavAppBlock)
          .resizable()
          .frame(width: 24, height: 24)
          .foregroundColor(.white)

        Text("Stats")
          .foregroundColor(.white)
          .font(.system(size: 24, weight: .semibold))
        Spacer()
        Text(formatLifetimeTime())
          .foregroundColor(.as_light_green)
          .font(.system(size: 11))
          .lineLimit(1)
      }

      separatorView
        .padding(.vertical, 16)

      datePicker
      
      // Сам отчёт
      if refreshTrigger {
        DeviceActivityReport(context, filter: filter)
      } else {
        DeviceActivityReport(context, filter: filter)
      }
    }
    .padding()
    .background(bgBlur)
    .onChange(of: scenePhase) { newPhase in
      if newPhase == .active {
        // Переключаем триггер для принудительного обновления
        refreshTrigger.toggle()
        Task {
          await loadLifetimeStats()
        }
      }
    }
    .task {
      await loadLifetimeStats()
    }
    .onChange(of: selectedDate) { _ in
      Task {
        await loadLifetimeStats()
      }
    }
  }
  
  private func loadLifetimeStats() async {
    // Получаем данные из SharedData через UserDefaults
    let totalTime = SharedData.getLifetimeTotalBlockingTime()
    await MainActor.run {
      lifetimeFocusedTime = totalTime
    }
  }
  
  private func formatLifetimeTime() -> String {
    let hours = Int(lifetimeFocusedTime) / 3600
    let minutes = (Int(lifetimeFocusedTime) % 3600) / 60
    return "\(hours)H \(minutes)M FOCUSED LIFETIME"
  }
  
  private var separatorView: some View {
    SeparatorView()
  }

  private var datePicker: some View {
    HStack {
      Button(action: {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
      }) {
        Image(systemName: "chevron.left.circle.fill")
          .font(.system(size: 32))
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(.white, .white.opacity(0.07))
      }
      
      Spacer()
      
      Text(dateText)
        .font(.caption)
        .foregroundStyle(.gray)
      
      Spacer()
      
      Button(action: {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
      }) {
        Image(systemName: "chevron.right.circle.fill")
          .font(.system(size: 32))
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(.white, .white.opacity(0.07))
      }
      .disabled(isToday)
      .opacity(isToday ? 0.3 : 1.0)
    }
    .foregroundStyle(Color.white)
  }
  
  private var isToday: Bool {
    Calendar.current.isDateInToday(selectedDate)
  }
  
  private var dateText: String {
    if isToday {
      return "TODAY, " + selectedDate.formatted(.dateTime.month(.wide).day())
    } else {
      // Показываем день недели и дату
      return selectedDate.formatted(.dateTime.weekday(.wide)) + ", " + selectedDate.formatted(.dateTime.month(.wide).day())
    }
  }
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 32)
        .fill(
          Color.white.opacity(0.07)
        )
    }
  }
}

