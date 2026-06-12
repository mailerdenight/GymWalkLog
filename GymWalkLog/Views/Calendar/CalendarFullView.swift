import SwiftUI
import SwiftData

struct CalendarFullView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    @State private var displayMonth = Date()

    var theme: AppTheme { appSettings.theme }
    private let calendar = Calendar.current
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    // MARK: - Computed

    private var monthRecords: [WorkoutRecord] {
        let comps = calendar.dateComponents([.year, .month], from: displayMonth)
        let start = calendar.date(from: comps)!
        let end   = calendar.date(byAdding: .month, value: 1, to: start)!
        return records.filter { $0.date >= start && $0.date < end }
    }

    private var monthlyGoal: Int { appSettings.monthlyGoal }

    private var daysGrid: [Date?] {
        let comps  = calendar.dateComponents([.year, .month], from: displayMonth)
        let start  = calendar.date(from: comps)!
        let count  = calendar.range(of: .day, in: .month, for: start)!.count
        let offset = calendar.component(.weekday, from: start) - 1
        var grid: [Date?] = Array(repeating: nil, count: offset)
        for d in 0..<count {
            grid.append(calendar.date(byAdding: .day, value: d, to: start))
        }
        return grid
    }

    private func hasRecord(on date: Date) -> Bool {
        records.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthNavigator
                    calendarGrid
                    achievementCard
                    challengeCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Month navigator

    private var monthNavigator: some View {
        HStack {
            Button {
                displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(theme.primaryColor)
                    .padding(8)
            }
            Spacer()
            let y = calendar.component(.year, from: displayMonth)
            let m = calendar.component(.month, from: displayMonth)
            Text("\(y)年\(m)月")
                .font(.headline)
            Spacer()
            Button {
                let next = calendar.date(byAdding: .month, value: 1, to: displayMonth)!
                if next <= Date() { displayMonth = next }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(
                        calendar.date(byAdding: .month, value: 1, to: displayMonth)! <= Date()
                            ? theme.primaryColor : .secondary
                    )
                    .padding(8)
            }
        }
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(weekdays, id: \.self) { d in
                    Text(d)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(Array(daysGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let hasRec   = hasRecord(on: date)
                        let isToday  = calendar.isDateInToday(date)
                        ZStack {
                            Circle()
                                .fill(hasRec ? theme.primaryColor : Color.clear)
                                .frame(width: 34, height: 34)
                            if isToday && !hasRec {
                                Circle()
                                    .stroke(theme.primaryColor.opacity(0.5), lineWidth: 1.5)
                                    .frame(width: 34, height: 34)
                            }
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 13, weight: hasRec ? .semibold : .regular))
                                .foregroundColor(
                                    hasRec ? .white :
                                    isToday ? theme.primaryColor : .primary
                                )
                        }
                    } else {
                        Color.clear.frame(width: 34, height: 34)
                    }
                }
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Achievement card

    private var achievementCard: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 10) {
                Text("今月の達成状況")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(monthRecords.count)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryColor)
                    Text("/ \(monthlyGoal)回")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                ProgressView(
                    value: Double(min(monthRecords.count, monthlyGoal)),
                    total: Double(monthlyGoal)
                )
                .tint(theme.primaryColor)
                .padding(.trailing, 70)
                let remaining = monthlyGoal - monthRecords.count
                if remaining > 0 {
                    Text("あと\(remaining)回で目標達成！")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("目標達成！すばらしい 🎉")
                        .font(.caption)
                        .foregroundColor(theme.primaryColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ThemePlantIllustration(theme: theme, size: 72)
                .padding(.trailing, 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - 30-day challenge card

    private var challengeCard: some View {
        let comps  = calendar.dateComponents([.year, .month], from: displayMonth)
        let start  = calendar.date(from: comps)!
        let count  = calendar.range(of: .day, in: .month, for: start)!.count
        let target = min(monthlyGoal, count)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("月間チャレンジ")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                let y = calendar.component(.year, from: displayMonth)
                let m = calendar.component(.month, from: displayMonth)
                Text("\(y)/\(m)/1 〜 \(y)/\(m)/\(count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text("\(count)日以内に\(target)回ジムに行こう！")
                .font(.caption)
                .foregroundColor(.secondary)

            let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(1...count, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: start)!
                    let done = hasRecord(on: date)
                    let past = date <= Date()
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                done ? theme.primaryColor :
                                past ? theme.primaryColor.opacity(0.08) : Color.clear
                            )
                            .frame(height: 30)
                        Text("\(day)")
                            .font(.system(size: 11, weight: done ? .bold : .regular))
                            .foregroundColor(done ? .white : past ? .secondary : Color(.tertiaryLabel))
                    }
                }
            }

            let remaining = target - monthRecords.count
            Text(remaining > 0 ? "あと\(remaining)回で達成。がんばりすぎなくて大丈夫。" : "達成しました 🌿")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
