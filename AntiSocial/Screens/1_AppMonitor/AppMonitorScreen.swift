//
//  AppMonitorScreen.swift
//  ScreenTimeTestApp
//
//  Created by D C on 11.02.2025.
//

import SwiftUI
import ScreenTime
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import DeviceActivity
import RevenueCatUI
import RevenueCat

struct AppMonitorScreen: View {
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @EnvironmentObject var familyControlsManager: FamilyControlsManager
  @StateObject private var restrictionModel = MyRestrictionModel()
  @Environment(\.scenePhase) var scenePhase
  
  @StateObject var vmScreenInteraption = AppInterruptionViewModel()
  @StateObject var vmScreenAlert = ScreenTimeAlertViewModel()

  @State private var isShowingProfile: Bool = false
  @State private var offsetY: CGFloat = .zero
  @State private var headerHeight: CGFloat = UIScreen.main.bounds.height * 0.35
  
  @State private var screenTimeID = UUID() // используется как .id
  @State private var lastRefreshDate = Date()
  
  // Navigation state
  @State private var currentSection = 0
  @State private var scrollOffset: CGFloat = 0
  @State private var isDragging = false
  
  // Добавляем состояние для отслеживания позиций секций
  @State private var sectionPositions: [CGFloat] = [0, 0, 0]
  
