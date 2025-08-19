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
  @State private var sectionPositions: [CGFloat] = []
  
  // MARK: - Constants
  private enum Constants {
    static let swipeThreshold: CGFloat = 50
    static let animationDuration: Double = 0.6
    static let headerPadding: CGFloat = 20
    static let horizontalPadding: CGFloat = 32
    static let sectionSpacing: CGFloat = 0
  }
  
  // MARK: - Section Management
  private enum SectionType: Int, CaseIterable {
    case appBlocking = 0
    case stats = 1
    case appInterruptions = 2
    case screenTimeAlerts = 3
    
    var id: Int { rawValue }
    
    var iconName: String {
      switch self {
        case .appBlocking: return "ic_nav_app_block"
        case .stats: return "ic_nav_stats"
        case .appInterruptions: return "ic_nav_app_interrupt"
        case .screenTimeAlerts: return "ic_nav_screen_alert"
      }
    }
    
    var title: String {
      switch self {
        case .appBlocking: return "App Blocking"
        case .stats: return "Statistics"
        case .appInterruptions: return "App Interruptions"
        case .screenTimeAlerts: return "Screen Time Alerts"
      }
    }
  }
  
  private struct SectionInfo {
    let type: SectionType
    let id: Int
    let iconName: String
    let title: String
    
    init(_ type: SectionType) {
      self.type = type
      self.id = type.id
      self.iconName = type.iconName
      self.title = type.title
    }
  }
  
  private var sections: [SectionInfo] {
    SectionType.allCases.map { SectionInfo($0) }
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
      ForEach(sections, id: \.id) { section in
        sectionView(for: section, screenGeometry: screenGeometry)
      }
    }
  }
  
  @ViewBuilder
  private func sectionView(for section: SectionInfo, screenGeometry: GeometryProxy) -> some View {
    createSection(for: section.type, screenGeometry: screenGeometry)
  }
  
  private func createSection(for type: SectionType, screenGeometry: GeometryProxy) -> AnyView {
    let content: AnyView
    let needsTopSpacer: Bool
    
    switch type {
      case .appBlocking:
        content = AnyView(appBlockingContent)
        needsTopSpacer = false
      case .stats:
        content = AnyView(statsContent)
        needsTopSpacer = true
      case .appInterruptions:
        content = AnyView(appInterruptionsContent)
        needsTopSpacer = true
      case .screenTimeAlerts:
        content = AnyView(screenTimeAlertContent)
        needsTopSpacer = true
    }
    
    return AnyView(
      VStack {
        if needsTopSpacer {
          Spacer()
            .frame(height: headerHeight + Constants.headerPadding)
        }
        content
        Spacer(minLength: 0)
      }
      .frame(minHeight: type == .appBlocking ? 
             screenGeometry.size.height - headerHeight - Constants.headerPadding : 
             screenGeometry.size.height)
      .padding(.horizontal, Constants.horizontalPadding)
      .padding(.top, type == .appBlocking ? Constants.headerPadding : 0)
      .id(type.id)
      .background(sectionPositionTracker(for: type.id))
    )
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
  
  var screenTimeAlertContent: some View {
    VStack {
      screenTimeAlertHeader
        .padding(.top)
        .padding(.horizontal)
      
      separatorView.padding(.horizontal, 20)
      
      ScreenTimeAlertsSectionView(viewModel: vmScreenAlert)
    }
    .blurBackground()
  }
  
  var screenTimeAlertHeader: some View {
    HStack {
      Image(.icNavScreenAlert)
        .resizable()
        .frame(width: 24, height: 24)
        .foregroundColor(.white)

      Text("Screen time alerts")
        .foregroundColor(.white)
        .font(.system(size: 19, weight: .medium))
      Spacer()
    }
  }
  
  var appInterruptionsContent: some View {
    VStack {
      appInterruptionsHeader
        .padding(.top)
        .padding(.horizontal)
      
      separatorView.padding(.horizontal, 20)
      
      AppInterruptionsSectionView(viewModel: vmScreenInteraption)
    }
    .blurBackground()
  }
  
  var appInterruptionsHeader: some View {
    HStack {
      Image(.icNavAppInterrupt)
        .resizable()
        .frame(width: 24, height: 24)
        .foregroundColor(.white)

      Text("App interruptions")
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
      ForEach(sections, id: \.id) { section in
        navigationButton(for: section)
      }
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 2)
  }
  
  private func navigationButton(for section: SectionInfo) -> some View {
    Button(action: { currentSection = section.id }) {
      Image(section.iconName)
        .resizable()
        .renderingMode(.template)
        .foregroundColor(currentSection == section.id ? .white : .white.opacity(0.5))
        .frame(width: currentSection == section.id ? 20 : 16, height: currentSection == section.id ? 20 : 16)
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
        .onChangeWithOldValue(of: proxy.frame(in: .global).minY) { _, newValue in
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
        .onChangeWithOldValue(of: proxy.frame(in: .global).minY) { _, newValue in
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
      // Инициализируем массив позиций секций
      sectionPositions = Array(repeating: 0, count: sections.count)
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
    let maxSection = sections.count - 1
    
    if value.translation.height < -threshold && currentSection < maxSection {
      currentSection += 1
    } else if value.translation.height > threshold && currentSection > 0 {
      currentSection -= 1
    }
  }
  
  func scrollToSection(_ section: Int, scrollProxy: ScrollViewProxy, screenGeometry: GeometryProxy) {
    withAnimation(.easeInOut(duration: Constants.animationDuration)) {
      if let sectionInfo = sections.first(where: { $0.id == section }) {
        switch sectionInfo.type {
          case .appBlocking:
            scrollProxy.scrollTo("header", anchor: .bottom)
          case .stats, .appInterruptions, .screenTimeAlerts:
            scrollProxy.scrollTo(section, anchor: .top)
        }
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
