import SwiftUI
import Combine

enum NotificationSetting: String, CaseIterable {
    case off = "off"
    case gentle = "gentle"
    case daily = "daily"

    var displayName: String {
        switch self {
        case .off: return "通知しない（おすすめ）"
        case .gentle: return "やさしく通知"
        case .daily: return "毎日リマインド"
        }
    }
}

class AppSettings: ObservableObject {
    @AppStorage("theme") var themeRaw: String = AppTheme.natural.rawValue {
        willSet { objectWillChange.send() }
    }
    @AppStorage("notificationSetting") var notificationRaw: String = NotificationSetting.off.rawValue {
        willSet { objectWillChange.send() }
    }
    @AppStorage("isPro") var isPro: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("firstLaunchDate") var firstLaunchTimestamp: Double = 0 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("monthlyGoal") var monthlyGoal: Int = 8 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("bodyWeightKg") var bodyWeightKg: Double = 65.0 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("gender") var gender: String = "" {
        willSet { objectWillChange.send() }
    }

    var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .natural }
        set { themeRaw = newValue.rawValue }
    }

    var notificationSetting: NotificationSetting {
        get { NotificationSetting(rawValue: notificationRaw) ?? .off }
        set { notificationRaw = newValue.rawValue }
    }

    var firstLaunchDate: Date {
        get {
            if firstLaunchTimestamp == 0 {
                let now = Date().timeIntervalSince1970
                firstLaunchTimestamp = now
                return Date(timeIntervalSince1970: now)
            }
            return Date(timeIntervalSince1970: firstLaunchTimestamp)
        }
    }

    var daysSinceLaunch: Int {
        Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
    }

    var isTrialExpired: Bool {
        daysSinceLaunch >= 30
    }
}
