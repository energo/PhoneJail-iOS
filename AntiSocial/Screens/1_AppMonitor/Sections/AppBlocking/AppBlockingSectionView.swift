//
//  AppBlockingSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

import SwiftUI
import WidgetKit
import FamilyControls


struct AppBlockingSectionView: View {
  @EnvironmentObject var model: MyModel
  @ObservedObject var restrictionModel: MyRestrictionModel
  
  @State var hours: Int = 0
  @State var minutes: Int = 0
  
//  @Binding var categories: [AppCategory]
  @Binding var isStrictBlock: Bool
  
  @State private var isBlocked: Bool = false
  @State private var noCategoriesAlert = false
  @State private var maxCategoriesAlert = false
  @State private var isDiscouragedPresented = false
  @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  @State private var timeRemainingString: String = ""
  
  //MARK: - Views
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerView
      separatorView
      
      if model.unlockDate != nil && (model.unlockDate ?? Date()) > Date() {
        timeRemainingView
      } else {
        durationSection
      }
      
      separatorView
      
      whatToBlockView
      separatorView
      
      //      strictBlockView
      //      separatorView
      swipeBlockView
        .padding(.bottom, 8)
    }
    .padding()
    .background(bgBlur)
    .onChange(of: isBlocked) { newValue in
      if newValue {
        startBlocking()
      } else {
        stopBlocking()
        hours = 0
        minutes = 0
        resetBlockState()
      }
    }
    .onAppear {
      // Восстанавливаем isUnlocked из UserDefaults
      let inRestriction = UserDefaults.standard.bool(forKey: "inRestrictionMode")
      isBlocked = inRestriction
      timeRemainingString = model.timeRemainingString
      
      if let savedHour = UserDefaults.standard.value(forKey: "endHour") as? Int,
         let savedMin = UserDefaults.standard.value(forKey: "endMins") as? Int {
          restrictionModel.endHour = savedHour
          restrictionModel.endMins = savedMin
      }
      
      if !isBlocked {
        
        hours = restrictionModel.endHour
        minutes = restrictionModel.endMins
      }
    }
    .onReceive(timer) { _ in
      if let unlockDate = model.unlockDate, unlockDate > Date() {
        timeRemainingString = model.timeRemainingString
      } else {
        timeRemainingString = "00:00:00"
      }
      
      if let unlockDate = model.unlockDate, unlockDate <= Date() {
        resetBlockState()
      }
    }
    .alert("No categories selected", isPresented: $noCategoriesAlert) {
      Button("OK", role: .cancel) { }
    }
    .alert("Too many categories selected", isPresented: $maxCategoriesAlert) {
      Button("OK", role: .cancel) { }
    }
  }
  
  private var timeRemainingView: some View {
    HStack {
      Spacer()
      VStack(alignment: .center, spacing: 8) {
        Text("Time Remaining Until Unlock")
          .foregroundStyle(Color(hex: "CFD3E6"))
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
      .font(.headline)
      .foregroundStyle(Color.white)
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
        .foregroundStyle(Color.white)
      
      ScrollView(.horizontal, showsIndicators: false) {
        if (model.selectionToDiscourage.applicationTokens.count > 0
            || model.selectionToDiscourage.categoryTokens.count > 0) {
          HStack(spacing: 8) {
            // Категории
            ForEach(Array(model.selectionToDiscourage.categoryTokens), id: \.self) { category in
              VStack {
                Label(category)
                  .labelStyle(.iconOnly)
                  .shadow(radius: 2)
                  .frame(width: 24, height: 24)
              }
              .padding()
              .multilineTextAlignment(.center)
              
            }
            // Приложения
            ForEach(Array(model.selectionToDiscourage.applicationTokens), id: \.self) { app in
              VStack {
                Label(app)
                  .labelStyle(.iconOnly)
                  .shadow(radius: 2)
                  .scaleEffect(3)
                  .frame(width:50, height:50)
                
              }
              .padding()
              .multilineTextAlignment(.center)
              
              //                      Text(app.localizedDisplayName ?? "App")
              //                          .padding(.horizontal, 12)
              //                          .padding(.vertical, 6)
              //                          .background(Color.white.opacity(0.85))
              //                          .cornerRadius(30)
              //                          .foregroundColor(.black)
              //                          .font(.system(size: 15, weight: .light))
            }
          }
          .contentShape(Rectangle())
        } else {
          HStack {
            Text("Choose apps to block")
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background( Color.white)
              .cornerRadius(30)
              .foregroundColor(.black)
              .font(.system(size: 15, weight: .light))
          }
        }
      }
      .onTapGesture {
        isDiscouragedPresented = true
      }
      .sheet(isPresented: $isDiscouragedPresented) {
        FamilyPickerView(model: model, isDiscouragedPresented: $isDiscouragedPresented)
      }
    }
  }
  
  private var strictBlockView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Toggle("Strict Block", isOn: $isStrictBlock)
        .foregroundStyle(Color.white)
    }
  }
  
  private var swipeBlockView: some View {
    SlideToTurnOnView(isBlocked: $isBlocked)
      .disabled(isBlockButtonDisabled)
  }
  
  private var isBlockButtonDisabled: Bool {
    (hours == 0 && minutes == 0) ||
    (model.selectionToDiscourage.applicationTokens.isEmpty &&
     model.selectionToDiscourage.categoryTokens.isEmpty &&
     model.selectionToDiscourage.webDomainTokens.isEmpty)
  }
  
  private var separatorView: some View {
    Rectangle()
      .fill(Color(hex: "D9D9D9").opacity(0.13))
      .frame(height: 0.5)
  }
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 32)
        .fill(Color.white.opacity(0.07))
    }
  }
  
  private func toggleCategory(_ category: AppCategory) {
    //    if let idx = categories.firstIndex(of: category) {
    //      categories.remove(at: idx)
    //    } else {
    //      categories.append(category)
    //    }
  }
  
  private func startBlocking() {
    // Не запускать блокировку, если время не выбрано
    if hours == 0 && minutes == 0 {
      return
    }
    // Проверка выбранных категорий (аналогично RestrictionView с приложениями)
//    if categories.isEmpty {
//      noCategoriesAlert = true
//      maxCategoriesAlert = false
//      return
//    } else if categories.count > 20 {
//      noCategoriesAlert = false
//      maxCategoriesAlert = true
//      return
//    } else {
//      noCategoriesAlert = false
//      maxCategoriesAlert = false
//    }
    
    // Сохраняем режим блокировки
    UserDefaults.standard.set(true, forKey: "inRestrictionMode")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(true, forKey:"widgetInRestrictionMode")
    
    // Сохраняем выбранные категории в MyModel (или как вам нужно)
//    model.savedSelection = categories.map { AppEntity(name: $0.title) }
    // Сохраняем FamilyActivitySelection для восстановления после перезапуска
    model.saveFamilyActivitySelection(model.selectionToDiscourage)
    
    // Устанавливаем время старта/окончания
    let now = Date()
    let calendar = Calendar.current
    let curHour = calendar.component(.hour, from: now)
    let curMins = calendar.component(.minute, from: now)
    
    restrictionModel.startHour = curHour
    restrictionModel.startMin = curMins
    
    let (endHour, endMins) = getEndTime(hourDuration: hours, minuteDuration: minutes)
    restrictionModel.endHour = endHour
    restrictionModel.endMins = endMins
    
    // Устанавливаем unlockDate только если её нет или она в прошлом
    if model.unlockDate == nil || (model.unlockDate ?? Date()) <= Date() {
      model.setUnlockDate(hour: endHour, minute: endMins)
    }
    
    UserDefaults.standard.set(endHour, forKey: "endHour")
    UserDefaults.standard.set(endMins, forKey: "endMins")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(endHour, forKey:"widgetEndHour")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(endMins, forKey:"widgetEndMins")
    
    WidgetCenter.shared.reloadAllTimelines()
    
    // Запуск блокировки (аналогично RestrictionView)
    MySchedule.setSchedule(endHour: endHour, endMins: endMins)
    
    // После установки блокировки — сохраняем статистику по всем выбранным приложениям
    let today = Date()
    for app in model.selectionToDiscourage.applications {
      FocusedTimeStatsStore.shared.saveUsage(for: app.localizedDisplayName ?? "APP",
                                             date: today,
                                             duration: TimeInterval(hours * 3600 + minutes * 60))
    }
    // Сохраняем время старта блокировки как Double
    let startTime = Date()
    UserDefaults(suiteName: "group.ScreenTimeTestApp.sharedData")?.set(startTime.timeIntervalSince1970, forKey: "restrictionStartTime")
  }
  
  private func stopBlocking() {
    // Сбросить все настройки блокировки
    UserDefaults.standard.set(false, forKey: "inRestrictionMode")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(false, forKey:"widgetInRestrictionMode")
    
    // Можно очистить savedSelection, если нужно
    model.savedSelection.removeAll()
    
    // Сбросить время окончания
    UserDefaults.standard.removeObject(forKey: "endHour")
    UserDefaults.standard.removeObject(forKey: "endMins")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.removeObject(forKey:"widgetEndHour")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.removeObject(forKey:"widgetEndMins")
    
    WidgetCenter.shared.reloadAllTimelines()
    
    // Если есть метод для остановки DeviceActivityCenter — вызови его:
    // Например:
    // MySchedule.stopSchedule()
    // Получаем время старта блокировки как Double
    if let startTimestamp = UserDefaults(suiteName: "group.ScreenTimeTestApp.sharedData")?.object(forKey: "restrictionStartTime") as? Double {
      let startTime = Date(timeIntervalSince1970: startTimestamp)
      let endTime = Date()
      let duration = endTime.timeIntervalSince(startTime)
      let today = Date()
      for app in model.selectionToDiscourage.applications {
        FocusedTimeStatsStore.shared.saveUsage(for: app.localizedDisplayName ?? "App", date: today, duration: duration)
      }
      // Очищаем время старта
      UserDefaults(suiteName: "group.ScreenTimeTestApp.sharedData")?.removeObject(forKey: "restrictionStartTime")
    }
  }
  
  private func resetBlockState() {
    // Сбросить все выбранные приложения, категории, web-домены
    model.selectionToDiscourage = FamilyActivitySelection()
    model.savedSelection.removeAll()
    model.saveFamilyActivitySelection(model.selectionToDiscourage)
    model.unlockDate = nil
    UserDefaults.standard.set(false, forKey: "inRestrictionMode")
    UserDefaults(suiteName:"group.com.app.antisocial.sharedData")?.set(false, forKey:"widgetInRestrictionMode")
    isBlocked = false
    model.stopAppRestrictions()
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
