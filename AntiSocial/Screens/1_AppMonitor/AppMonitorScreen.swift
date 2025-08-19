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
  // MARK: - Environment Objects
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @EnvironmentObject var familyControlsManager: FamilyControlsManager
  @Environment(\.scenePhase) var scenePhase
  
  // MARK: - View Models
  @StateObject private var restrictionModel = MyRestrictionModel()
  @StateObject var vmScreenInteraption = AppInterruptionViewModel()
  @StateObject var vmScreenAlert = ScreenTimeAlertViewModel()
  
  // MARK: - UI State
  @State private var isShowingProfile: Bool = false
  @State private var offsetY: CGFloat = .zero
  @State private var headerHeight: CGFloat = UIScreen.main.bounds.height * 0.35
  @State private var screenTimeID = UUID()
  @State private var lastRefreshDate = Date()
  
  // MARK: - Navigation State
  @State private var currentSection = 0
  @State private var scrollOffset: CGFloat = 0
  @State private var isDragging = false
  @State private var sectionPositions: [CGFloat] = [0, 0, 0]
  
  // MARK: - Constants
  private enum Constants {
    static let swipeThreshold: CGFloat = 50
    static let animationDuration: Double = 0.6
    static let headerPadding: CGFloat = 20
    static let horizontalPadding: CGFloat = 32
    static let sectionSpacing: CGFloat = 0
  }
  
  var body: some View {
    BGView(imageRsc: .bgMain) {
      GeometryReader { screenGeometry in
        ZStack(alignment: .top) {
          mainScrollView(screenGeometry: screenGeometry)
          sideNavigationPanel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .fullScreenCover(isPresented: $isShowingProfile) {
      ProfileScreen()
    }
    .task {
      await setupInitialData()
    }
    .onChangeWithOldValue(of: scenePhase) { _, newPhase in
      handleScenePhaseChange(newPhase)
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
}

// MARK: - Main Content Views
private extension AppMonitorScreen {
  
  func mainScrollView(screenGeometry: GeometryProxy) -> some View {
    ScrollViewReader { scrollProxy in
      ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: Constants.sectionSpacing) {
          headerSection(screenGeometry: screenGeometry)
          contentSections(screenGeometry: screenGeometry)
        }
        .background(scrollOffsetReader(screenGeometry: screenGeometry))
      }
      .refreshable {
        refreshScreenTime()
      }
      .onChangeWithOldValue(of: currentSection) { _, newSection in
        scrollToSection(newSection, scrollProxy: scrollProxy, screenGeometry: screenGeometry)
      }
      .simultaneousGesture(swipeGesture)
    }
  }
  
  func headerSection(screenGeometry: GeometryProxy) -> some View {
    Color.clear
      .frame(height: headerHeight)
      .overlay {
        headerOverlayView(screenGeometry: screenGeometry)
      }
      .id("header")
  }
  
  func contentSections(screenGeometry: GeometryProxy) -> some View {
    VStack(spacing: headerHeight) { //to ensure that prevuios page will scroll out from current screen
      appBlockingSection(screenGeometry: screenGeometry)
      statsSection(screenGeometry: screenGeometry)
      focusBreaksSection(screenGeometry: screenGeometry)
    }
  }
  
  var sideNavigationPanel: some View {
    HStack(spacing: 0) {
      Spacer()
      VStack(spacing: 20) {
        Spacer()
        navigationButtons
          .padding(.top,120)
        Spacer()
      }
      Spacer()
        .frame(width: 4)
    }
  }
}

// MARK: - Section Views
private extension AppMonitorScreen {
  
  func appBlockingSection(screenGeometry: GeometryProxy) -> some View {
    VStack {
      appBlockingContent
      Spacer(minLength: 0)
    }
    .frame(minHeight: screenGeometry.size.height - headerHeight - Constants.headerPadding)
    .padding(.horizontal, Constants.horizontalPadding)
    .padding(.top, Constants.headerPadding)
    .id(0)
    .background(sectionPositionTracker(for: 0))
  }
  
  func statsSection(screenGeometry: GeometryProxy) -> some View {
    VStack {
      Spacer()
        .frame(height: headerHeight + Constants.headerPadding)
      statsContent
      Spacer(minLength: 0)
    }
    .frame(minHeight: screenGeometry.size.height)
    .padding(.horizontal, Constants.horizontalPadding)
    .id(1)
    .background(sectionPositionTracker(for: 1))
  }
  
  func focusBreaksSection(screenGeometry: GeometryProxy) -> some View {
    VStack {
      Spacer()
        .frame(height: headerHeight + Constants.headerPadding)
      focusBreaksContent
      Spacer(minLength: 0)
    }
    .frame(minHeight: screenGeometry.size.height)
    .padding(.horizontal, Constants.horizontalPadding)
    .id(2)
    .background(sectionPositionTracker(for: 2))
  }
}

// MARK: - Content Views
private extension AppMonitorScreen {
  
  var appBlockingContent: some View {
    AppBlockingSectionView(restrictionModel: restrictionModel)
  }
  
  var statsContent: some View {
    ActivityReportView()
      .frame(maxWidth: .infinity)
      .frame(minHeight: 500)
      .frame(maxHeight: .infinity)
  }
  
  var focusBreaksContent: some View {
    VStack {
      focusBreaksHeader
        .padding(.top)
        .padding(.horizontal)
      
      separatorView.padding(.horizontal, 20)
      
      AppInterruptionsSectionView(viewModel: vmScreenInteraption)
      
      separatorView.padding(.horizontal, 20)
      
      ScreenTimeAlertsSectionView(viewModel: vmScreenAlert)
    }
    .blurBackground()
  }
  
  var focusBreaksHeader: some View {
    HStack {
      Text("Focus Breaks")
        .foregroundColor(.white)
        .font(.system(size: 19, weight: .medium))
      Spacer()
    }
  }
  
  var separatorView: some View {
    SeparatorView()
  }
}

// MARK: - Header Views
private extension AppMonitorScreen {
  
  func headerOverlayView(screenGeometry: GeometryProxy) -> some View {
    VStack(spacing: 8) {
      headerView
      screenTimeSection
    }
    .background(headerHeightReader)
    .offset(y: max(0, screenGeometry.safeAreaInsets.top - offsetY))
  }
  
  var headerView: some View {
    HStack {
      Spacer()
      profileButton
    }
    .padding(.horizontal)
  }
  
  var profileButton: some View {
    Button(action: { isShowingProfile = true }) {
      Image(systemName: "person.fill")
        .font(.system(size: 18))
        .foregroundStyle(Color.white)
        .padding()
        .contentShape(Rectangle())
    }
  }
  
  var screenTimeSection: some View {
    ScreenTimeTodayView(id: screenTimeID)
  }
  
  var headerHeightReader: some View {
    GeometryReader { proxy in
      Color.clear.onAppear {
        headerHeight = proxy.size.height
      }
    }
  }
}

// MARK: - Navigation
private extension AppMonitorScreen {
  
  var navigationButtons: some View {
    VStack(spacing: 20) {
      ForEach(0..<3) { section in
        navigationButton(for: section)
      }
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 2)
    //    .background(
    //      RoundedRectangle(cornerRadius: 16)
    //        .fill(.ultraThinMaterial)
    //    )
  }
  
  func navigationButton(for section: Int) -> some View {
    Button(action: { currentSection = section }) {
      Image(iconName(for: section))
        .resizable()
        .renderingMode(.template)
        .foregroundColor(currentSection == section ? .white : .white.opacity(0.5))
        .frame(width: currentSection == section ? 20 : 16, height: currentSection == section ? 20 : 16)
    }
  }
  
  func iconName(for section: Int) -> String {
    switch section {
      case 0: return "ic_nav_app_block"
      case 1: return "ic_nav_stats"
      case 2: return "ic_nav_app_interrupt"
      case 3: return "ic_nav_schedule"
      case 4: return "ic_nav_screen_alert"
      default: return "questionmark"
    }
  }
  
  var swipeGesture: some Gesture {
    DragGesture()
      .onEnded { value in
        handleSwipeGesture(value)
      }
  }
}

// MARK: - Helper Views
private extension AppMonitorScreen {
  
  func scrollOffsetReader(screenGeometry: GeometryProxy) -> some View {
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
  }
  
  func sectionPositionTracker(for section: Int) -> some View {
    GeometryReader { proxy in
      Color.clear
        .onAppear {
          updateSectionPosition(section, position: proxy.frame(in: .global).minY)
        }
        .onChange(of: proxy.frame(in: .global).minY) { newValue in
          updateSectionPosition(section, position: newValue)
        }
    }
  }
}

// MARK: - Helper Functions
private extension AppMonitorScreen {
  
  func setupInitialData() async {
    await AppBlockingLogger.shared.refreshAllData()
    await MainActor.run {
      familyControlsManager.requestAuthorization()
    }
  }
  
  func handleScenePhaseChange(_ newPhase: ScenePhase) {
    switch newPhase {
      case .active:
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshDate)
        if timeSinceLastRefresh > 5 {
          refreshScreenTime()
          lastRefreshDate = Date()
        }
      case .inactive, .background:
        break
      @unknown default:
        break
    }
  }
  
  func handleSwipeGesture(_ value: DragGesture.Value) {
    let threshold = Constants.swipeThreshold
    
    if value.translation.height < -threshold && currentSection < 2 {
      currentSection += 1
    } else if value.translation.height > threshold && currentSection > 0 {
      currentSection -= 1
    }
  }
  
  func scrollToSection(_ section: Int, scrollProxy: ScrollViewProxy, screenGeometry: GeometryProxy) {
    withAnimation(.easeInOut(duration: Constants.animationDuration)) {
      switch section {
        case 0:
          scrollProxy.scrollTo("header", anchor: .bottom)
        case 1, 2:
          scrollProxy.scrollTo(section, anchor: .top)
        default:
          break
      }
    }
  }
  
  func updateSectionPosition(_ section: Int, position: CGFloat) {
    guard section >= 0 && section < sectionPositions.count else { return }
    sectionPositions[section] = position
  }
  
  func refreshScreenTime() {
    screenTimeID = UUID()
  }
}

// MARK: - Preview
#Preview {
  AppMonitorScreen()
    .environmentObject(SubscriptionManager())
    .environmentObject(FamilyControlsManager.shared)
}
