import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    @State private var showNewRecord = false
    @State private var showProUpgrade = false
    @State private var showSettings = false

    var theme: AppTheme { appSettings.theme }

    private var calendar: Calendar { Calendar.current }

    private var currentMonthRecords: [WorkoutRecord] {
        let now = Date()
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return records.filter { $0.date >= start }
    }

    private var totalDistanceKm: Double {
        currentMonthRecords.reduce(0) { $0 + $1.distanceKm }
    }

    private var totalDurationSeconds: Int {
        currentMonthRecords.reduce(0) { $0 + $1.durationSeconds }
    }

    private var totalCalories: Double {
        currentMonthRecords.compactMap { $0.caloriesKcal }.reduce(0, +)
    }

    private var streakDays: Int {
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        while true {
            let hasRecord = records.contains {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if hasRecord {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    private var daysSinceLastRecord: Int? {
        guard let last = records.map(\.date).max() else { return nil }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: Date())).day
    }

    private var shouldShowReturnEncouragement: Bool {
        (daysSinceLastRecord ?? 0) >= 14
    }

    private var greetingText: String {
        let hour = calendar.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "おはようございます 🌱"
        case 12..<17: return "今日もおつかれさまです 🌿"
        case 17..<21: return "今日もおつかれさまです 🌿"
        default: return "ゆっくり休んでください 🌙"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if shouldShowReturnEncouragement {
                        returnEncouragementView
                    } else {
                        greetingCard
                        monthlyStatsCard
                        streakCard
                        miniCalendarCard
                        recentRecordsCard
                    }

                    if records.count >= 30 && !appSettings.isPro {
                        proPromotionBanner
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                newRecordButton
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .overlay(alignment: .top) { Divider() }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(theme.primaryColor)
                        Text("ジム歩走ログ")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
    }


    private var newRecordButton: some View {
        Button {
            showNewRecord = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                Text("記録をつける")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.primaryColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: theme.primaryColor.opacity(0.3), radius: 8, y: 4)
        }
        .sheet(isPresented: $showNewRecord) {
            NewRecordView()
        }
    }

    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.title3)
                .fontWeight(.medium)
            Text("自分のペースで、続けていきましょう。")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var returnEncouragementView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                ThemePlantIllustration(theme: theme, size: 54)
                Text("久しぶりですね")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("また始めるのに、遅すぎることはありません。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)

            encouragementItem(
                icon: "figure.walk",
                title: "今日は歩くだけでもOK",
                body: "10分だけでも、体と心が動きます。"
            )
            encouragementItem(
                icon: "heart.fill",
                title: "あなたのペースで大丈夫",
                body: "比べるのは、昨日の自分だけ。"
            )
            encouragementItem(
                icon: "face.smiling.fill",
                title: "続いた日を、ちゃんと残そう",
                body: "小さな一歩が、未来の自分をつくります。"
            )
        }
    }

    private func encouragementItem(icon: String, title: String, body: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(theme.primaryColor)
                .frame(width: 42)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(body)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var monthlyStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            let now = Date()
            let month = calendar.component(.month, from: now)
            let year = calendar.component(.year, from: now)
            HStack {
                Text("\(year)年\(month)月の記録")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                NavigationLink(destination: StatsView()) {
                    HStack(spacing: 2) {
                        Text("レポートを見る")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .foregroundColor(theme.primaryColor)
                }
            }

            HStack(spacing: 0) {
                statItem(value: "\(currentMonthRecords.count)", unit: "回")
                Divider().frame(height: 40)
                statItem(value: String(format: "%.1f", totalDistanceKm), unit: "km")
                Divider().frame(height: 40)
                statItem(value: formatDuration(totalDurationSeconds), unit: "h:mm")
                Divider().frame(height: 40)
                statItem(value: "\(Int(totalCalories))", unit: "kcal")
            }

            if appSettings.monthlyGoal > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("目標 \(appSettings.monthlyGoal)回")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(currentMonthRecords.count)/\(appSettings.monthlyGoal)回")
                            .font(.caption)
                            .foregroundColor(theme.primaryColor)
                    }
                    ProgressView(
                        value: Double(min(currentMonthRecords.count, appSettings.monthlyGoal)),
                        total: Double(appSettings.monthlyGoal)
                    )
                    .tint(theme.primaryColor)
                }
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func statItem(value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var streakCard: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(theme.primaryColor.opacity(0.2), lineWidth: 3)
                        .frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: min(CGFloat(streakDays) / 30, 1))
                        .stroke(theme.primaryColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(streakDays)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryColor)
                        Text("日")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("連続記録")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(streakDays > 0 ? "続けています！" : "今日から始めよう")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if streakDays >= 7 {
                        Text("いいペースです 🌿")
                            .font(.caption)
                            .foregroundColor(theme.primaryColor)
                    }
                }
                Spacer(minLength: 66)
            }

            ThemePlantIllustration(theme: theme, size: 64)
                .padding(.trailing, 6)
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var miniCalendarCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            let now = Date()
            let month = calendar.component(.month, from: now)
            Text("\(month)月")
                .font(.subheadline)
                .foregroundColor(.secondary)
            MiniCalendarView(records: records)
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var recentRecordsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近の記録")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                NavigationLink(destination: RecordListView()) {
                    Text("すべて見る")
                        .font(.caption)
                        .foregroundColor(theme.primaryColor)
                }
            }

            if records.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 32))
                        .foregroundColor(theme.primaryColor.opacity(0.5))
                    Text("まだ記録がありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("+ ボタンから最初の記録を始めましょう")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(records.prefix(3)) { record in
                    NavigationLink(destination: RecordDetailView(record: record)) {
                        RecentRecordRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var proPromotionBanner: some View {
        Button {
            showProUpgrade = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(theme.primaryColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("31件目以降も記録しませんか？")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Proにすると31件目以降も保存でき、全履歴を振り返れます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(purchaseManager.priceString)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryColor)
            }
            .padding(16)
            .background(theme.primaryColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.primaryColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }
}

struct RecentRecordRow: View {
    @EnvironmentObject var appSettings: AppSettings
    let record: WorkoutRecord

    var theme: AppTheme { appSettings.theme }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d(EEE)"
        return f
    }

    var body: some View {
        HStack(spacing: 12) {
            if let data = record.primaryPhotoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.primaryColor.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "figure.walk")
                            .foregroundColor(theme.primaryColor.opacity(0.5))
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(dateFormatter.string(from: record.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    Label(String(format: "%.2f km", record.distanceKm), systemImage: "mappin.and.ellipse")
                    Label(record.durationFormatted, systemImage: "clock")
                    if let kcal = record.caloriesKcal {
                        Label("\(Int(kcal)) kcal", systemImage: "flame")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
