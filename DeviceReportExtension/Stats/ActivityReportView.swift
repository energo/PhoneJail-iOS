//
//  ActivityReportView.swift
//  AntiSocial
//
//  Created by D C on 07.07.2025.
//

import SwiftUI
import DeviceActivity
import Combine

extension DeviceActivityReport.Context {
  static let statsActivity = Self("Stats Activity")
}

struct ActivityReportView: View {
  // Храним выбранную дату
  @State private var selectedDate: Date = Date()
  @State private var reportKey = UUID()
  @State private var lifetimeFocusedTime: TimeInterval = 0
  @State private var lastRefreshDate: Date? = nil
  @State private var isChangingDate = false
  @State private var pendingDate: Date? = nil
  private let dateChangeSubject = PassthroughSubject<Date, Never>()
  
  // Храним фильтр как @State чтобы контролировать его обновление
  @State private var currentFilter: DeviceActivityFilter
  
  @Environment(\.scenePhase) var scenePhase
  
  // Контекст отчёта (может быть .totalActivity или ваш собственный)
  let context: DeviceActivityReport.Context = .statsActivity
  
  init() {
    let initialDate = Date()
    _selectedDate = State(initialValue: initialDate)
    _currentFilter = State(initialValue: DeviceActivityFilter(
      segment: .hourly(
        during: Calendar.current.dateInterval(of: .day, for: initialDate)!
      ),
      users: .all,
      devices: .init([.iPhone])
    ))
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
      
      // Сам отчёт с защитой от сбоев
      ZStack {
        // Всегда показываем placeholder чтобы view не исчезала
        Color.clear
          .frame(minHeight: 200)
        
        // Отчёт поверх placeholder
        DeviceActivityReport(context, filter: currentFilter)
          .id(reportKey) // Используем UUID вместо комбинации date+trigger
      }
      .frame(minHeight: 200)
    }
    .padding()
    .background(bgBlur)
    .onAppear {
      // View appeared
    }
    .onReceive(
      dateChangeSubject
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    ) { newDate in
      Task { @MainActor in
        guard newDate != selectedDate else { return }
        
        isChangingDate = true
        selectedDate = newDate
        
        // Создаём новый фильтр для новой даты
        let newFilter = DeviceActivityFilter(
          segment: .hourly(
            during: Calendar.current.dateInterval(of: .day, for: newDate)!
          ),
          users: .all,
          devices: .init([.iPhone])
        )
        
        // Обновляем фильтр и ключ одновременно - только ОДНА перерисовка
        currentFilter = newFilter
        reportKey = UUID()
        
        await loadLifetimeStats()
        isChangingDate = false
      }
    }
    .onChange(of: scenePhase) { newPhase in
      if newPhase == .active {
        // Обновляем только если прошло больше 10 секунд с последнего обновления
        let now = Date()
        if lastRefreshDate == nil || now.timeIntervalSince(lastRefreshDate!) > 10 {
          lastRefreshDate = now
          reportKey = UUID()
          Task {
            await loadLifetimeStats()
          }
        }
      }
    }
    .task {
      await loadLifetimeStats()
      lastRefreshDate = Date()
    }
    // Убрали onChange для selectedDate - теперь используем debounce через Combine
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
        changeDate(by: -1)
      }) {
        Image(systemName: "chevron.left.circle.fill")
          .font(.system(size: 32))
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(.white, .white.opacity(0.07))
      }
      .disabled(isChangingDate)
      
      Spacer()
      
      if isChangingDate {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: .gray))
          .scaleEffect(0.7)
      } else {
        Text(dateText)
          .font(.caption)
          .foregroundStyle(.gray)
      }
      
      Spacer()
      
      Button(action: {
        changeDate(by: 1)
      }) {
        Image(systemName: "chevron.right.circle.fill")
          .font(.system(size: 32))
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(.white, .white.opacity(0.07))
      }
      .disabled(isToday || isChangingDate)
      .opacity(isToday || isChangingDate ? 0.3 : 1.0)
    }
    .foregroundStyle(Color.white)
  }
  
  private func changeDate(by days: Int) {
    guard !isChangingDate else { return }
    
    let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate)!
    
    // НЕ меняем selectedDate здесь!
    // Отправляем в Combine subject для debounce
    dateChangeSubject.send(newDate)
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

