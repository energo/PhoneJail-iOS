//
//  AppBlockingSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI
import WidgetKit
import FamilyControls
import Combine


struct AppBlockingSectionView: View {
  @EnvironmentObject var deviceActivityService: DeviceActivityService
  @ObservedObject var restrictionModel: MyRestrictionModel
  
  @State var hours: Int = 0
  @State var minutes: Int = 0
  
  @State private var isStrictBlock: Bool = false
  @State private var isBlocked: Bool = false
  
  @State private var noCategoriesAlert = false
  @State private var maxCategoriesAlert = false
  @State private var isDiscouragedPresented = false
  @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
  @State private var timerConnection: Cancellable?
  
  @State private var timeRemainingString: String = ""
  @State private var timeBlockedString: String = ""
  
  //MARK: - Views
  var body: some View {
    contentView
    .padding()
    .blurBackground()
    // Removed onChangeWithOldValue - logic moved to swipeBlockView
    .onAppear {
      // Восстанавливаем isUnlocked из UserDefaults
      isStrictBlock = SharedData.userDefaults?.bool(forKey: SharedData.Widget.isStricted) ?? false
      isBlocked = SharedData.userDefaults?.bool(forKey: SharedData.Widget.isBlocked) ?? false
      timeRemainingString = deviceActivityService.timeRemainingString
      timeBlockedString = deviceActivityService.timeBlockedString
      
      //TODO: - need to refactor (looks like odd properties)
      if let savedHour = SharedData.userDefaults?.integer(forKey: SharedData.Widget.endHour),
         let savedMin = SharedData.userDefaults?.integer(forKey: SharedData.Widget.endMinutes) {
        restrictionModel.endHour = savedHour
        restrictionModel.endMins = savedMin
      }
      
      if !isBlocked {
        hours = restrictionModel.endHour
        minutes = restrictionModel.endMins
      }
      
      // Start timer if already blocked
      if isBlocked && deviceActivityService.unlockDate != nil {
        timerConnection = timer.connect()
      }
    }
    .onReceive(timer) { _ in
      if timerConnection != nil && isBlocked {
        if let unlockDate = deviceActivityService.unlockDate {
          timeRemainingString = unlockDate > Date() ? deviceActivityService.timeRemainingString : "0:00:00"
          timeBlockedString = deviceActivityService.timeBlockedString

          if unlockDate <= Date() {
            isBlocked = false
            BlockingNotificationService.shared.stopBlocking(selection: deviceActivityService.selectionToDiscourage)
            timerConnection?.cancel()
            timerConnection = nil
          }
        }
      }
    }
    .onDisappear {
      timerConnection?.cancel()
    }
    .alert("No categories selected", isPresented: $noCategoriesAlert) {
      Button("OK", role: .cancel) { }
    }
    .alert("Too many categories selected", isPresented: $maxCategoriesAlert) {
      Button("OK", role: .cancel) { }
    }
  }
  
  //MARK: - Views
  private var contentView: some View {
    VStack(alignment: .leading, spacing: 16) {
      if isBlocked && deviceActivityService.unlockDate != nil && (deviceActivityService.unlockDate ?? Date()) > Date() {
        timeRemainingView
      } else {
        headerView
        separatorView

        durationSection
        separatorView
        
        whatToBlockView
        separatorView
        
        strictBlockView
        separatorView
      }
      
      swipeBlockView
        .padding(.bottom, 8)
      
      if isBlocked && deviceActivityService.unlockDate != nil && (deviceActivityService.unlockDate ?? Date()) > Date() {
        HStack(alignment: .top, spacing: 12) {
          savedBlockedView
            .frame(maxHeight: .infinity)

          appsBlockedView
            .frame(maxHeight: .infinity)
        }
        .frame(minHeight: 0, alignment: .top)
      }
    }
  }
  private var savedBlockedView: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(timeBlockedString)
        .font(.system(size: 20, weight: .bold, design: .monospaced))
        .foregroundStyle(Color.as_white)
      
