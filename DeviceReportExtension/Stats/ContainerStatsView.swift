//
//  ContainerStatsView.swift
//  DeviceReportExtension
//

import SwiftUI
import Combine
import DeviceActivity

struct ContainerStatsView: View {
  
  @Environment(\.scenePhase) var scenePhase
  
  @State private var selectedDate: Date = Date()
  @State private var isChangingDate = false
  @State private var isShowingAll = false
  @State private var currentFilter: DeviceActivityFilter
  @State private var lifetimeFocusedTime: TimeInterval = 0
  @State private var lastRefreshDate: Date? = nil
  
  private let dateChangeSubject = PassthroughSubject<Date, Never>()
  private let adaptive = AdaptiveValues.current
  
  init() {
    let initialDate = Date()
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
      
      ActivityReportView(currentFilter: $currentFilter, isShowingAll: $isShowingAll)
    }
    .padding()
    .background(bgBlur)
    .fullScreenCover(isPresented: $isShowingAll, content: {
      AppsActivityView(currentFilter: $currentFilter)
    })
    .onReceive(
      dateChangeSubject
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
        
        // Обновляем только фильтр - DeviceActivityReport сам обновит данные
        currentFilter = newFilter
        
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
      .scaleEffect(isChangingDate ? 0.9 : 1.0)
      .animation(.easeInOut(duration: 0.2), value: isChangingDate)
      
      Spacer()
      
      Text(dateText)
        .font(.caption)
        .foregroundStyle(.gray)
      
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
      .scaleEffect(isChangingDate ? 0.9 : 1.0)
      .animation(.easeInOut(duration: 0.2), value: isChangingDate)
    }
    .foregroundStyle(Color.white)
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
  
  private func loadLifetimeStats() async {
    // Получаем данные из SharedData через UserDefaults
    let totalTime = SharedData.getLifetimeTotalBlockingTime()
    await MainActor.run {
      lifetimeFocusedTime = totalTime
    }
  }
  
  private func changeDate(by days: Int) {
    guard !isChangingDate else { return }
    
    let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate)!
    
    // НЕ меняем selectedDate здесь!
    // Отправляем в Combine subject для debounce
    dateChangeSubject.send(newDate)
  }
  
  private var dateText: String {
    if isToday {
      return "TODAY, " + selectedDate.formatted(.dateTime.month(.wide).day())
    } else {
      // Показываем день недели и дату
      return selectedDate.formatted(.dateTime.weekday(.wide)) + ", " + selectedDate.formatted(.dateTime.month(.wide).day())
    }
  }
  
  private func formatLifetimeTime() -> String {
    let hours = Int(lifetimeFocusedTime) / 3600
    let minutes = (Int(lifetimeFocusedTime) % 3600) / 60
    return "\(hours)H \(minutes)M FOCUSED LIFETIME"
  }
  
  private var isToday: Bool {
    Calendar.current.isDateInToday(selectedDate)
  }
}