  var body: some View {
    BGView(imageRsc: .bgMain) {
      GeometryReader { screenGeometry in
        ZStack(alignment: .top) {
          
          //          Color.clear
          
          ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: false) {
              VStack(spacing: 0) {
                // Spacer-заполнитель под header
                Color.clear
                  .frame(height: headerHeight)
                  .overlay() {
                    headerOverlayView(screenGeometry: screenGeometry)
                  }
                  .id("header") // Добавляем id для header
                
                VStack(spacing: 0) {
                  // App Blocking Section
                  VStack {
                    appBlockingSection
                    Spacer(minLength: 0)
                  }
                  .frame(minHeight: screenGeometry.size.height - headerHeight - 20)
                  .padding(.horizontal, 20)
                  .padding(.top, 20)
                  .id(0)
                  .background(
                    GeometryReader { proxy in
                      Color.clear
                        .onAppear {
                          updateSectionPosition(0, position: proxy.frame(in: .global).minY)
                        }
                        .onChange(of: proxy.frame(in: .global).minY) { newValue in
                          updateSectionPosition(0, position: newValue)
                        }
                    }
                  )
                  
                  // Stats Section
                  VStack {
                    Spacer()
                      .frame(height: headerHeight + 20) // Header height + padding
                    statsSection
                    Spacer(minLength: 0)
                  }
                  .frame(minHeight: screenGeometry.size.height)
                  .padding(.horizontal, 20)
                  .id(1)
                  .background(
                    GeometryReader { proxy in
                      Color.clear
                        .onAppear {
                          updateSectionPosition(1, position: proxy.frame(in: .global).minY)
                        }
                        .onChange(of: proxy.frame(in: .global).minY) { newValue in
                          updateSectionPosition(1, position: newValue)
                        }
                    }
                  )
                  
                  // Focus Breaks Section
                  VStack {
                    Spacer()
                      .frame(height: headerHeight + 20) // Header height + padding
                    focusBreaksSection
                    Spacer(minLength: 0)
                  }
                  .frame(minHeight: screenGeometry.size.height)
                  .padding(.horizontal, 20)
                  .id(2)
                  .background(
                    GeometryReader { proxy in
                      Color.clear
                        .onAppear {
                          updateSectionPosition(2, position: proxy.frame(in: .global).minY)
                        }
                        .onChange(of: proxy.frame(in: .global).minY) { newValue in
                          updateSectionPosition(2, position: newValue)
                        }
                    }
                  )
                }
              }
              .background(
                GeometryReader { proxy in
                  Color.clear
                    .onAppear {
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        offsetY = screenGeometry.safeAreaInsets.top
                      }
                    }
                    .onChange(of: proxy.frame(in: .global).minY) { newValue in
                      offsetY = newValue
                    }
                  
                }
              )
              //            .padding(.horizontal, 20)
            }
            .refreshable {
              refreshScreenTime()
            }
            .onChange(of: currentSection) { newSection in
              scrollToSection(newSection, scrollProxy: scrollProxy, screenGeometry: screenGeometry)
            }
            .simultaneousGesture(
              DragGesture()
                .onEnded { value in
                  let threshold: CGFloat = 50 // minimum swipe distance
                  
                  if value.translation.height < -threshold && currentSection < 2 {
                    // Swipe up - next section
                    currentSection += 1
                  } else if value.translation.height > threshold && currentSection > 0 {
                    // Swipe down - previous section
                    currentSection -= 1
                  }
                }
            )
          }
          
          // Side Navigation on the right
          HStack {
            Spacer()
            VStack(spacing: 24) {
              Spacer()
              
              // Navigation buttons
              VStack(spacing: 20) {
                // App Blocking button
                Button(action: { 
                  currentSection = 0
                }) {
                  Image(systemName: "apps.iphone")
                    .font(.system(size: 24))
                    .foregroundColor(currentSection == 0 ? .white : .white.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(currentSection == 0 ? Color.white.opacity(0.2) : Color.clear)
                    )
                }
                
                // Stats button
                Button(action: { 
                  currentSection = 1
                }) {
                  Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundColor(currentSection == 1 ? .white : .white.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(currentSection == 1 ? Color.white.opacity(0.2) : Color.clear)
                    )
                }
                
                // Focus Breaks button
                Button(action: { 
                  currentSection = 2
                }) {
                  Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundColor(currentSection == 2 ? .white : .white.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(currentSection == 2 ? Color.white.opacity(0.2) : Color.clear)
                    )
                }
              }
              .padding(.vertical, 16)
              .padding(.horizontal, 8)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(.ultraThinMaterial)
              )
              
              Spacer()
            }
            .padding(.trailing, 16)
          }
          
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .fullScreenCover(isPresented: $isShowingProfile) {
      ProfileScreen()
    }
    .task {
      await AppBlockingLogger.shared.refreshAllData()
      await MainActor.run {
        familyControlsManager.requestAuthorization()
      }
    }
    .onChange(of: scenePhase) { newPhase in
      switch newPhase {
      case .active:
        // Check if enough time passed since last refresh (at least 5 seconds)
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshDate)
        if timeSinceLastRefresh > 5 {
          // Refresh screen time data when app becomes active
          refreshScreenTime()
          lastRefreshDate = Date()
        }
      case .inactive, .background:
        break
      @unknown default:
        break
      }
    }
    .presentPaywallIfNeeded(
      requiredEntitlementIdentifier: SubscriptionManager.Constants.entitlementID,
      purchaseCompleted: { _ in },
      restoreCompleted: { _ in
        Task {
          try? await subscriptionManager.restorePurchases()
        }
      }
    )
  }
  
  // MARK: - Header View (Floating)
  @ViewBuilder
  private func headerOverlayView(screenGeometry: GeometryProxy) -> some View {
    VStack(spacing: 8) {
      headerView
      screenTimeSection
    }
    .background(
      GeometryReader { proxy in
        Color.clear.onAppear {
          headerHeight = proxy.size.height
        }
      }
    )
    .offset(y: max(0, screenGeometry.safeAreaInsets.top - offsetY))
  }
  
  // MARK: - Header (Top-right profile)
  private var headerView: some View {
    HStack {
      Spacer()
      profileButton
    }
    .padding(.horizontal)
  }
  
  private var profileButton: some View {
    Button(action: { isShowingProfile = true }) {
      Image(systemName: "person.fill")
        .font(.system(size: 18))
        .foregroundStyle(Color.white)
        .padding()
        .contentShape(Rectangle())
    }
  }
  
  // MARK: - ScreenTime Today Section
  private var screenTimeSection: some View {
    ScreenTimeTodayView(id: screenTimeID)
  }
  
  private func refreshScreenTime() {
    screenTimeID = UUID()
  }
  
  // MARK: - App Blocking
  private var appBlockingSection: some View {
    VStack {
      AppBlockingSectionView(restrictionModel: restrictionModel)
    }
  }
  
  // MARK: - Focus Breaks Section
  private var focusBreaksSectionHeaderView: some View {
    HStack {
      Text("Focus Breaks")
        .foregroundColor(.white)
        .font(.system(size: 19, weight: .medium))
      Spacer()
    }
  }
  
  private var focusBreaksSection: some View {
    VStack {
      focusBreaksSectionHeaderView
        .padding(.top)
        .padding(.horizontal)
      
      separatorView.padding(.horizontal, 20)
      
      AppInterruptionsSectionView(viewModel: vmScreenInteraption)
      
      separatorView.padding(.horizontal, 20)
      
      ScreenTimeAlertsSectionView(viewModel: vmScreenAlert)
    }
    .blurBackground()
  }
  
  private var separatorView: some View {
    SeparatorView()
  }
  
  // MARK: - Stats Section
  private var statsSection: some View {
    ActivityReportView()
      .frame(maxWidth: .infinity)
      .frame(minHeight: 500)
      .frame(maxHeight: .infinity)
  }
  
  // MARK: - Navigation Helper
  private func scrollToSection(_ section: Int, scrollProxy: ScrollViewProxy, screenGeometry: GeometryProxy) {
    withAnimation(.easeInOut(duration: 0.6)) {
      switch section {
      case 0: // App Blocking - скроллим к позиции сразу после header
        // Используем специальный id для позиционирования после header
        scrollProxy.scrollTo("header", anchor: .bottom)
      case 1: // Stats - скроллим к секции с учетом header
        scrollProxy.scrollTo(1, anchor: .top)
      case 2: // Focus Breaks - скроллим к секции с учетом header
        scrollProxy.scrollTo(2, anchor: .top)
      default:
        break
      }
    }
  }
  
  // MARK: - Section Position Tracking
  private func updateSectionPosition(_ section: Int, position: CGFloat) {
    guard section >= 0 && section < sectionPositions.count else { return }
    sectionPositions[section] = position
  }
  
  private func getOptimalScrollPosition(for section: Int, in screenGeometry: GeometryProxy) -> CGFloat {
    let headerOffset = headerHeight + screenGeometry.safeAreaInsets.top
    
    switch section {
    case 0: // App Blocking - учитываем header
      return headerOffset + 20 // +20 для padding
    case 1: // Stats - стандартная позиция
      return headerOffset + 20
    case 2: // Focus Breaks - стандартная позиция
      return headerOffset + 20
    default:
      return headerOffset + 20
    }
  }
}

#Preview {
  AppMonitorScreen()
}
