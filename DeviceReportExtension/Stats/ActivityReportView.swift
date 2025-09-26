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
  @Binding var currentFilter: DeviceActivityFilter
  @Binding var isShowingAll: Bool 

  @State private var selectedDate: Date = Date()
  @State private var lastRefreshDate: Date? = nil
    
  private let adaptive = AdaptiveValues.current

  let context: DeviceActivityReport.Context = .statsActivity
    
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      // Сам отчёт с защитой от сбоев
      ZStack {
        // Всегда показываем placeholder чтобы view не исчезала
        Color.clear
          .frame(minHeight: 200)
        
        // Отчёт поверх placeholder
        DeviceActivityReport(context, filter: currentFilter)
      }
      .frame(minHeight: 200)
      showAllButton
    }
  }
  
  private var showAllButton: some View {
    Button(action: {
      isShowingAll = true
      print("Show All button tapped")
    }) {
      HStack {
        Spacer()
        Text("Show All")
          .adaptiveFont(\.body)
          .fontWeight(.semibold)
          .foregroundStyle(Color.white)
        Spacer()
      }
      .padding(.vertical, adaptive.spacing.small)
      .background(
        RoundedRectangle(cornerRadius: 9999)
          .stroke(Color.borderGradient, lineWidth: 1)
      )
      .frame(height: adaptive.componentSizes.buttonHeight)
    }
    .padding(.top, adaptive.spacing.xSmall)
  }
}

