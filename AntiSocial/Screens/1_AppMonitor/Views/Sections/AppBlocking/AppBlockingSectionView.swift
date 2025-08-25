//
//  AppBlockingSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI
import WidgetKit
import FamilyControls
import ManagedSettings
import Combine
import RevenueCatUI


struct AppBlockingSectionView: View {
  @EnvironmentObject var deviceActivityService: DeviceActivityService
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @ObservedObject var restrictionModel: MyRestrictionModel
  
  @State var hours: Int = 0
  @State var minutes: Int = 0
  
  @State private var isStrictBlock: Bool = SharedData.userDefaults?.bool(forKey: SharedData.Widget.isStricted) ?? false
  @State private var isBlocked: Bool = SharedData.userDefaults?.bool(forKey: SharedData.Widget.isBlocked) ?? false
  @State private var showStrictBlockDialog: Bool = false
  
  private let adaptive = AdaptiveValues.current
  
  @State private var noCategoriesAlert = false
  @State private var maxCategoriesAlert = false
  @State private var isDiscouragedPresented = false
  @State private var currentTimer: Timer.TimerPublisher?
  @State private var timerConnection: Cancellable?
  @State private var timerID = UUID() // Для отладки
  
  @State private var timeRemainingString: String = ""
  @State private var timeBlockedString: String = ""
  @State private var blockingCount = 0 // Счетчик блокировок
  @State private var totalSavedTime: TimeInterval = 0 // Общее время за сегодня
  @State private var currentSessionSavedTime: String = "0h 00m" // Текущая сессия
  @State private var showPaywall = false
  
  // MARK: - Constants
  private enum Constants {
    enum Timer {
      static let updateInterval: TimeInterval = 1.0
      static let animationDelay: TimeInterval = 0.6
    }
    
    enum TimeFormat {
      static let initialBlocked = "0h 00m"
      static let initialRemaining = "0:00:00"
      static let remainingFormat = "%d:%02d:%02d"
      static let blockedFormat = "%dh %02dm"
    }
    
    enum TimeCalculation {
      static let secondsInHour = 3600
      static let secondsInMinute = 60
      static let secondsInDay = 86400 // 24 часа - максимальное разумное время блокировки
    }
  }
  
