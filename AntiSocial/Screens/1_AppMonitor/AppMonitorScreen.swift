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
  @EnvironmentObject var scheduleNotificationHandler: ScheduleNotificationHandler
  @Environment(\.scenePhase) var scenePhase
  
  // MARK: - View Models
  @StateObject var vmScreenInteraption = AppInterruptionViewModel()
  @StateObject var vmScreenAlert = ScreenTimeAlertViewModel()
  
  // Keep ScreenTimeTodayView instance to avoid unnecessary recreation
  @State var screenTimeView = ScreenTimeTodayView()
  @State var statsView = ActivityReportView()
  // Single refresh key used by pull-to-refresh and restore foregrounding
  @State private var screenTimeRefreshID = UUID()
  
  // MARK: - Optimized Content Views
  @State private var appBlockingContent = AppBlockingSectionView()
  @State private var blockSchedulerContent = BlockSchedulerSectionView()
  @State private var pomodoroContent = PomodoroSectionView()
  

  // MARK: - UI State
  @AppStorage("lastRefreshDate")
  private var lastRefreshTimestamp: TimeInterval = 0
  
  private var lastRefreshDate: Date {
    get {
      if lastRefreshTimestamp > 0 {
        return Date(timeIntervalSince1970: lastRefreshTimestamp)
      } else {
        return .distantPast
      }
    }
    set {
      lastRefreshTimestamp = newValue.timeIntervalSince1970
    }
  }

  @State private var isShowingProfile: Bool = false
  @State private var offsetY: CGFloat = .zero
  @State private var headerHeight: CGFloat = UIScreen.main.bounds.height * 0.30

  // MARK: - Navigation State
  @State private var currentSection = 0
  @State private var scrollOffset: CGFloat = 0
  @State private var isDragging = false
  @State private var sectionPositions: [CGFloat] = []
  @State private var isScrolling = false
  
  // MARK: - Constants
  private enum Constants {
    static let swipeThreshold: CGFloat = 20
    static let animationDuration: Double = 0.5
    static let scrollAnimationDuration: Double = 0.45
    static let headerPadding: CGFloat = 10
    static let horizontalPadding: CGFloat = 32
    static let sectionSpacing: CGFloat = 0
  }
  
  // MARK: - Section Management
  private enum SectionType: Int, CaseIterable {
    case appBlocking = 0
    case blockScheduler = 1
    case focusBreakers = 2
    case stats = 3
    case pomodoro = 4
    
    var id: Int { rawValue }
    
    var iconName: String {
      switch self {
        case .appBlocking: return "ic_nav_app_block"
        case .blockScheduler: return "ic_nav_schedule"
        case .pomodoro: return "ic_nav_pomodoro" // Using timer icon
        case .stats: return "ic_nav_stats"
        case .focusBreakers: return "ic_nav_app_interrupt"
      }
    }
    
    var title: String {
      switch self {
        case .appBlocking: return "App Blocking"
        case .blockScheduler: return "Block Scheduler"
        case .pomodoro: return "Pomodoro Focus"
        case .stats: return "Statistics"
        case .focusBreakers: return "Focus Breakers"
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
    .onChangeWithOldValue(of: currentSection, perform: { oldValue, newValue in
      AppLogger.alert("currentSection \(currentSection)")
    })
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
        // Пользователь, вероятно, начал системный жест/ушёл в другой апп/вызов и т.п.
        // Сохраните состояние, остановите анимации, зафиксируйте таймеры и т.д.
        AppLogger.trace("willResignActive — вероятно системный свайп снизу/уход")
    }

//    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
//      reloadScreenTimeIfNeeded()
//    }
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
      .scrollDismissesKeyboard(.immediately)
      .scrollIndicators(.hidden)
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
      case .blockScheduler:
        content = AnyView(blockSchedulerContent)
        needsTopSpacer = true
      case .stats:
        content = AnyView(statsContent)
        needsTopSpacer = true
      case .focusBreakers:
        content = AnyView(focusBreakersContent)
        needsTopSpacer = true
      case .pomodoro:
        content = AnyView(pomodoroContent)
        needsTopSpacer = false
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
      VStack(spacing: 2) {
        Spacer()
        navigationButtons
          .padding(.top, 120)
        Spacer()
      }
      Spacer()
        .frame(width: 4)
    }
  }
}

// MARK: - Content Views
private extension AppMonitorScreen {
//  var appBlockingContent: some View {
//    appBlockingContent ?? createAppBlockingContent()
//  }
//  
//  var blockSchedulerContent: some View {
//    blockSchedulerContent ?? createBlockSchedulerContent()
//  }
//  
//  var pomodoroContent: some View {
//    pomodoroContent ?? createPomodoroContent()
//  }
  
  var statsContent: some View {
    statsView
      .id(screenTimeRefreshID)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 500)
      .frame(maxHeight: .infinity)
  }
  
  var focusBreakersContent: some View {
    VStack(spacing: 20) {
      // Combined header for Focus Breakers
      focusBreakersHeader
        .padding(.top)
        .padding(.horizontal)
      
      separatorView.padding(.horizontal, 20)

      AppInterruptionsSectionView(viewModel: vmScreenInteraption)

      separatorView.padding(.horizontal, 20)
      
      ScreenTimeAlertsSectionView(viewModel: vmScreenAlert)
        .padding(.bottom, 20)
    }
    .blurBackground()
  }
  
  var focusBreakersHeader: some View {
    HStack {
      Image(.icNavAppInterrupt)
        .resizable()
        .frame(width: 24, height: 24)
        .foregroundColor(.white)

      Text("Nudges")
        .foregroundColor(.white)
        .font(.system(size: 20, weight: .bold))
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
    VStack(spacing: 0) {
      headerView
      screenTimeSection
    }
    .offset(y: max(0, screenGeometry.safeAreaInsets.top - offsetY))
  }
  
  var headerView: some View {
    HStack {
      Spacer()
      profileButton
    }
    .padding(.horizontal)
    .frame(height: 30)
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
    screenTimeView
      .opacity(currentSection == SectionType.pomodoro.rawValue ? 0 : 1)
      .animation(.easeInOut(duration: 0.3), value: currentSection)
  }
}

