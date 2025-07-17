//
//  AppInterruptionsSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct AppInterruptionsSectionView: View {
  @StateObject var viewModel: AppMonitorViewModel
    
  init() {
    self._viewModel = StateObject(wrappedValue: AppMonitorViewModel(model: SelectAppsModel()))
  }
  
  var body: some View {
    contentView
      .task {
        await viewModel.onAppear()
      }
      .onChangeWithOldValue(of: viewModel.model.activitySelection, perform: { _, _ in
        viewModel.onActivitySelectionChange()
      })
  }
  
  private var contentView: some View {
    VStack {
      whatToMonitorView
    }
    .padding()
    .blurBackground()
  }
  
  private var whatToMonitorView: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("App interruptions")
          .foregroundColor(.white)
          .font(.headline)
        
        Spacer()
        
        startMonitorButton
      }
      
      Button(action: {
        viewModel.showSelectApps()
      }) {
        VStack(alignment: .leading, spacing: 8) {
          
          // Основной блок — Select Apps (всегда отображается)
          HStack(spacing: 12) {
            Text("Apps")
              .foregroundColor(.white)
              .font(.system(size: 15, weight: .regular))
            
            Spacer()
            
            Text("\(viewModel.model.activitySelection.applicationTokens.count)")
              .foregroundColor(Color.as_white_light)
              .font(.system(size: 15, weight: .regular))
            
            stackedAppIcons
            
            Image(systemName: "chevron.right")
              .foregroundColor(Color.as_white_light)
          }
          
          // Показываем категории, только если они выбраны
          if !viewModel.model.activitySelection.categoryTokens.isEmpty {
            HStack(spacing: 12) {
              Text("Categories")
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .regular))
              
              Spacer()
              
              Text("\(viewModel.model.activitySelection.categoryTokens.count)")
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
        isPresented: $viewModel.pickerIsPresented,
        selection: $viewModel.model.activitySelection
      )
    }
  }
  
  private var stackedCategoryIcons: some View {
    let tokens = Array(viewModel.model.activitySelection.categoryTokens.prefix(4))
    
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
    let tokens = Array(viewModel.model.activitySelection.applicationTokens.prefix(4))
    
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
    
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 32)
        .fill(
          Color.white.opacity(0.07)
        )
    }
  }
  
  private var startMonitorButton: some View {
    Toggle("", isOn: $viewModel.isInterruptionsEnabled)
      .foregroundStyle(Color.white)
      .toggleStyle(SwitchToggleStyle(tint: .purple))
  }
  
//  private var monitoredAppsListView: some View {
//    VStack(alignment: .leading, spacing: 8) {
//      Text("Tracking apps")
//        .font(.headline)
//      
//      ForEach(0..<viewModel.monitoredApps.count, id: \.self) { index in
//        monitoredAppRow(app: viewModel.monitoredApps[index])
//      }
//      
//      Button("Add more apps") {
//        viewModel.showSelectApps()
//      }
//      .padding(.top, 8)
//    }
//    .padding()
//    .background(Color.gray.opacity(0.1))
//    .cornerRadius(10)
//  }
//  
//  private func monitoredAppRow(app: MonitoredApp) -> some View {
//    HStack {
//      Label(app.token)
//        .lineLimit(1)
//        .truncationMode(.tail)
//      
//      Spacer()
//      
//      Toggle("", isOn: Binding(
//        get: { app.isMonitored },
//        set: { _ in
//          viewModel.toggleAppMonitoring(app: app)
//        }
//      ))
//      .labelsHidden()
//    }
//    .padding(.vertical, 4)
//  }
}
