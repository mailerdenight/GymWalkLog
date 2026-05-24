import SwiftUI

struct MiniCalendarView: View {
    @EnvironmentObject var appSettings: AppSettings
    let records: [WorkoutRecord]

    private let calendar = Calendar.current
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var theme: AppTheme { appSettings.theme }

    private var currentMonth: Date {
        let comps = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: comps)!
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: currentMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            var comps = calendar.dateComponents([.year, .month], from: currentMonth)
            comps.day = day
            days.append(calendar.date(from: comps))
        }
        return days
    }

    private func hasRecord(on date: Date) -> Bool {
        records.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        let hasRec = hasRecord(on: date)
                        let isToday = isToday(date)
                        ZStack {
                            Circle()
                                .fill(hasRec ? theme.calendarDotColor : Color.clear)
                                .frame(width: 28, height: 28)
                            if isToday && !hasRec {
                                Circle()
                                    .stroke(theme.primaryColor.opacity(0.5), lineWidth: 1.5)
                                    .frame(width: 28, height: 28)
                            }
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 12, weight: hasRec ? .semibold : .regular))
                                .foregroundColor(hasRec ? .white : (isToday ? theme.primaryColor : .primary))
                        }
                    } else {
                        Color.clear.frame(width: 28, height: 28)
                    }
                }
            }
        }
    }
}
