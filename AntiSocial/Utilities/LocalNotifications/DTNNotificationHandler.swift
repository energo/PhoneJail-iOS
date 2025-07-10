//
//  DTNNotificationHandler.swift
//  AntiSocial
//
//  Created by D C on 10.07.2025.
//
import UserNotifications

class DTNNotificationHandler: NSObject, UNUserNotificationCenterDelegate {
  static let shared = DTNNotificationHandler()

  private override init() {
    super.init()
  }

    // Метод для обработки уведомлений в foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      // Здесь можно настроить отображение баннера или звука
    completionHandler([.banner, .sound]) // Отобразить баннер и звук, даже если приложение активно
  }

    // Метод для обработки действий пользователя с уведомлением
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    AppLogger.trace("User interacted with notification: \(response.notification.request.content.title)")

      // Выполните нужное действие, например, откройте определенный экран
    completionHandler()
  }
}