// MARK: - Navigation
private extension AppMonitorScreen {
    var navigationButtons: some View {
    VStack(spacing: 0) {
      ForEach(sections, id: \.id) { section in
        navigationButton(for: section)
      }
    }
    .padding(.horizontal, 2)
  }
  
  private func navigationButton(for section: SectionInfo) -> some View {
    Button(action: { 
      guard currentSection != section.id else { return }
      HapticManager.shared.impact(style: .light)
      currentSection = section.id 
    }) {
      Image(section.iconName)
        .resizable()
        .renderingMode(.template)
        .foregroundColor(currentSection == section.id ? .white : .white.opacity(0.5))
        .frame(width: currentSection == section.id ? 20 : 16, height: currentSection == section.id ? 20 : 16)
        .padding(10)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2),
                   value: currentSection == section.id)
        .offset(x: 10)
    }
    .disabled(isScrolling)
  }
  
  var swipeGesture: some Gesture {
    DragGesture(minimumDistance: 10)
      .onChanged { value in
        // Фильтруем свайпы, начатые слишком близко к нижней кромке экрана
        let startY = value.startLocation.y
        let updatedStartY = startY - value.translation.height

        if let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first {
          let safeBottom = window.safeAreaInsets.bottom
          let screenH = window.bounds.height
          let bottomGuardZone: CGFloat = max(20, safeBottom + 10)
          
          if updatedStartY > screenH - bottomGuardZone {
            AppLogger.trace("Swipe gesture ignored - started too close to bottom edge (startY: \(updatedStartY), guardZone: \(screenH - bottomGuardZone))")
            return // игнорировать, очень близко к Home Indicator
          }
        }
        
        // Log gesture changes for debugging
        AppLogger.trace("Swipe gesture changed - translation: \(value.translation.height), startY: \(updatedStartY), scenePhase: \(scenePhase)")
      }
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
    
    sectionPositions = Array(repeating: 0, count: sections.count)
    // Check and apply active schedules on app launch
    BlockSchedulerService.shared.checkAndApplyActiveSchedules()
  }
  
  func handleScenePhaseChange(_ newPhase: ScenePhase) {
    switch newPhase {
      case .active:
        reloadScreenTimeIfNeeded()
        BlockSchedulerService.shared.checkAndApplyActiveSchedules()
        AppLogger.trace("Scene phase: active - gestures enabled")

      case .inactive, .background:
        AppLogger.trace("Scene phase: \(newPhase) - gestures disabled")
        break
      @unknown default:
        break
    }
  }
  
  private func reloadScreenTimeIfNeeded() {
    let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshDate)
    if timeSinceLastRefresh > 5 {
        refreshScreenTime()
    }
  }
  
  func handleSwipeGesture(_ value: DragGesture.Value) {
    guard !isScrolling else { return }
    
    // Prevent swipe gesture from triggering when app is not active
    guard scenePhase == .active else { 
      AppLogger.trace("Swipe gesture ignored - app not active (scenePhase: \(scenePhase))")
      return 
    }
    
    let threshold = Constants.swipeThreshold
    let maxSection = sections.count - 1
    
    if value.translation.height < -threshold && currentSection < maxSection {
      HapticManager.shared.impact(style: .light)
      currentSection += 1
      AppLogger.trace("Swipe gesture: currentSection increased to \(currentSection)")
    } else if value.translation.height > threshold && currentSection > 0 {
      HapticManager.shared.impact(style: .light)
      currentSection -= 1
      AppLogger.trace("Swipe gesture: currentSection decreased to \(currentSection)")
    }
  }
  
  func scrollToSection(_ section: Int, scrollProxy: ScrollViewProxy, screenGeometry: GeometryProxy) {
    // Prevent multiple scroll animations
    guard !isScrolling else { return }
    
    isScrolling = true
    
    // Strong pagination effect with easeInOut for snap feeling
    withAnimation(.easeInOut(duration: Constants.scrollAnimationDuration)) {
      if let sectionInfo = sections.first(where: { $0.id == section }) {
        switch sectionInfo.type {
          case .appBlocking:
            scrollProxy.scrollTo("header", anchor: .bottom)
          case .blockScheduler,
              .pomodoro,
              .stats, .focusBreakers:
            scrollProxy.scrollTo(section, anchor: .top)
        }
      }
    }
    
    // Reset scrolling flag after animation completes
    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.scrollAnimationDuration + 0.2) {
      isScrolling = false
    }
  }
  
  func updateSectionPosition(_ section: Int, position: CGFloat) {
    guard section >= 0 && section < sectionPositions.count else { return }
    sectionPositions[section] = position
  }
  
  @MainActor
  func refreshScreenTime() {
    // Generate a new token to trigger refresh in dependent views
    screenTimeRefreshID = UUID()
    
    // Store the timestamp directly to avoid mutating computed property on a struct View
    lastRefreshTimestamp = Date().timeIntervalSince1970
    
    // Propagate the token to the screenTimeView
    screenTimeView.refreshToken = screenTimeRefreshID
  }
}

// MARK: - Preview
#Preview {
  AppMonitorScreen()
    .environmentObject(SubscriptionManager())
    .environmentObject(FamilyControlsManager.shared)
}

