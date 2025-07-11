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
  @StateObject private var model = DeviceActivityService.shared

    var body: some Scene {
        WindowGroup {
//          ContentView(model: SelectAppsModel())
          MainView()
            .environmentObject(authVM)
            .environmentObject(subscriptionManager)
            .environmentObject(model)
//            .task {
//              LocalNotificationManager.shared.requestAuthorization { isNotificationAuthed in
//                AppLogger.trace("isNotificationAuthed \(isNotificationAuthed)")
//                
//                UNUserNotificationCenter.current().delegate = DTNNotificationHandler.shared
//              }
//            }
            .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
            .task {
              setupATTracking()
    //          await requestSceenTimeAuthorization()
              
              // Обновляем статистику блокировок при запуске приложения
              await AppBlockingLogger.shared.refreshAllData()
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
}

//MARK: - Extensions
extension UIApplication {
    func addTapGestureRecognizer() {
        guard let window = windows.first else { return }
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

