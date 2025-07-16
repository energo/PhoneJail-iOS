//
//  ScreenTimeAlertsSectionView.swift
//  AntiSocial
//
//  Created by D C on 26.06.2025.
//

import SwiftUI

struct ScreenTimeAlertsSectionView: View {
  @StateObject var viewModel: AppMonitorViewModel
  
  //  @Binding var notifyInterval: TimeInterval
  //  @Binding var isAlertEnabled: Bool
  
  let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]
  
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
      whatToBlockView
    }
    .padding()
    .blurBackground()
  }
  
  private var whatToBlockView: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Screen Time Alerts")
          .foregroundColor(.white)
          .font(.headline)
        
        Spacer()
        
        startMonitorButton
      }
      
      Button(action: {
        //        isDiscouragedPresented = true
        viewModel.showSelectApps()
      }) {
        VStack(alignment: .leading, spacing: 8) {
          
          // Основной блок — Select Apps (всегда отображается)
          HStack(spacing: 12) {
            Text("Apps")
              .foregroundColor(.white)
              .font(.system(size: 15, weight: .regular))
            
            Spacer()
            
            //            Text("\(deviceActivityService.selectionToDiscourage.applicationTokens.count)")
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
  
  //  var body: some View {
  //    VStack(alignment: .leading, spacing: 16) {
  //      Text("Screentime Alerts")
  //        .font(.headline)
  //        .foregroundStyle(Color.white)
  //
  //      HStack(spacing: 8) {
  //        ForEach(AlertCategory.allCases, id: \.self) { category in
  //          Button(action: { toggleCategory(category) }) {
  //            Text(category.title)
  //              .padding(.horizontal, 12)
  //              .padding(.vertical, 6)
  //              .background(selectedAlertCategories.contains(category) ? Color.white.opacity(0.85) : Color.gray.opacity(0.2))
  //              .cornerRadius(30)
  //              .foregroundColor(.black)
  //              .font(.system(size: 15, weight: .light))
  //          }
  //        }
  //      }
  //
  //      HStack {
  //        Text("Notify Me Every")
  //          .foregroundStyle(Color.white)
  //          .lineLimit(1)
  //          .layoutPriority(999)
  //        Picker("", selection: $notifyInterval) {
  //          ForEach([10, 20, 30, 60], id: \.self) { value in
  //            Text("\(value) Mins")
  //              .tag(TimeInterval(value * 60))
  //              .lineLimit(1)
  ////              .layoutPriority(999)
  //          }
  //        }
  //        .pickerStyle(.menu)
  //
  ////        Spacer()
  //
  //        Toggle(isOn: $isAlertEnabled) {
  //          EmptyView()
  //        }
  //        .toggleStyle(SwitchToggleStyle(tint: .purple))
  //
  //      }
  //    }
  //    .padding()
  //    .background(bgBlur)
  //  }
  
  private var bgBlur: some View {
    ZStack {
      BackdropBlurView(isBlack: false, radius: 10)
      RoundedRectangle(cornerRadius: 32)
        .fill(
          Color.white.opacity(0.07)
        )
    }
  }
  
  //MARK: -
  //MARK: - OLD Implementation (base functional for tracking use of app
  //  private var oldContentView: some View {
  //    VStack(spacing: 16) {
  ////      screenTimeSelectButton
  //
  //      if !viewModel.monitoredApps.isEmpty {
  //        monitoredAppsListView
  //      } else {
  //        quickSelectSocialMediaButton
  //      }
  //
  //      startMonitorButton
  //
  ////      selectedAppsView
  //
  //    }
  //    .padding()
  //  }
  
  
  //MARK: - Views
  //  private var screenTimeSelectButton: some View {
  //    Button {
  //      viewModel.showSelectApps()
  //    } label: {
  //      HStack {
  //        Text("Select Apps")
  //          .padding(32)
  //          .background(Color.white)
  //      }
  //    }
  //    .familyActivityPicker(
  //      isPresented: $viewModel.pickerIsPresented,
  //      selection: $viewModel.model.activitySelection
  //    )
  //  }
  
  //  private var quickSelectSocialMediaButton: some View {
  //    Button {
  //      viewModel.showPickerWithInstructions()
  //    } label: {
  //      HStack {
  //        Image(systemName: "person.2.fill")
  //          .font(.title2)
  //        Text("Choose Apps to block")
  //          .padding()
  //          .background(Color.blue.opacity(0.2))
  //          .cornerRadius(10)
  //      }
  //      .overlay(
  //        RoundedRectangle(cornerRadius: 10)
  //          .stroke(Color.blue, lineWidth: 1)
  //      )
  //    }
  //    .alert(isPresented: $viewModel.showSocialMediaHint) {
  //      Alert(
  //        title: Text("Hint"),
  //        message: Text("Please, chose apps to block"),
  //        dismissButton: .default(Text("OK"))
  //      )
  //    }
  //  }
  
  private var startMonitorButton: some View {
    Toggle("", isOn: $viewModel.isAlertEnabled)
      .foregroundStyle(Color.white)
      .toggleStyle(SwitchToggleStyle(tint: .purple))
  }
  
  private var monitoredAppsListView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Tracking apps")
        .font(.headline)
      
      ForEach(0..<viewModel.monitoredApps.count, id: \.self) { index in
        monitoredAppRow(app: viewModel.monitoredApps[index])
      }
      
      Button("Add more apps") {
        viewModel.showSelectApps()
      }
      .padding(.top, 8)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(10)
  }
  
  private func monitoredAppRow(app: MonitoredApp) -> some View {
    HStack {
      Label(app.token)
        .lineLimit(1)
        .truncationMode(.tail)
      
      Spacer()
      
      Toggle("", isOn: Binding(
        get: { app.isMonitored },
        set: { _ in
          viewModel.toggleAppMonitoring(app: app)
        }
      ))
      .labelsHidden()
    }
    .padding(.vertical, 4)
  }
}
