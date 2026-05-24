import WidgetKit
import SwiftUI

// MARK: - Shared data key (main app も同じキーで書き込む)
private let suiteName = "group.com.gymwalklog.app"
private let keyCount    = "widget_monthlyCount"
private let keyDistance = "widget_monthlyDistance"
private let keyLastDate = "widget_lastRecordDate"

// MARK: - Timeline entry

struct WorkoutEntry: TimelineEntry {
    let date: Date
    let monthlyCount: Int
    let monthlyDistanceKm: Double
    let lastRecordDate: Date?

    static let placeholder = WorkoutEntry(
        date: Date(), monthlyCount: 8,
        monthlyDistanceKm: 42.6, lastRecordDate: Date()
    )
}

// MARK: - Provider

struct WorkoutProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutEntry) -> Void) {
        completion(context.isPreview ? .placeholder : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutEntry>) -> Void) {
        let entry = load()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func load() -> WorkoutEntry {
        let d = UserDefaults(suiteName: suiteName) ?? .standard
        return WorkoutEntry(
            date: Date(),
            monthlyCount:       d.integer(forKey: keyCount),
            monthlyDistanceKm:  d.double(forKey: keyDistance),
            lastRecordDate:     d.object(forKey: keyLastDate) as? Date
        )
    }
}

// MARK: - Color helper (standalone, no import of app target)

private let green = Color(red: 0.29, green: 0.49, blue: 0.35)

private func shortDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ja_JP")
    f.dateFormat = "M/d(EEE)"
    return f.string(from: date)
}

// MARK: - Small widget view

struct SmallWidgetView: View {
    let entry: WorkoutEntry
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(green).frame(width: 44, height: 44)
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text("記録する")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "gymwalklog://newrecord"))
    }
}

// MARK: - Medium widget view

struct MediumWidgetView: View {
    let entry: WorkoutEntry
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("ジム歩走ログ", systemImage: "figure.walk")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(green)

                Text("今月 \(entry.monthlyCount)回")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(String(format: "%.1f km", entry.monthlyDistanceKm))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                if let last = entry.lastRecordDate {
                    Text("最終: \(shortDate(last))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()

            Link(destination: URL(string: "gymwalklog://newrecord")!) {
                VStack(spacing: 4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(green)
                            .frame(width: 72, height: 52)
                        VStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("記録する")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Lock screen (accessoryCircular)

struct CircularWidgetView: View {
    var body: some View {
        ZStack {
            Circle().fill(green)
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .widgetURL(URL(string: "gymwalklog://newrecord"))
    }
}

// MARK: - Widgets

struct GymWalkLogSmallWidget: Widget {
    let kind = "GymWalkLogSmall"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ジム歩走ログ")
        .description("ワンタップで記録を始める")
        .supportedFamilies([.systemSmall])
    }
}

struct GymWalkLogMediumWidget: Widget {
    let kind = "GymWalkLogMedium"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ジム歩走ログ")
        .description("今月の記録と記録ボタン")
        .supportedFamilies([.systemMedium])
    }
}

struct GymWalkLogLockWidget: Widget {
    let kind = "GymWalkLogLock"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutProvider()) { _ in
            CircularWidgetView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ジム歩走ログ")
        .description("ロック画面から記録する")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Bundle

@main
struct GymWalkLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        GymWalkLogSmallWidget()
        GymWalkLogMediumWidget()
        GymWalkLogLockWidget()
    }
}
