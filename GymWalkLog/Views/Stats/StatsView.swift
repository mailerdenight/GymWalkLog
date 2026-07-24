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
    @State private var showTrophies = false

    var theme: AppTheme { appSettings.theme }

    private let calendar = Calendar.current
    private let periodOptions = ["週", "月", "年"]

    private var trophySections: [(category: TrophyCategory, trophies: [TrophyAwardState])] {
        TrophyEngine.sections(from: allRecords)
    }

    private var achievedTrophies: [TrophyAwardState] {
        trophySections
            .flatMap(\.trophies)
            .filter(\.achieved)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if !appSettings.isPro {
                    proRequiredView
                } else {
                    statsContent
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("レポート")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
            .sheet(isPresented: $showTrophies) {
                NavigationStack {
                    TrophyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showTrophies = true
                    } label: {
                        Image(systemName: "rosette")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
    }

    private var proRequiredView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundColor(theme.primaryColor.opacity(0.5))
                Text("レポートはPro機能です")
                    .font(.headline)
                Text("週・月・年の振り返りグラフが使えます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)

            previewStatsCard
            previewTrophiesCard

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

            Text("※Pro購入で週・月・年のグラフを閲覧できます")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var previewTrophiesCard: some View {
        let previewTrophies = trophySections
            .flatMap(\.trophies)
            .filter(\.achieved)
            .prefix(3)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("プレビュー（トロフィー）")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "rosette")
                    .foregroundColor(theme.primaryColor.opacity(0.7))
            }

            HStack(alignment: .top, spacing: 12) {
                if previewTrophies.isEmpty {
                    ForEach(0..<3, id: \.self) { index in
                        VStack(spacing: 8) {
                            TrophyBadgeIcon(
                                glyph: index == 0 ? .longestDistance : (index == 1 ? .monthlyDistance(24) : .streakCount(3, unit: .days)),
                                style: index == 0 ? .sunshine : (index == 1 ? .bronze : .streak),
                                achieved: true,
                                theme: theme
                            )
                            .frame(width: 62, height: 62)
                            .blur(radius: 3.5)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.primaryColor.opacity(0.12))
                                .frame(height: 10)
                                .blur(radius: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(Array(previewTrophies), id: \.id) { trophy in
                        VStack(spacing: 8) {
                            TrophyBadgeIcon(
                                glyph: trophy.definition.glyph,
                                style: trophy.definition.style,
                                achieved: trophy.achieved,
                                theme: theme
                            )
                            .frame(width: 62, height: 62)
                            .blur(radius: 3.5)

                            Text(trophy.definition.title)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .blur(radius: 2.4)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .overlay {
                Text("Proでトロフィー一覧を見る")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text("※自己ベストや継続記録のバッジも確認できます")
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
            achievementsOverviewCard

            periodSelector

            periodNavigator

            summaryCards

            personalBestCard

            distanceChart

            streakCard

            Spacer(minLength: 80)
        }
        .padding(.horizontal, 16)
    }

    private var achievementsOverviewCard: some View {
        let totalTrophies = trophySections.flatMap(\.trophies).count

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("成果")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(achievedTrophies.count) / \(totalTrophies) 個のトロフィーを獲得")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                NavigationLink {
                    TrophyView()
                } label: {
                    HStack(spacing: 2) {
                        Text("トロフィーを見る")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .foregroundColor(theme.primaryColor)
                }
            }

            HStack(spacing: 10) {
                statCapsule(title: "自己ベスト", value: "\(personalBestItems.count)項目")
                statCapsule(title: "最長連続", value: "\(bestStreak())日")
                statCapsule(title: "累計記録", value: "\(allRecords.count)回")
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func statCapsule(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.primaryColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private var periodNavigator: some View {
        HStack {
            Button {
                currentDate = previousPeriodDate()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(theme.primaryColor)
            }

            Spacer()

            Text(periodTitle)
                .font(.headline)

            Spacer()

            Button {
                if let next = nextPeriodDate(), next <= Date() { currentDate = next }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(nextPeriodDate().map { $0 <= Date() } == true ? theme.primaryColor : .secondary.opacity(0.4))
            }
            .disabled(nextPeriodDate().map { $0 <= Date() } != true)
        }
        .padding(12)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var periodTitle: String {
        switch selectedPeriod {
        case 0:
            let interval = weekInterval(containing: currentDate)
            return "\(shortDateLabel(interval.start)) 〜 \(shortDateLabel(calendar.date(byAdding: .day, value: -1, to: interval.end)!))"
        case 2:
            return "\(calendar.component(.year, from: currentDate))年"
        default:
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            return "\(year)年\(month)月"
        }
    }

    private var summaryCards: some View {
        let records = periodRecords()
        let count = records.count
        let dist = records.reduce(0.0) { $0 + $1.distanceKm }
        let dur = records.reduce(0) { $0 + $1.durationSeconds }
        let kcal = records.compactMap { $0.caloriesKcal }.reduce(0, +)
        let speed = dur > 0 ? dist / (Double(dur) / 3600.0) : 0

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            summaryCard(icon: "figure.walk.circle.fill", value: formatHours(dur), unit: "", label: "運動時間")
            summaryCard(icon: "flame.fill", value: "\(Int(kcal))", unit: "kcal", label: "消費カロリー")
            summaryCard(icon: "speedometer", value: String(format: "%.1f", speed), unit: "km/h", label: "平均速度")
            summaryCard(icon: "calendar", value: "\(count)", unit: "回", label: "ジムに行った回数")
        }
    }

    private func summaryCard(icon: String, value: String, unit: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(theme.primaryColor)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    private var personalBestItems: [PersonalBestItem] {
        var items: [PersonalBestItem] = []

        if let longestDistance = allRecords.max(by: { $0.distanceKm < $1.distanceKm }) {
            items.append(
                PersonalBestItem(
                    title: "最長距離",
                    value: String(format: "%.2f km", longestDistance.distanceKm),
                    icon: "figure.run",
                    record: longestDistance
                )
            )
        }

        if let longestDuration = allRecords.max(by: { $0.durationSeconds < $1.durationSeconds }) {
            items.append(
                PersonalBestItem(
                    title: "最長時間",
                    value: longestDuration.durationFormatted,
                    icon: "clock",
                    record: longestDuration
                )
            )
        }

        if let fastestPace = allRecords
            .filter({ $0.distanceKm > 0 && $0.durationSeconds > 0 })
            .min(by: { ($0.paceMinPerKm ?? .greatestFiniteMagnitude) < ($1.paceMinPerKm ?? .greatestFiniteMagnitude) }) {
            items.append(
                PersonalBestItem(
                    title: "最速ペース",
                    value: fastestPace.paceFormatted ?? "-",
                    icon: "speedometer",
                    record: fastestPace
                )
            )
        }

        return items
    }

    private var personalBestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("自己ベスト")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("タップで記録を見る")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if personalBestItems.isEmpty {
                Text("記録が増えると、ここにベストが並びます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(personalBestItems) { item in
                        NavigationLink {
                            RecordDetailView(record: item.record)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(theme.primaryColor)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(item.value)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                Spacer()

                                Text(shortDateLabel(item.record.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var distanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("距離（km）")
                .font(.subheadline)
                .fontWeight(.medium)

            Chart(periodRecords()) { record in
                BarMark(
                    x: .value("日", record.date, unit: selectedPeriod == 2 ? .month : .day),
                    y: .value("距離", record.distanceKm)
                )
                .foregroundStyle(theme.primaryColor.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: axisMarks) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(axisLabel(date))
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
        let start = periodStart(containing: currentDate)
        let end = periodEnd(after: start)
        return allRecords.filter { $0.date >= start && $0.date < end }
    }

    private func previousPeriodDate() -> Date {
        switch selectedPeriod {
        case 0:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)!
        case 2:
            return calendar.date(byAdding: .year, value: -1, to: currentDate)!
        default:
            return calendar.date(byAdding: .month, value: -1, to: currentDate)!
        }
    }

    private func nextPeriodDate() -> Date? {
        switch selectedPeriod {
        case 0:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)
        case 2:
            return calendar.date(byAdding: .year, value: 1, to: currentDate)
        default:
            return calendar.date(byAdding: .month, value: 1, to: currentDate)
        }
    }

    private func periodStart(containing date: Date) -> Date {
        switch selectedPeriod {
        case 0:
            return weekInterval(containing: date).start
        case 2:
            return calendar.date(from: calendar.dateComponents([.year], from: date))!
        default:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        }
    }

    private func periodEnd(after start: Date) -> Date {
        switch selectedPeriod {
        case 0:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
        case 2:
            return calendar.date(byAdding: .year, value: 1, to: start)!
        default:
            return calendar.date(byAdding: .month, value: 1, to: start)!
        }
    }

    private func weekInterval(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 7 * 24 * 60 * 60)
    }

    private func currentStreak() -> Int {
        let recordDates = Set(allRecords.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        while recordDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
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

    private var axisMarks: AxisMarkValues {
        selectedPeriod == 2 ? .stride(by: .month, count: 2) : .stride(by: .day, count: selectedPeriod == 0 ? 1 : 5)
    }

    private func axisLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = selectedPeriod == 2 ? "M月" : "M/d"
        return f.string(from: date)
    }

    private func shortDateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}

private struct PersonalBestItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let record: WorkoutRecord
}
