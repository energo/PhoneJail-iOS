//
//  FirebaseReportService.swift
//  AntiSocial
//
//  Created by D C on 24.06.2025.
//


//
//  FirebaseReportService.swift
//  DoThisNow
//
//  Created by D C on 13.03.2025.
//

import Foundation
import FirebaseCrashlytics

final class FirebaseReportService {
    
    static func sendNonCrashError(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}
