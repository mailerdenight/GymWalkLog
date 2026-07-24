import SwiftUI
import SwiftData

struct CalendarFullView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    @State private var displayMonth: Date
    @State private var activeSheet: CalendarDestination?

    var theme: AppTheme { appSettings.theme }
    private let calendar = Calendar.current
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    init(initialMonth: Date = Date()) {
        _displayMonth = State(initialValue: initialMonth)
    }

    // MARK: - Computed

    private var monthRecords: [WorkoutRecord] {
        let comps = calendar.dateComponents([.year, .month], from: displayMonth)
        let start = calendar.date(from: comps)!
        let end   = calendar.date(byAdding: .month, value: 1, to: start)!
        return records.filter { $0.date >= start && $0.date < end }
    }

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

    private func firstRecord(on date: Date) -> WorkoutRecord? {
        records.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func canOpenDate(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) <= calendar.startOfDay(for: Date())
    }

    private func openDate(_ date: Date) {
        guard canOpenDate(date) else { return }
        if let record = firstRecord(on: date) {
            activeSheet = .record(recordID: record.id)
        } else {
            activeSheet = .newRecord(date: calendar.startOfDay(for: date))
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthNavigator
                    calendarGrid
                    monthlyBestCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $activeSheet) { destination in
                switch destination {
                case .newRecord(let date):
                    NewRecordView(initialDate: date)
                case .record(let recordID):
                    if let record = records.first(where: { $0.id == recordID }) {
                        NavigationStack {
                            RecordDetailView(record: record)
                        }
                    } else {
                        ContentUnavailableView("記録が見つかりません", systemImage: "calendar.badge.exclamationmark")
                    }
                }
            }
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
                        Button {
                            openDate(date)
                        } label: {
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
                        }
                        .buttonStyle(.plain)
                        .disabled(!canOpenDate(date))
                        .opacity(canOpenDate(date) ? 1 : 0.35)
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

    // MARK: - Monthly best card

    private var monthlyBestCard: some View {
        let longestDistanceRecord = monthRecords.max { $0.distanceKm < $1.distanceKm }
        let longestDurationRecord = monthRecords.max { $0.durationSeconds < $1.durationSeconds }
        let fastestPaceRecord = monthRecords
            .filter { $0.distanceKm > 0 && $0.durationSeconds > 0 }
            .min { lhs, rhs in
                (Double(lhs.durationSeconds) / lhs.distanceKm) < (Double(rhs.durationSeconds) / rhs.distanceKm)
            }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("月のベスト記録")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(monthLabel(displayMonth))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if monthRecords.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("この月の記録はまだありません")
                        .font(.subheadline)
                    Text("カレンダーの日付をタップすると、その日の記録をつけられます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    monthlyBestRow(
                        icon: "figure.run",
                        title: "最長距離",
                        value: longestDistanceRecord.map { String(format: "%.2f km", $0.distanceKm) } ?? "-",
                        record: longestDistanceRecord
                    )

                    monthlyBestRow(
                        icon: "clock",
                        title: "最長時間",
                        value: longestDurationRecord?.durationFormatted ?? "-",
                        record: longestDurationRecord
                    )

                    monthlyBestRow(
                        icon: "speedometer",
                        title: "最速ペース",
                        value: fastestPaceRecord.map(formatPace(record:)) ?? "-",
                        record: fastestPaceRecord
                    )
                }
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func monthlyBestRow(icon: String, title: String, value: String, record: WorkoutRecord?) -> some View {
        Button {
            if let record {
                activeSheet = .record(recordID: record.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                if let record {
                    Text(shortDateLabel(record.date))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .disabled(record == nil)
        .contentShape(Rectangle())
    }

    private func monthLabel(_ date: Date) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return "\(year)年\(month)月"
    }

    private func shortDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func formatPace(record: WorkoutRecord) -> String {
        let secondsPerKm = Double(record.durationSeconds) / record.distanceKm
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

private enum CalendarDestination: Identifiable {
    case newRecord(date: Date)
    case record(recordID: UUID)

    var id: String {
        switch self {
        case .newRecord(let date):
            return "new-\(date.timeIntervalSince1970)"
        case .record(let recordID):
            return "record-\(recordID.uuidString)"
        }
    }
}
