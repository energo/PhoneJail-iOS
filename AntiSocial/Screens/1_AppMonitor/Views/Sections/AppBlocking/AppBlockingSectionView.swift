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
  @EnvironmentObject var model: DeviceActivityService
  @ObservedObject var restrictionModel: MyRestrictionModel
  
  @State var hours: Int = 0
  @State var minutes: Int = 0
  
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
      
      swipeBlockView
        .padding(.bottom, 8)
    }
    .padding()
    .blurBackground()
    .onChangeWithOldValue(of: isBlocked) { oldValue, newValue in
      if newValue {
        BlockingNotificationService.shared.startBlocking(
          hours: hours,
          minutes: minutes,
          selection: model.selectionToDiscourage,
          restrictionModel: restrictionModel
        )
      } else {
        BlockingNotificationService.shared.stopBlocking(selection: model.selectionToDiscourage)
        hours = 0
        minutes = 0
        BlockingNotificationService.shared.resetBlockingState()
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
        BlockingNotificationService.shared.resetBlockingState()
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
