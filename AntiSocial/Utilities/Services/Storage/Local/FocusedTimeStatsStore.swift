import Foundation

final class FocusedTimeStatsStore {
    static let shared = FocusedTimeStatsStore()
    private let suiteName = "group.ScreenTimeTestApp.sharedData"
    private let statsKey = "FocusedTimeStats"
    private var userDefaults: UserDefaults? { UserDefaults(suiteName: suiteName) }
    
    struct Entry: Codable, Hashable {
        let date: String // yyyy-MM-dd
        let appId: String
        var duration: TimeInterval
    }
    
    private init() {}
    
    // MARK: - Save usage
    func saveUsage(for appId: String, date: Date, duration: TimeInterval) {
        let dateString = Self.dateFormatter.string(from: date)
        var stats = loadAllStats()
        if let idx = stats.firstIndex(where: { $0.date == dateString && $0.appId == appId }) {
            stats[idx].duration += duration
        } else {
            stats.append(Entry(date: dateString, appId: appId, duration: duration))
        }
        saveAllStats(stats)
    }
    
    // MARK: - Get usage for date
    func getUsage(for date: Date) -> [String: TimeInterval] {
        let dateString = Self.dateFormatter.string(from: date)
        let stats = loadAllStats().filter { $0.date == dateString }
        var result: [String: TimeInterval] = [:]
        for entry in stats {
            result[entry.appId, default: 0] += entry.duration
        }
        return result
    }
    
    func getTotalFocusedTime(for date: Date) -> TimeInterval {
        getUsage(for: date).values.reduce(0, +)
    }
    
    // MARK: - Internal storage
    private func loadAllStats() -> [Entry] {
        guard let data = userDefaults?.data(forKey: statsKey),
              let stats = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return stats
    }
    
    private func saveAllStats(_ stats: [Entry]) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        userDefaults?.set(data, forKey: statsKey)
    }
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
} 