  var body: some View {
    contentView
      .blurBackground()
      .onChange(of: isBlocked) { _, newValue in
        if newValue {
          // При включении блокировки сразу сбрасываем счетчик
          timeBlockedString = Constants.TimeFormat.initialBlocked
          currentSessionSavedTime = Constants.TimeFormat.initialBlocked
          timeRemainingString = deviceActivityService.timeRemainingString
        } else {
          // При выключении блокировки очищаем все данные
          timeBlockedString = Constants.TimeFormat.initialBlocked
          currentSessionSavedTime = Constants.TimeFormat.initialBlocked
          // ВАЖНО: Очищаем timestamp чтобы избежать проблем при следующем запуске
          SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
          AppLogger.trace("Cleared blocking timestamp on disable")
        }
      }
      .onAppear {
        // isBlocked и isStrictBlock уже инициализированы правильными значениями из SharedData
        
        // Reload saved app selection
        deviceActivityService.loadSelection()
        
        // Загружаем общее время за сегодня
        loadTotalSavedTime()
        
        // Unlock date is already loaded in DeviceActivityService init
        
        timeRemainingString = deviceActivityService.timeRemainingString
        
        // Проверяем состояние блокировки
        if isBlocked {
          // Перезагружаем unlock date из SharedData на случай если синглтон не успел загрузиться
          deviceActivityService.loadUnlockDate()
          
          // Check if we have a valid unlock date
          if let unlockDate = deviceActivityService.unlockDate, unlockDate > Date() {
            // Блокировка еще активна - восстанавливаем состояние
            
            // Проверяем и восстанавливаем timestamp если он отсутствует
            if SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp) == nil ||
                SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp) == 0 {
              // Устанавливаем текущее время как время начала блокировки
              // Это не точно, но лучше чем 0
              SharedData.userDefaults?.set(Date().timeIntervalSince1970, forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
              AppLogger.notice("Restored blocking start timestamp with current time")
            }
            
            timeBlockedString = calculateBlockedTime()
            currentSessionSavedTime = formatSavedTime()
            
            // Восстанавливаем ограничения приложений если они не активны
            deviceActivityService.setShieldRestrictions(isStrictBlock)
            
            AppLogger.notice("Restored active blocking state on app start")
          } else {
            // Блокировка истекла или нет unlockDate - завершаем ее
            isBlocked = false
            SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
            SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
            SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.unlockDate)
            timeBlockedString = Constants.TimeFormat.initialBlocked
            currentSessionSavedTime = Constants.TimeFormat.initialBlocked
            AppLogger.notice("Blocking expired or invalid - cleaning up")
          }
        } else {
          // Блокировка неактивна - очищаем старые timestamp'ы и unlock date
          SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
          SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.unlockDate)
          timeBlockedString = Constants.TimeFormat.initialBlocked
          currentSessionSavedTime = Constants.TimeFormat.initialBlocked
          AppLogger.trace("Cleared stale data on app start (blocking inactive)")
        }
        
        //TODO: - need to refactor (looks like odd properties)
        if let savedHour = SharedData.userDefaults?.integer(forKey: SharedData.Widget.endHour),
           let savedMin = SharedData.userDefaults?.integer(forKey: SharedData.Widget.endMinutes) {
          restrictionModel.endHour = savedHour
          restrictionModel.endMins = savedMin
        }
        
        // Load saved time if not currently blocked
        if !isBlocked {
          // Load saved duration
          hours = SharedData.userDefaults?.integer(forKey: SharedData.AppBlocking.savedDurationHours) ?? 0
          minutes = SharedData.userDefaults?.integer(forKey: SharedData.AppBlocking.savedDurationMinutes) ?? 0
        }
        
        // Start timer if already blocked
        if isBlocked {
          // Перезагружаем unlock date еще раз перед запуском таймера
          deviceActivityService.loadUnlockDate()
          
          if let unlockDate = deviceActivityService.unlockDate, unlockDate > Date() {
            // If we have a timestamp, calculate current blocked time
            if SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp) != nil {
              timeBlockedString = calculateBlockedTime()
            }
            startTimer()
            AppLogger.notice("Restored timer for active blocking")
          } else {
            // Если unlock date все еще нет или она истекла, сбрасываем блокировку
            isBlocked = false
            SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isBlocked)
            AppLogger.notice("Timer not started - blocking invalid")
          }
        }
      }
      .onReceive(currentTimer ?? Timer.publish(every: 999, on: .main, in: .common)) { _ in
        // Обработка тиков таймера - только если таймер активен и блокировка включена
        guard timerConnection != nil && isBlocked else { return }
        
        guard let unlockDate = deviceActivityService.unlockDate else { return }
        
        // Обновляем время до разблокировки
        timeRemainingString = formatRemainingTime(unlockDate.timeIntervalSinceNow)
        
        // Обновляем время блокировки
        timeBlockedString = calculateBlockedTime()
        
        // Обновляем время текущей сессии
        currentSessionSavedTime = formatSavedTime()
        
        // Обновляем общее время за сегодня
        loadTotalSavedTime()
        
        // Проверяем завершение блокировки
        if unlockDate <= Date() {
          isBlocked = false
          BlockingNotificationService.shared.stopBlocking(selection: deviceActivityService.selectionToDiscourage)
          // Очищаем timestamp при автоматическом завершении
          SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
          AppLogger.trace("Cleared timestamp on auto-completion")
          stopTimer()
        }
      }
      .onDisappear {
        stopTimer()
      }
      .alert("No categories selected", isPresented: $noCategoriesAlert) {
        Button("OK", role: .cancel) { }
      }
      .alert("Too many categories selected", isPresented: $maxCategoriesAlert) {
        Button("OK", role: .cancel) { }
      }
      .fullScreenCover(isPresented: $showPaywall) {
        PaywallView(displayCloseButton: true)
          .onDisappear {
            // Force refresh subscription status after paywall closes
            subscriptionManager.refreshSubscription()
          }
      }
  }
  
  //MARK: - Views
  private var contentView: some View {
    VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
      // Время до разблокировки - показываем с анимацией
      if isBlocked && deviceActivityService.unlockDate != nil && (deviceActivityService.unlockDate ?? Date()) > Date() {
        timeRemainingView
          .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
      }
      
      // Основные настройки - скрываем с анимацией когда заблокировано
      if !isBlocked || deviceActivityService.unlockDate == nil || (deviceActivityService.unlockDate ?? Date()) <= Date() {
        VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
          headerView
          separatorView
          durationSection
          separatorView
          whatToBlockView
//          separatorView
        }
        .padding(.horizontal)
        .padding(.top)
        .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale)))
        
        // ZStack для strictBlockView, separatorView и swipeBlockView с диалогом
        ZStack {
          VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
            separatorView
            strictBlockView
            separatorView
            
            swipeBlockView
              .padding(.bottom, adaptive.spacing.xSmall)
          }
          .padding(.horizontal)
          .padding(.bottom)
          .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale)))
          
          // Dialog overlay - показывается поверх strictBlockView, separatorView и swipeBlockView
          if showStrictBlockDialog {
            ConfirmationDialogView(
              dialogType: .strictBlock,
              isBlur: true,
              fillAvailableSpace: true,
              onCancel: {
                showStrictBlockDialog = false
              },
              onConfirm: {
                HapticManager.shared.notification(type: .warning)
                isStrictBlock = true
                SharedData.userDefaults?.set(true, forKey: SharedData.Widget.isStricted)
                showStrictBlockDialog = false
              }
            )
            .transition(.opacity)
          }
        }
      } else {
        // Когда заблокировано - показываем только swipeBlockView без ZStack
        swipeBlockView
          .padding(.horizontal)
          .padding(.bottom, adaptive.spacing.xSmall)
      }
      
      // Статистика блокировки - показываем с анимацией
      if isBlocked && deviceActivityService.unlockDate != nil && (deviceActivityService.unlockDate ?? Date()) > Date() {
        HStack(alignment: .top, spacing: adaptive.spacing.small) {
          savedBlockedView
          
          appsBlockedView
        }
        .padding(.horizontal)
        .padding(.bottom)
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity))
      }
    }
    .animation(.easeInOut(duration: 0.3), value: isBlocked)
  }
  
  private var savedBlockedView: some View {
    VStack(alignment: .leading, spacing: adaptive.spacing.xSmall) {
      Text(currentSessionSavedTime)
        .adaptiveFont(\.title3)
        .fontWeight(.bold)
        .fontDesign(.monospaced)
        .foregroundStyle(Color.as_white)
      
      Text("saved")
        .adaptiveFont(\.callout)
        .foregroundStyle(Color.as_gray_light)
    }
    .adaptivePadding(\.medium)
    .frame(height: 100)
    .blurBackground(cornerRadius: 20)
  }
  
  private var appsBlockedView: some View {
    VStack(spacing: adaptive.spacing.small) {
      HStack {
        AppTokensView(
          tokens: deviceActivityService.selectionToDiscourage.applicationTokens,
          showCount: false
        )
        CategoryTokensView(
          tokens: deviceActivityService.selectionToDiscourage.categoryTokens,
          showCount: false
        )
        Spacer()
      }
      
      HStack {
        Text("\(deviceActivityService.selectionToDiscourage.applicationTokens.count)")
          .foregroundColor(Color.as_white_light)
          .adaptiveFont(\.callout)
        
        Text("apps and")
          .foregroundStyle(Color.as_gray_light)
          .adaptiveFont(\.callout)
        
        Text("\(deviceActivityService.selectionToDiscourage.categoryTokens.count)")
          .foregroundColor(Color.as_white_light)
          .adaptiveFont(\.callout)
        
        Text("categories")
          .foregroundStyle(Color.as_gray_light)
          .adaptiveFont(\.callout)
        Spacer()
      }
    }
    .adaptivePadding(\.medium)
    .frame(height: 100)
    .frame(maxWidth: .infinity)
    .blurBackground(cornerRadius: 20)
  }
  
  private var timeRemainingView: some View {
    HStack {
      Spacer()
      VStack(alignment: .center, spacing: adaptive.spacing.xSmall) {
        Text("Time Remaining Until Unlock")
          .foregroundStyle(Color.as_white_light)
          .adaptiveFont(\.body)
          .fontWeight(.semibold)
        
        Text(timeRemainingString)
          .font(.system(size: AdaptiveValues.isCompactDevice ? 44 : 56, weight: .bold, design: .monospaced))
          .foregroundColor(.white)
      }
      Spacer()
    }
    .adaptivePadding(\.medium)
  }
  
  private var headerView: some View {
    HStack {
      Image(.icNavAppBlock)
        .resizable()
        .adaptiveFrame(width: \.iconLarge, height: \.iconLarge)
        .foregroundColor(.white)
      
      Text("App Blocking")
        .foregroundColor(.white)
        .adaptiveFont(\.title2)
        .fontWeight(.semibold)
      
      Spacer()
    }
  }
  
  private var durationSection: some View {
    VStack {
      HStack {
        Text("Duration")
          .foregroundStyle(Color.white)
        Spacer()
      }
      
      TimePickerView(value1: $hours, value2: $minutes)
        .onChange(of: hours) { _, newValue in
          SharedData.userDefaults?.set(newValue, forKey: SharedData.AppBlocking.savedDurationHours)
        }
        .onChange(of: minutes) { _, newValue in
          SharedData.userDefaults?.set(newValue, forKey: SharedData.AppBlocking.savedDurationMinutes)
        }
    }
  }
  
  private var whatToBlockView: some View {
    VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
      Text("What to Block")
        .foregroundColor(.white)
        .adaptiveFont(\.body)
      
      Button(action: {
        isDiscouragedPresented = true
      }) {
        VStack(alignment: .leading, spacing: adaptive.spacing.xSmall) {
          
          // Основной блок — Select Apps (всегда отображается)
          HStack(spacing: adaptive.spacing.small) {
            Text("Apps")
              .foregroundColor(.white)
              .adaptiveFont(\.subheadline)
            
            Spacer()
            
            AppTokensView(
              tokens: deviceActivityService.selectionToDiscourage.applicationTokens,
              spacing: adaptive.spacing.xxSmall
            )
            
            Image(systemName: "chevron.right")
              .foregroundColor(Color.as_white_light)
          }
          
          // Показываем категории, только если они выбраны
          if !deviceActivityService.selectionToDiscourage.categoryTokens.isEmpty {
            HStack(spacing: adaptive.spacing.small) {
              Text("Categories")
                .foregroundColor(.white)
                .adaptiveFont(\.subheadline)
              
              Spacer()
              
              CategoryTokensView(
                tokens: deviceActivityService.selectionToDiscourage.categoryTokens,
                spacing: adaptive.spacing.xxSmall
              )
              
              Image(systemName: "chevron.right")
                .foregroundColor(Color.as_white_light)
            }
          }
        }
        .padding(.horizontal, adaptive.spacing.medium)
        .padding(.vertical, adaptive.spacing.small)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 30))
      }
      .familyActivityPicker(
        isPresented: $isDiscouragedPresented,
        selection: $deviceActivityService.selectionToDiscourage
      )
      .onChange(of: deviceActivityService.selectionToDiscourage) { _, newValue in
        // Save selection when changed
        deviceActivityService.saveFamilyActivitySelection(newValue)
      }
    }
  }
  
  private var strictBlockView: some View {
    VStack(alignment: .leading, spacing: adaptive.spacing.medium) {
      Toggle("Strict Block", isOn: Binding(
        get: { isStrictBlock },
        set: { newValue in
          HapticManager.shared.impact(style: .medium)
          if newValue && !isStrictBlock {
            // Show confirmation dialog when enabling
            showStrictBlockDialog = true
          } else if !newValue {
            // Allow disabling without confirmation
            isStrictBlock = false
            SharedData.userDefaults?.set(false, forKey: SharedData.Widget.isStricted)
          }
        }
      ))
      .foregroundStyle(Color.white)
      .toggleStyle(SwitchToggleStyle(tint: .purple))
    }
  }
  
  private var swipeBlockView: some View {
    SlideToTurnOnView(isBlocked: $isBlocked,
                      isStrictBlock: $isStrictBlock,
                      isLimitReached: !subscriptionManager.canStartNewBlock(),
                      onBlockingStateChanged: { newState in
      if newState {
        // Check subscription limits first
        if !subscriptionManager.canStartNewBlock() {
          // This shouldn't happen as button is disabled, but just in case
          return
        }
        
        // Increment block usage
        subscriptionManager.incrementBlockUsage()
        
        restrictionModel.isStricted = isStrictBlock
        
        // Timestamp теперь устанавливается в BlockingNotificationService.startBlocking
        
        BlockingNotificationService.shared.startBlocking(
          hours: hours,
          minutes: minutes,
          selection: deviceActivityService.selectionToDiscourage,
          restrictionModel: restrictionModel
        )
        // Start timer after blocking animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Timer.animationDelay) {
          // Проверяем что таймер еще не подключен
          if timerConnection == nil {
            // Сразу обновляем отображение
            timeBlockedString = Constants.TimeFormat.initialBlocked
            timeRemainingString = deviceActivityService.timeRemainingString
            startTimer()
          }
        }
      } else {
        // Сначала отключаем таймер
        stopTimer()
        
        // Очищаем timestamp при ручном выключении
        SharedData.userDefaults?.removeObject(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp)
        AppLogger.trace("Cleared timestamp on manual disable")
        
        BlockingNotificationService.shared.stopBlocking(selection: deviceActivityService.selectionToDiscourage)
        // Don't reset hours and minutes - keep last used values
      }
    },
                      onPurchaseTap: {
      showPaywall = true
    })
    .disabled(isBlockButtonDisabled)
  }
  
  private var isBlockButtonDisabled: Bool {
    if isBlocked == true { return false }
    
    return (hours == 0 && minutes == 0) ||
    (deviceActivityService.selectionToDiscourage.applicationTokens.isEmpty &&
     deviceActivityService.selectionToDiscourage.categoryTokens.isEmpty &&
     deviceActivityService.selectionToDiscourage.webDomainTokens.isEmpty)
  }
  
  private var separatorView: some View {
    SeparatorView()
  }
  
  func getEndTime(hourDuration: Int, minuteDuration: Int) -> (Int, Int) {
    let now = Date()
    let calendar = Calendar.current
    // Прибавляем к текущему времени общее количество минут
    if let endDate = calendar.date(byAdding: .minute, value: hourDuration * 60 + minuteDuration, to: now) {
      let comps = calendar.dateComponents([.hour, .minute], from: endDate)
      return (comps.hour ?? 0, comps.minute ?? 0)
    }
    // Если что-то пошло не так — fallback
    return (0, 0)
  }
  
  // MARK: - Time Formatting Methods
  private func formatRemainingTime(_ timeInterval: TimeInterval) -> String {
    let remaining = Int(timeInterval)
    
    guard remaining > 0 else {
      return Constants.TimeFormat.initialRemaining
    }
    
    let hours = remaining / Constants.TimeCalculation.secondsInHour
    let minutes = (remaining % Constants.TimeCalculation.secondsInHour) / Constants.TimeCalculation.secondsInMinute
    let seconds = remaining % Constants.TimeCalculation.secondsInMinute
    
    return String(format: Constants.TimeFormat.remainingFormat, hours, minutes, seconds)
  }
  
  private func formatBlockedTime(from timestamp: TimeInterval) -> String {
    let elapsed = Date().timeIntervalSince1970 - timestamp
    
    // Валидация: если elapsed > 24 часов, что-то пошло не так
    guard elapsed >= 0 && elapsed < TimeInterval(Constants.TimeCalculation.secondsInDay) else {
      AppLogger.alert("Invalid elapsed time: \(elapsed) seconds from timestamp: \(timestamp)")
      return Constants.TimeFormat.initialBlocked
    }
    
    let hours = Int(elapsed) / Constants.TimeCalculation.secondsInHour
    let minutes = (Int(elapsed) % Constants.TimeCalculation.secondsInHour) / Constants.TimeCalculation.secondsInMinute
    
    AppLogger.trace("Blocked time: \(hours)h \(minutes)m (elapsed: \(elapsed)s)")
    return String(format: Constants.TimeFormat.blockedFormat, hours, minutes)
  }
  
  private func calculateBlockedTime() -> String {
    guard let startTimestamp = SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp) else {
      return Constants.TimeFormat.initialBlocked
    }
    
    return formatBlockedTime(from: startTimestamp)
  }
  
  // Загрузить общее время за сегодня
  private func loadTotalSavedTime() {
    totalSavedTime = SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.todayTotalBlockingTime) ?? 0
  }
  
  // Форматировать общее время включая текущую сессию
  private func formatTotalSavedTime() -> String {
    var total = totalSavedTime
    
    // Добавляем время текущей сессии если блокировка активна
    if isBlocked, let startTimestamp = SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp) {
      let currentSessionTime = Date().timeIntervalSince1970 - startTimestamp
      total += currentSessionTime
    }
    
    let hours = Int(total) / Constants.TimeCalculation.secondsInHour
    let minutes = (Int(total) % Constants.TimeCalculation.secondsInHour) / Constants.TimeCalculation.secondsInMinute
    
    return String(format: Constants.TimeFormat.blockedFormat, hours, minutes)
  }
  
  // Форматировать только текущую сессию блокировки
  private func formatSavedTime() -> String {
    guard isBlocked,
          let startTimestamp = SharedData.userDefaults?.double(forKey: SharedData.AppBlocking.currentBlockingStartTimestamp) else {
      return Constants.TimeFormat.initialBlocked
    }
    
    let currentSessionTime = Date().timeIntervalSince1970 - startTimestamp
    let hours = Int(currentSessionTime) / Constants.TimeCalculation.secondsInHour
    let minutes = (Int(currentSessionTime) % Constants.TimeCalculation.secondsInHour) / Constants.TimeCalculation.secondsInMinute
    
    return String(format: Constants.TimeFormat.blockedFormat, hours, minutes)
  }
  
  // MARK: - Timer Management Methods
  private func startTimer() {
    // Останавливаем предыдущий таймер если есть
    stopTimer()
    
    // Создаем новый Timer.TimerPublisher каждый раз
    let newTimer = Timer.publish(every: Constants.Timer.updateInterval, on: .main, in: .common)
    currentTimer = newTimer
    timerConnection = newTimer.connect()
    timerID = UUID() // Обновляем ID для отладки
    
    AppLogger.trace("Timer started with ID: \(timerID)")
  }
  
  private func stopTimer() {
    timerConnection?.cancel()
    timerConnection = nil
    currentTimer = nil
    
    AppLogger.trace("Timer stopped for ID: \(timerID)")
  }
  
  
}
