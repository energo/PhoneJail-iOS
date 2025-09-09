//
//  ChartBar.swift
//  AntiSocial
//
//  Created by D C on 07.07.2025.
//

import Foundation

struct ChartBar: Identifiable, Equatable {
    var id: Int { hour }
    let hour: Int
    var focusedMinutes: Int
    var distractedMinutes: Int
    var offlineMinutes: Int = 0

    var totalMinutes: Int {
        focusedMinutes + distractedMinutes
    }
    
    /// Процент focused времени в часе с минимумом 1%
    var focusedPercent: Double {
        let percentage = Double(focusedMinutes) / 60.0 * 100
        // Если есть хоть какое-то focused время, но меньше 1%, показываем 1%
        if focusedMinutes > 0 && percentage < 1 {
            return 1
        }
        return percentage
    }
    
    /// Процент distracted времени в часе с минимумом 1%
    var distractedPercent: Double {
        let percentage = Double(distractedMinutes) / 60.0 * 100
        // Если есть хоть какое-то distracted время, но меньше 1%, показываем 1%
        if distractedMinutes > 0 && percentage < 1 {
            return 1
        }
        return percentage
    }
    
    /// Процент offline времени в часе с учетом минимумов
    var offlinePercent: Double {
        let remainingPercent = 100 - focusedPercent - distractedPercent
        return max(0, remainingPercent)
    }
}

