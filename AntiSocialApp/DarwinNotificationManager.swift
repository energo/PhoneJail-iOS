//
//  DarwinNotificationManager.swift
//  ScreenTimeTestApp
//
//  Created by D C on 11.02.2025.
//


import Foundation

class DarwinNotificationManager {
    
    static let shared = DarwinNotificationManager()
    
    private init() {}
    
    // 1
    private var callbacks: [String: () -> Void] = [:]
    
    // Method to post a Darwin notification
    func postNotification(name: String) {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(notificationCenter, CFNotificationName(name as CFString), nil, nil, true)
    }
    
    // 2
    func startObserving(name: String, callback: @escaping () -> Void) {
        callbacks[name] = callback
        
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        
        CFNotificationCenterAddObserver(notificationCenter,
                                        Unmanaged.passUnretained(self).toOpaque(),
                                        DarwinNotificationManager.notificationCallback,
                                        name as CFString,
                                        nil,
                                        .deliverImmediately)
    }
    
    // 3
    func stopObserving(name: String) {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveObserver(notificationCenter, Unmanaged.passUnretained(self).toOpaque(), CFNotificationName(name as CFString), nil)
        callbacks.removeValue(forKey: name)
    }
    
    // 4
    private static let notificationCallback: CFNotificationCallback = { center, observer, name, _, _ in
        guard let observer = observer else { return }
        let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()
        
        if let name = name?.rawValue as String?, let callback = manager.callbacks[name] {
            callback()
        }
    }
}
