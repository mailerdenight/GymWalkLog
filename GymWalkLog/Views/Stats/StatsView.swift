import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var allRecords: [WorkoutRecord]
    @State private var selectedPeriod = 0
    @State private var currentDate = Date()
    @State private var showProUpgrade = false

    var theme: AppTheme { appSettings.theme }

    private let calendar = Calendar.current
    private let periodOptions = ["週", "月", "年"]

    var body: some View {
        ScrollView {
            if !appSettings.isPro {
                proRequiredView
            } else {
                statsContent
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .navigationTitle("統計")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
    }

    private var proRequiredView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundColor(theme.primaryColor.opacity(0.5))
                Text("統計グラフはPro機能です")
                    .font(.headline)
                Text("月別・年別の振り返りグラフが使えます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)

            previewStatsCard

            Button {
                showProUpgrade = true
            } label: {
                Text("Proをみる（\(purchaseManager.priceString)）")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.primaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            Spacer(minLength: 80)
        }
        .padding(.horizontal, 16)
    }

    private var previewStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プレビュー（今月）")
                .font(.subheadline)
                .foregroundColor(.secondary)

            let monthRecords = currentMonthRecords()
            let totalDist = monthRecords.reduce(0.0) { $0 + $1.distanceKm }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f km", totalDist))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryColor)
                    Text("累積距離")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            blurredChart(records: monthRecords)
                .frame(height: 120)
                .blur(radius: 4)
                .overlay(
                    Text("Proで見る")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryColor)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                )

            Text("※Pro購入で過去の月も閲覧できます")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func blurredChart(records: [WorkoutRecord]) -> some View {
        Chart(records) { record in
            BarMark(
                x: .value("日", record.date, unit: .day),
                y: .value("距離", record.distanceKm)
            )
            .foregroundStyle(theme.primaryColor.opacity(0.6))
        }
    }

    private var statsContent: some View {
        VStack(spacing: 16) {
            periodSelector

            monthNavigator

            summaryCards

            distanceChart

            streakCard

            Spacer(minLength: 80)
        }
        .padding(.horizontal, 16)
    }

    private var periodSelector: some View {
        Picker("期間", selection: $selectedPeriod) {
            ForEach(0..<periodOptions.count, id: \.self) { i in
                Text(periodOptions[i]).tag(i)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 8)
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(theme.primaryColor)
            }

            Spacer()

            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            Text("\(year)年\(month)月")
                .font(.headline)

            Spacer()

            Button {
                let next = calendar.date(byAdding: .month, value: 1, to: currentDate)!
                if next <= Date() {
                    currentDate = next
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.primaryColor)
            }
        }
        .padding(12)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var summaryCards: some View {
        let records = periodRecords()
        let count = records.count
        let dist = records.reduce(0.0) { $0 + $1.distanceKm }
        let dur = records.reduce(0) { $0 + $1.durationSeconds }
        let kcal = records.compactMap { $0.caloriesKcal }.reduce(0, +)

        return HStack(spacing: 10) {
            summaryCard(value: "\(count)", unit: "回", label: "回数")
            summaryCard(value: String(format: "%.1f", dist), unit: "km", label: "距離")
            summaryCard(value: formatHours(dur), unit: "", label: "時間")
            summaryCard(value: "\(Int(kcal))", unit: "kcal", label: "カロリー")
        }
    }

    private func summaryCard(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryColor)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    private var distanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("距離（km）")
                .font(.subheadline)
                .fontWeight(.medium)

            Chart(periodRecords()) { record in
                BarMark(
                    x: .value("日", record.date, unit: .day),
                    y: .value("距離", record.distanceKm)
                )
                .foregroundStyle(theme.primaryColor.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(dayLabel(date))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var streakCard: some View {
        let streak = currentStreak()
        let best = bestStreak()
        return HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(streak)日")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryColor)
                Text("連続記録")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 4) {
                Text("\(best)日")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Text("ベスト")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func currentMonthRecords() -> [WorkoutRecord] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return allRecords.filter { $0.date >= start }
    }

    private func periodRecords() -> [WorkoutRecord] {
        let start: Date
        switch selectedPeriod {
        case 0:
            start = calendar.date(byAdding: .day, value: -7, to: currentDate)!
        case 2:
            let comps = calendar.dateComponents([.year], from: currentDate)
            start = calendar.date(from: comps)!
        default:
            let comps = calendar.dateComponents([.year, .month], from: currentDate)
            start = calendar.date(from: comps)!
        }

        let end: Date
        switch selectedPeriod {
        case 0:
            end = calendar.date(byAdding: .day, value: 7, to: start)!
        case 2:
            end = calendar.date(byAdding: .year, value: 1, to: start)!
        default:
            end = calendar.date(byAdding: .month, value: 1, to: start)!
        }

        return allRecords.filter { $0.date >= start && $0.date < end }
    }

    private func currentStreak() -> Int {
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        while true {
            let has = allRecords.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if has {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else { break }
        }
        return streak
    }

    private func bestStreak() -> Int {
        guard !allRecords.isEmpty else { return 0 }
        let sortedDates = Set(allRecords.map { calendar.startOfDay(for: $0.date) }).sorted()
        var best = 1
        var current = 1
        for i in 1..<sortedDates.count {
            let diff = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if diff == 1 { current += 1; best = max(best, current) }
            else { current = 1 }
        }
        return best
    }

    private func formatHours(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}
