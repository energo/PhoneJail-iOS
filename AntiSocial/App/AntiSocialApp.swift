//
//  ScreenTimeTestAppApp.swift
//  ScreenTimeTestApp
//
//  Created by D C on 11.02.2025.
//


import SwiftUI
import FirebaseCore
import AppTrackingTransparency
//import FBSDKCoreKit
//import FBSDKCoreKit_Basics
import DeviceActivity
//import FamilyControls

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
//    Settings.shared.isAdvertiserIDCollectionEnabled = true
//    Settings.shared.isAutoLogAppEventsEnabled = true
//
//    ApplicationDelegate.shared.application(
//        application,
//        didFinishLaunchingWithOptions: launchOptions
//    )
    
    return true
  }
}

@main
struct AntiSocialApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject private var authVM = AuthenticationViewModel(subscriptionManager: SubscriptionManager.shared)
  @StateObject private var subscriptionManager = SubscriptionManager.shared
  @StateObject private var deviceActivityService = DeviceActivityService.shared
  @StateObject private var familyControlsManager = FamilyControlsManager.shared
  @State private var midnightTimer: Timer?
  @AppStorage("isFirstRun") private var isFirstRun: Bool = true

    var body: some Scene {
        WindowGroup {
//          ContentView(model: SelectAppsModel())
          MainView()
            .environmentObject(authVM)
            .environmentObject(subscriptionManager)
            .environmentObject(deviceActivityService)
            .environmentObject(familyControlsManager)
            .task {
              if !isFirstRun {
                LocalNotificationManager.shared.requestAuthorization { isNotificationAuthed in
                  AppLogger.trace("isNotificationAuthed \(isNotificationAuthed)")
                  
                  UNUserNotificationCenter.current().delegate = DTNNotificationHandler.shared
                }
              }
            }
            .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
            .task {
              setupATTracking()
    //          await requestSceenTimeAuthorization()
              
              // Обновляем статистику блокировок при запуске приложения
              await AppBlockingLogger.shared.refreshAllData()
              
              // Setup midnight timer for resetting usage counters
              setupMidnightTimer()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
              Task {
                // Обновляем статистику при возврате в приложение
                await AppBlockingLogger.shared.refreshAllData()
              }
            }

        }
    }
  
  private func setupATTracking() {
      if #available(iOS 14, *) {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              ATTrackingManager.requestTrackingAuthorization { status in
                  switch status {
                  case .authorized:
                      break
//                      Settings.shared.isAutoLogAppEventsEnabled = true
//                      Settings.shared.isAdvertiserIDCollectionEnabled = true
                      
//                      ApplicationDelegate.shared.initializeSDK() // инициализация после установки флагов

//                        FirebaseReportService.sendCustomEvent(.at_tracking, parameters: ["status": "authorized"])
                  default:
                      break
//                        FirebaseReportService.sendCustomEvent(.at_tracking, parameters: ["status": "denied"])
                  }
              }
          }
      }
  }
  
  private func setupMidnightTimer() {
    // Cancel existing timer if any
    midnightTimer?.invalidate()
    
    // Calculate time until midnight
    let calendar = Calendar.current
    let now = Date()
    
    guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
          let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else { return }
    
    let timeUntilMidnight = midnight.timeIntervalSince(now)
    
    // Create timer that fires at midnight
    midnightTimer = Timer.scheduledTimer(withTimeInterval: timeUntilMidnight, repeats: false) { _ in
      // Reset app usage counters
      SharedData.resetAppUsageTimes()
      AppLogger.notice("Reset app usage counters at midnight")
      
      // Setup next midnight timer
      self.setupMidnightTimer()
    }
  }
}

//MARK: - Extensions
extension UIApplication {
    func addTapGestureRecognizer() {
        // Find the first foreground active UIWindowScene
        guard let windowScene = self.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first else { return }
        
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        window.addGestureRecognizer(tapGesture)
    }
}

extension UIApplication: @retroactive UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true // set to `false` if you don't want to detect tap during other gestures
    }
}

