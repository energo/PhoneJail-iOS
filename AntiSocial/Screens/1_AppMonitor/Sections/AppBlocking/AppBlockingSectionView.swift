//
//  AppBlockingSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

import SwiftUI
import WidgetKit

struct AppBlockingSectionView: View {
  @EnvironmentObject var model: MyModel
  @ObservedObject var restrictionModel: MyRestrictionModel
  
  @Binding var hours: Int
  @Binding var minutes: Int
  
  @Binding var categories: [AppCategory]
  @Binding var isStrictBlock: Bool
  
  @State private var isUnlocked: Bool = false
  @State private var noCategoriesAlert = false
  @State private var maxCategoriesAlert = false
  
  @State private var isDiscouragedPresented = false
  @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
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
      strictBlockView
      separatorView
      swipeBlockView
        .padding(.bottom, 8)
      
      //      Button(action: startBlocking) {
      //        Text("Start Blocking")
      //          .bold()
      //          .frame(maxWidth: .infinity)
      //          .padding()
      //          .background(isUnlocked ? Color.blue : Color.gray.opacity(0.5))
      //          .foregroundColor(.white)
      //          .cornerRadius(16)
      //      }
      //      .disabled(!isUnlocked)
      //      .alert("No categories selected", isPresented: $noCategoriesAlert) {
      //        Button("OK", role: .cancel) { }
      //      }
      //      .alert("Too many categories selected", isPresented: $maxCategoriesAlert) {
      //        Button("OK", role: .cancel) { }
      //      }
    }
    .padding()
    .background(bgBlur)
    .onChange(of: isUnlocked) { newValue in
      if newValue {
        startBlocking()
      } else {
        stopBlocking()
      }
    }
    .onAppear {
      // Восстанавливаем isUnlocked из UserDefaults
      let inRestriction = UserDefaults.standard.bool(forKey: "inRestrictionMode")
      isUnlocked = inRestriction
    }
    .alert("No categories selected", isPresented: $noCategoriesAlert) {
      Button("OK", role: .cancel) { }
    }
    .alert("Too many categories selected", isPresented: $maxCategoriesAlert) {
      Button("OK", role: .cancel) { }
    }
  }
  
  private var timeRemainingView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Time Remaining Until Unlock")
        .foregroundStyle(Color.white)
        .font(.headline)
      Text(model.timeRemainingString)
        .font(.system(size: 32, weight: .bold, design: .monospaced))
        .foregroundColor(.yellow)
    }
    .padding()
    .onReceive(timer) { _ in
      // Просто триггерим обновление вью
      _ = model.timeRemainingString
    }
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
            || model.selectionToDiscourage.categoryTokens.count > 0 ) {
          HStack(spacing: 8) {
            // Категории
            ForEach(Array(model.selectionToDiscourage.categoryTokens), id: \.self) { category in
              VStack {
                Label(category)
                  .labelStyle(.iconOnly)
                  .shadow(radius: 2)
                  .scaleEffect(3)
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
              .background( Color.gray.opacity(0.2))
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
  
  //  private var whatToBlockView: some View {
  //    VStack(alignment: .leading, spacing: 16) {
  //      Text("What to Block")
  //        .foregroundStyle(Color.white)
  //
  //      HStack(spacing: 8) {
  //        ForEach(AppCategory.allCases, id: \.self) { category in
  ////          Button(action: { toggleCategory(category) }) {
  //            Text(category.title)
  //                .padding(.horizontal, 12)
  //                .padding(.vertical, 6)
  //                .background(categories.contains(category) ? Color.white.opacity(0.85) : Color.gray.opacity(0.2))
  //                .cornerRadius(30)
  //                .foregroundColor(.black)
  //                .font(.system(size: 15, weight: .light))
  ////          }
  //        }
  //      }
  //      .onTapGesture {
  //        isDiscouragedPresented = true
  //      }
  //      .sheet(isPresented: $isDiscouragedPresented) {
  //          FamilyPickerView(model: model, isDiscouragedPresented: $isDiscouragedPresented)
  //      }
  //    }
  //  }
  
  private var strictBlockView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Toggle("Strict Block", isOn: $isStrictBlock)
        .foregroundStyle(Color.white)
    }
  }
  
  private var swipeBlockView: some View {
    SlideToTurnOnView(isUnlocked: $isUnlocked)
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
    // Проверка выбранных категорий (аналогично RestrictionView с приложениями)
    if categories.isEmpty {
      noCategoriesAlert = true
      maxCategoriesAlert = false
      return
    } else if categories.count > 20 {
      noCategoriesAlert = false
      maxCategoriesAlert = true
      return
    } else {
      noCategoriesAlert = false
      maxCategoriesAlert = false
    }
    
    // Сохраняем режим блокировки
    UserDefaults.standard.set(true, forKey: "inRestrictionMode")
    UserDefaults(suiteName:"group.ChristianPichardo.ScreenBreak")?.set(true, forKey:"widgetInRestrictionMode")
    
    // Сохраняем выбранные категории в MyModel (или как вам нужно)
    model.savedSelection = categories.map { AppEntity(name: $0.title) }
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
    
    // Устанавливаем unlockDate для восстановления после перезапуска
    model.setUnlockDate(hour: endHour, minute: endMins)
    
    UserDefaults.standard.set(endHour, forKey: "endHour")
    UserDefaults.standard.set(endMins, forKey: "endMins")
    UserDefaults(suiteName:"group.ChristianPichardo.ScreenBreak")?.set(endHour, forKey:"widgetEndHour")
    UserDefaults(suiteName:"group.ChristianPichardo.ScreenBreak")?.set(endMins, forKey:"widgetEndMins")
    
    WidgetCenter.shared.reloadAllTimelines()
    
    // Запуск блокировки (аналогично RestrictionView)
    MySchedule.setSchedule(endHour: endHour, endMins: endMins)
  }
  
  private func stopBlocking() {
    // Сбросить все настройки блокировки
    UserDefaults.standard.set(false, forKey: "inRestrictionMode")
    UserDefaults(suiteName:"group.ChristianPichardo.ScreenBreak")?.set(false, forKey:"widgetInRestrictionMode")
    
    // Можно очистить savedSelection, если нужно
    model.savedSelection.removeAll()
    
    // Сбросить время окончания
    UserDefaults.standard.removeObject(forKey: "endHour")
    UserDefaults.standard.removeObject(forKey: "endMins")
    UserDefaults(suiteName:"group.ChristianPichardo.ScreenBreak")?.removeObject(forKey:"widgetEndHour")
    UserDefaults(suiteName:"group.ChristianPichardo.ScreenBreak")?.removeObject(forKey:"widgetEndMins")
    
    WidgetCenter.shared.reloadAllTimelines()
    
    // Если есть метод для остановки DeviceActivityCenter — вызови его:
    // Например:
    // MySchedule.stopSchedule()
  }
  
  func getEndTime(hourDuration: Int, minuteDuration: Int) -> (Int, Int) {
      let now = Date()
      let calendar = Calendar.current
      // Прибавляем к текущему времени общее количество минут
      if let endDate = calendar.date(byAdding: .minute, value: hourDuration * 60 + minuteDuration, to: now) {
          let comps = calendar.dateComponents([.hour, .minute], from: endDate)
          return (comps.hour ?? 23, comps.minute ?? 59)
      }
      // Если что-то пошло не так — fallback
      return (23, 59)
  }

//  private func getEndTime(hourDuration: Int, minuteDuration: Int) -> (Int, Int) {
//    let now = Date()
//    let calendar = Calendar.current
//    var endHour = calendar.component(.hour, from: now) + hourDuration
//    var endMins = calendar.component(.minute, from: now) + minuteDuration
//    
//    if endMins >= 60 {
//      endMins -= 60
//      endHour += 1
//    }
//    if endHour > 23 {
//      endHour = 23
//      endMins = 59
//    }
//    return (endHour, endMins)
//  }
}

//struct AppBlockingSectionView: View {
//  @Binding var hours: Int
//  @Binding var minutes: Int
//
//  @Binding var categories: [AppCategory]
//  @Binding var isStrictBlock: Bool
//
//  @State var isUnlocked: Bool = false
//
//  var onBlock: () -> Void
//
//  var body: some View {
//    VStack(alignment: .leading, spacing: 16) {
//      headerVeiw
//      separatorView
//      durationSection
//      separatorView
//      whatToBlockView
//      separatorView
//      stricktBlockView
//      separatorView
//      swipeBlockView
//        .padding(.bottom, 8)
//    }
//    .padding()
//    .background(bgBlur)
//  }
//
//  private var swipeBlockView: some View {
//    SlideToTurnOnView(isUnlocked: $isUnlocked)
//  }
//
//  private var stricktBlockView: some View {
//    VStack(alignment: .leading, spacing: 16) {
//      Toggle("Strict Block", isOn: $isStrictBlock)
//        .foregroundStyle(Color.white)
//    }
//  }
//
//  private var whatToBlockView: some View {
//    VStack(alignment: .leading, spacing: 16) {
//
//      Text("What to Block")
//        .foregroundStyle(Color.white)
//
//      HStack(spacing: 8) {
//        ForEach(AppCategory.allCases, id: \.self) { category in
//          Button(action: { toggleCategory(category) }) {
//            Text(category.title)
//              .padding(.horizontal, 12)
//              .padding(.vertical, 6)
//              .background(categories.contains(category) ? Color.white.opacity(0.85) : Color.gray.opacity(0.2))
//              .cornerRadius(30)
//              .foregroundColor(.black)
//              .font(.system(size: 15, weight: .light))
//          }
//        }
//      }
//    }
//  }
//
//  private var headerVeiw: some View {
//    Text("App Blocking")
//      .font(.headline)
//      .foregroundStyle(Color.white)
//  }
//
//  private var durationSection: some View {
//    VStack {
//      HStack {
//        Text("Duration")
//          .foregroundStyle(Color.white)
//        Spacer()
//      }
//
//      TimePickerView()
//    }
//  }
//
//  private var separatorView: some View {
//    Rectangle()
//      .fill(Color(hex: "D9D9D9").opacity(0.13))
//      .frame(height: 0.5)
//  }
//
//  private var bgBlur: some View {
//    ZStack {
//      BackdropBlurView(isBlack: false, radius: 10)
//      RoundedRectangle(cornerRadius: 32)
//        .fill(
//          Color.white.opacity(0.07)
//        )
//    }
//  }
//
//  private func toggleCategory(_ category: AppCategory) {
//    if let idx = categories.firstIndex(of: category) {
//      categories.remove(at: idx)
//    } else {
//      categories.append(category)
//    }
//  }
//}
