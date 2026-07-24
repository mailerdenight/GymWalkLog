import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    private let weeklySummaryID = "weekly_summary"
    private let monthlySummaryID = "monthly_summary"
    private let absenceReminderID = "absence_reminder"
    private let dailyReminderID = "daily_reminder"

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleGentleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [weeklySummaryID, monthlySummaryID, dailyReminderID])
        scheduleWeeklySummary(center: center)
        scheduleMonthlySummary(center: center)
    }

    func rescheduleAbsenceReminder(lastWorkoutDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [absenceReminderID])

        guard let fireDate = Calendar.current.date(byAdding: .day, value: 14, to: lastWorkoutDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "久しぶりですね 🌱"
        content.body = "10分だけでも大丈夫。あなたのペースで、続けていきましょう。"
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: absenceReminderID, content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [weeklySummaryID, monthlySummaryID, absenceReminderID, dailyReminderID])

        let content = UNMutableNotificationContent()
        content.title = "今日もジムへ 🌿"
        content.body = "記録をつけると、続けた証になります。"
        content.sound = .default

        var components = DateComponents()
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        center.add(request)
    }

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func refreshNotifications(for setting: NotificationSetting, lastWorkoutDate: Date?) async {
        let center = UNUserNotificationCenter.current()
        let granted = await notificationPermissionGranted()

        guard granted else {
            removeAllNotifications()
            return
        }

        switch setting {
        case .off:
            removeAllNotifications()
        case .gentle:
            scheduleGentleNotifications()
            if let lastWorkoutDate {
                rescheduleAbsenceReminder(lastWorkoutDate: lastWorkoutDate)
            } else {
                center.removePendingNotificationRequests(withIdentifiers: [absenceReminderID])
            }
        case .daily:
            scheduleDailyReminder()
        }
    }

    private static let nextNotificationFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    func nextPendingNotificationDescription() async -> String? {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let scheduled = requests.compactMap { request -> (Date, String)? in
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                  let date = trigger.nextTriggerDate() else { return nil }
            return (date, request.identifier)
        }
        .sorted { $0.0 < $1.0 }

        guard let next = scheduled.first else { return nil }
        return "\(notificationLabel(for: next.1)): \(Self.nextNotificationFormatter.string(from: next.0))"
    }

    func scheduleDebugTestNotification(after seconds: TimeInterval = 5) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "通知テスト"
        content.body = "ジム歩走ログの通知が届くか確認しています。"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        let request = UNNotificationRequest(identifier: "notification_test", content: content, trigger: trigger)
        center.add(request)
    }

    func notificationPermissionGranted() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    private func notificationLabel(for identifier: String) -> String {
        switch identifier {
        case weeklySummaryID:
            return "週次のふり返り"
        case monthlySummaryID:
            return "月次のまとめ"
        case absenceReminderID:
            return "久しぶりのお知らせ"
        case dailyReminderID:
            return "毎日リマインド"
        case "notification_test":
            return "通知テスト"
        default:
            return identifier
        }
    }

    private func scheduleWeeklySummary(center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "今日もおつかれさまです 🌿"
        content.body = "今週の記録を振り返ってみましょう。あなたのペースで、続けていますね。"
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: weeklySummaryID, content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleMonthlySummary(center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "先月の記録をふり返りましょう ✨"
        content.body = "積み重ねた記録を確認してみましょう。小さな一歩が、続けた証です。"
        content.sound = .default

        var components = DateComponents()
        components.day = 1
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: monthlySummaryID, content: content, trigger: trigger)
        center.add(request)
    }
}
