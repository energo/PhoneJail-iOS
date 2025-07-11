//
//  FirestoreStorage+AppBlocking.swift
//  AntiSocial
//
//  Created by AI Assistant on 12.01.2025.
//

import Foundation
import FirebaseFirestore

extension FirestoreStorage {
    
    // MARK: - Blocking Sessions
    
    func saveBlockingSession(_ session: AppBlockingSession) async throws {
        let userId = try ensureUserId()
        let sessionRef = db.collection("users").document(userId)
                          .collection("blocking_sessions").document(session.id)
        
        let data: [String: Any] = [
            "id": session.id,
            "userId": session.userId,
            "applicationToken": session.applicationToken,
            "appDisplayName": session.appDisplayName,
            "startDate": Timestamp(date: session.startDate),
            "endDate": session.endDate != nil ? Timestamp(date: session.endDate!) : NSNull(),
            "plannedDuration": session.plannedDuration,
            "actualDuration": session.actualDuration ?? NSNull(),
            "wasCompleted": session.wasCompleted,
            "createdAt": Timestamp(date: session.createdAt)
        ]
        
        try await sessionRef.setData(data, merge: true)
    }
    
    func getBlockingSessions(for userId: String) async throws -> [AppBlockingSession] {
        let sessionsRef = db.collection("users").document(userId).collection("blocking_sessions")
        let snapshot = try await sessionsRef.order(by: "startDate", descending: true).getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? parseBlockingSession(from: document.data())
        }
    }
    
    func getActiveBlockingSessions(for userId: String) async throws -> [AppBlockingSession] {
        let sessionsRef = db.collection("users").document(userId).collection("blocking_sessions")
        let snapshot = try await sessionsRef.whereField("endDate", isEqualTo: NSNull()).getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? parseBlockingSession(from: document.data())
        }
    }
    
    func getBlockingSession(by id: String, for userId: String) async throws -> AppBlockingSession? {
        let sessionRef = db.collection("users").document(userId).collection("blocking_sessions").document(id)
        let document = try await sessionRef.getDocument()
        
        guard let data = document.data() else { return nil }
        return try parseBlockingSession(from: data)
    }
    
    func deleteBlockingSession(id: String, for userId: String) async throws {
        let sessionRef = db.collection("users").document(userId).collection("blocking_sessions").document(id)
        try await sessionRef.delete()
    }
    
    // MARK: - Daily Stats
    
    func saveDailyBlockingStats(_ stats: DailyAppBlockingStats) async throws {
        let userId = try ensureUserId()
        let statsRef = db.collection("users").document(userId)
                        .collection("daily_blocking_stats").document(stats.id)
        
        let data: [String: Any] = [
            "id": stats.id,
            "userId": stats.userId,
            "date": stats.date,
            "applicationToken": stats.applicationToken,
            "appDisplayName": stats.appDisplayName,
            "totalBlockedDuration": stats.totalBlockedDuration,
            "sessionsCount": stats.sessionsCount,
            "completedSessionsCount": stats.completedSessionsCount,
            "averageSessionDuration": stats.averageSessionDuration
        ]
        
        try await statsRef.setData(data, merge: true)
    }
    
    func getDailyBlockingStats(for userId: String, date: Date) async throws -> [DailyAppBlockingStats] {
        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        let statsRef = db.collection("users").document(userId).collection("daily_blocking_stats")
        let snapshot = try await statsRef.whereField("date", isEqualTo: dateString).getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? parseDailyBlockingStats(from: document.data())
        }
    }
    
    func getBlockingStatsForPeriod(for userId: String, from: Date, to: Date) async throws -> [DailyAppBlockingStats] {
        let fromString = DateFormatter.yyyyMMdd.string(from: from)
        let toString = DateFormatter.yyyyMMdd.string(from: to)
        
        let statsRef = db.collection("users").document(userId).collection("daily_blocking_stats")
        let snapshot = try await statsRef
            .whereField("date", isGreaterThanOrEqualTo: fromString)
            .whereField("date", isLessThanOrEqualTo: toString)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? parseDailyBlockingStats(from: document.data())
        }
    }
    
    func getTopBlockedApps(for userId: String, limit: Int) async throws -> [(appName: String, totalDuration: TimeInterval)] {
        // Firestore не поддерживает GROUP BY, поэтому делаем агрегацию на клиенте
        let statsRef = db.collection("users").document(userId).collection("daily_blocking_stats")
        let snapshot = try await statsRef.getDocuments()
        
        var appDurations: [String: TimeInterval] = [:]
        
        for document in snapshot.documents {
            if let stats = try? parseDailyBlockingStats(from: document.data()) {
                appDurations[stats.appDisplayName, default: 0] += stats.totalBlockedDuration
            }
        }
        
        return Array(appDurations.sorted { $0.value > $1.value }.prefix(limit))
            .map { (appName: $0.key, totalDuration: $0.value) }
    }
    
    func deleteOldBlockingData(for userId: String, olderThan date: Date) async throws {
        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        
        // Удаляем старые сессии
        let sessionsRef = db.collection("users").document(userId).collection("blocking_sessions")
        let sessionsSnapshot = try await sessionsRef.whereField("startDate", isLessThan: Timestamp(date: date)).getDocuments()
        
        for document in sessionsSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Удаляем старую статистику
        let statsRef = db.collection("users").document(userId).collection("daily_blocking_stats")
        let statsSnapshot = try await statsRef.whereField("date", isLessThan: dateString).getDocuments()
        
        for document in statsSnapshot.documents {
            try await document.reference.delete()
        }
    }
    
    // MARK: - Parsing Helpers
    
    private func parseBlockingSession(from data: [String: Any]) throws -> AppBlockingSession {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let applicationToken = data["applicationToken"] as? Data,
              let appDisplayName = data["appDisplayName"] as? String,
              let startDateTimestamp = data["startDate"] as? Timestamp,
              let plannedDuration = data["plannedDuration"] as? TimeInterval,
              let wasCompleted = data["wasCompleted"] as? Bool,
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            throw NSError(domain: "FirestoreStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid blocking session data"])
        }
        
        let endDate: Date?
        if let endDateTimestamp = data["endDate"] as? Timestamp {
            endDate = endDateTimestamp.dateValue()
        } else {
            endDate = nil
        }
        
        let actualDuration: TimeInterval?
        if let duration = data["actualDuration"] as? TimeInterval {
            actualDuration = duration
        } else {
            actualDuration = nil
        }
        
        return AppBlockingSession(
            id: id,
            userId: userId,
            applicationToken: applicationToken,
            appDisplayName: appDisplayName,
            startDate: startDateTimestamp.dateValue(),
            endDate: endDate,
            plannedDuration: plannedDuration,
            actualDuration: actualDuration,
            wasCompleted: wasCompleted,
            createdAt: createdAtTimestamp.dateValue()
        )
    }
    
    private func parseDailyBlockingStats(from data: [String: Any]) throws -> DailyAppBlockingStats {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let date = data["date"] as? String,
              let applicationToken = data["applicationToken"] as? Data,
              let appDisplayName = data["appDisplayName"] as? String,
              let totalBlockedDuration = data["totalBlockedDuration"] as? TimeInterval,
              let sessionsCount = data["sessionsCount"] as? Int,
              let completedSessionsCount = data["completedSessionsCount"] as? Int,
              let averageSessionDuration = data["averageSessionDuration"] as? TimeInterval else {
            throw NSError(domain: "FirestoreStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid daily blocking stats data"])
        }
        
        return DailyAppBlockingStats(
            id: id,
            userId: userId,
            date: date,
            applicationToken: applicationToken,
            appDisplayName: appDisplayName,
            totalBlockedDuration: totalBlockedDuration,
            sessionsCount: sessionsCount,
            completedSessionsCount: completedSessionsCount,
            averageSessionDuration: averageSessionDuration
        )
    }
} 