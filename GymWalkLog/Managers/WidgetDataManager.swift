import Foundation
import SwiftData
import WidgetKit

// ウィジェット用データをApp Group UserDefaultsに書き込むヘルパー
// App Group が設定されるまでは標準UserDefaultsを使用
enum WidgetDataManager {
    private static let defaults = UserDefaults(suiteName: "group.com.gymwalklog.app") ?? .standard

    static func update(records: [WorkoutRecord]) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        let monthlyRecords = records.filter { $0.date >= startOfMonth }
        let count    = monthlyRecords.count
        let distance = monthlyRecords.reduce(0.0) { $0 + $1.distanceKm }
        let lastDate = records.sorted { $0.date > $1.date }.first?.date

        defaults.set(count,    forKey: "widget_monthlyCount")
        defaults.set(distance, forKey: "widget_monthlyDistance")
        if let d = lastDate { defaults.set(d, forKey: "widget_lastRecordDate") }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