      Text("saved")
        .font(.system(size: 14, weight: .regular))
        .foregroundStyle(Color.as_gray_light)
    }
    .padding(16)
    .frame(height: 100)
    .blurBackground(cornerRadius: 20)
  }
  
  private var appsBlockedView: some View {
    VStack(spacing: 12) {
      HStack {
        stackedAppIcons
        stackedCategoryIcons
        Spacer()
      }
      
      HStack {
        Text("\(deviceActivityService.selectionToDiscourage.applicationTokens.count)")
          .foregroundColor(Color.as_white_light)
          .font(.system(size: 14, weight: .regular))
        
        Text("apps and")
          .foregroundStyle(Color.as_gray_light)
          .font(.system(size: 14, weight: .regular))
        
        Text("\(deviceActivityService.selectionToDiscourage.categoryTokens.count)")
          .foregroundColor(Color.as_white_light)
          .font(.system(size: 14, weight: .regular))
        
        Text("categories")
          .foregroundStyle(Color.as_gray_light)
          .font(.system(size: 14, weight: .regular))
        Spacer()
      }
    }
    .padding(16)
    .frame(height: 100)
    .frame(maxWidth: .infinity)
    .blurBackground(cornerRadius: 20)
  }
  
  private var timeRemainingView: some View {
    HStack {
      Spacer()
      VStack(alignment: .center, spacing: 8) {
        Text("Time Remaining Until Unlock")
          .foregroundStyle(Color.as_white_light)
          .font(.system(size: 16, weight: .semibold))
        
        Text(timeRemainingString)
          .font(.system(size: 56, weight: .bold, design: .monospaced))
          .foregroundColor(.white)
      }
      Spacer()
    }
    .padding()
  }
  
  private var headerView: some View {
    Text("App Blocking")
      .foregroundColor(.white)
      .font(.system(size: 19, weight: .medium))
  }
  
  private var durationSection: some View {
    VStack {
      HStack {
        Text("Duration")
          .foregroundStyle(Color.white)
        Spacer()
      }
      
      TimePickerView(value1: $hours, value2: $minutes)
    }
  }
  
  private var whatToBlockView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("What to Block")
        .foregroundColor(.white)
        .font(.system(size: 16, weight: .regular))

      Button(action: {
        isDiscouragedPresented = true
      }) {
        VStack(alignment: .leading, spacing: 8) {
          
          // Основной блок — Select Apps (всегда отображается)
          HStack(spacing: 12) {
            Text("Apps")
              .foregroundColor(.white)
              .font(.system(size: 15, weight: .regular))
            
            Spacer()
            
            Text("\(deviceActivityService.selectionToDiscourage.applicationTokens.count)")
              .foregroundColor(Color.as_white_light)
              .font(.system(size: 15, weight: .regular))
            
            stackedAppIcons
            
            Image(systemName: "chevron.right")
              .foregroundColor(Color.as_white_light)
          }
          
          // Показываем категории, только если они выбраны
          if !deviceActivityService.selectionToDiscourage.categoryTokens.isEmpty {
            HStack(spacing: 12) {
              Text("Categories")
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .regular))
              
              Spacer()
              
              Text("\(deviceActivityService.selectionToDiscourage.categoryTokens.count)")
                .foregroundColor(Color.as_white_light)
                .font(.system(size: 15, weight: .regular))
              
              stackedCategoryIcons
              
              Image(systemName: "chevron.right")
                .foregroundColor(Color.as_white_light)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 30))
      }
      .familyActivityPicker(
        isPresented: $isDiscouragedPresented,
        selection: $deviceActivityService.selectionToDiscourage
      )
    }
  }
  
  private var stackedCategoryIcons: some View {
    let tokens = Array(deviceActivityService.selectionToDiscourage.categoryTokens.prefix(4))
    
    return ZStack {
      ForEach(tokens.indices, id: \.self) { index in
        let token = tokens[index]
        Label(token)
          .labelStyle(.iconOnly)
          .frame(width: 20, height: 20)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 6))
          .offset(x: CGFloat(-(tokens.count - 1 - index)) * 12)
          .zIndex(Double(index)) // правая поверх
      }
    }
    .frame(width: CGFloat(20 + (tokens.count - 1) * 12), height: 20)
  }
  
  private var stackedAppIcons: some View {
    let tokens = Array(deviceActivityService.selectionToDiscourage.applicationTokens.prefix(4))
    
    return ZStack {
      ForEach(tokens.indices, id: \.self) { index in
        let token = tokens[index]
        Label(token)
          .labelStyle(.iconOnly)
          .frame(width: 20, height: 20)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 6))
          .offset(x: CGFloat(-(tokens.count - 1 - index)) * 12)
          .zIndex(Double(index)) // правая поверх
      }
    }
    .frame(width: CGFloat(20 + (tokens.count - 1) * 12), height: 20)
  }
  
  private var strictBlockView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Toggle("Strict Block", isOn: $isStrictBlock)
        .foregroundStyle(Color.white)
        .toggleStyle(SwitchToggleStyle(tint: .purple))
    }
  }
  
  private var swipeBlockView: some View {
    SlideToTurnOnView(isBlocked: $isBlocked,
                      isStrictBlock: $isStrictBlock,
                      onBlockingStateChanged: { newState in
                        if newState {
                          BlockingNotificationService.shared.startBlocking(
                            hours: hours,
                            minutes: minutes,
                            selection: deviceActivityService.selectionToDiscourage,
                            restrictionModel: restrictionModel
                          )
                          // Start timer after blocking animation completes
                          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            timerConnection = timer.connect()
                          }
                        } else {
                          BlockingNotificationService.shared.stopBlocking(selection: deviceActivityService.selectionToDiscourage)
                          hours = 0
                          minutes = 0
                          timerConnection?.cancel()
                          timerConnection = nil
                        }
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
}
