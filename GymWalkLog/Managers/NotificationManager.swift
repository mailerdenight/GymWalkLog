import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()

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
        center.removeAllPendingNotificationRequests()
        scheduleWeeklySummary(center: center)
        scheduleMonthlySummary(center: center)
    }

    func rescheduleAbsenceReminder(lastWorkoutDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["absence_reminder"])

        guard let fireDate = Calendar.current.date(byAdding: .day, value: 14, to: lastWorkoutDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "久しぶりですね 🌱"
        content.body = "10分だけでも大丈夫。あなたのペースで、続けていきましょう。"
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "absence_reminder", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "今日もジムへ 🌿"
        content.body = "記録をつけると、続けた証になります。"
        content.sound = .default

        var components = DateComponents()
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        center.add(request)
    }

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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
        let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleMonthlySummary(center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "今月もよくがんばりました ✨"
        content.body = "今月の記録を確認してみましょう。小さな積み重ねが、続けた証です。"
        content.sound = .default

        var components = DateComponents()
        components.day = 1
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "monthly_summary", content: content, trigger: trigger)
        center.add(request)
    }
}
