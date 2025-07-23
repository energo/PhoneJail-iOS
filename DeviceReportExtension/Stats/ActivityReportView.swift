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
        Text("Stats")
          .foregroundColor(.white)
          .font(.system(size: 19, weight: .medium))
        Spacer()
      }

      separatorView
        .padding(.horizontal, 20)
        .padding(.vertical, 16)

      datePicker
      
      // Сам отчёт
      DeviceActivityReport(context, filter: filter)
    }
    .padding()
    .background(bgBlur)
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
      
//      Text(selectedDate, style: .date)
      Text("TODAY, " + selectedDate.formatted(.dateTime.month(.wide).day()))
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
    }
    .foregroundStyle(Color.white)
//    .padding()
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

