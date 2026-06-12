import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [WorkoutRecord]
    @State private var showProUpgrade = false
    @State private var showExportAlert = false
    @State private var showDeleteConfirm = false
    @State private var showResetProfileConfirm = false
    @State private var treadmillProfile = TreadmillProfile.load()
    @State private var weightText = ""
    @State private var showCalorieInfo = false
    @State private var exportErrorMessage: String? = nil

    var theme: AppTheme { appSettings.theme }

    var body: some View {
        NavigationStack {
            List {
                profileSection
                themeSection
                notificationSection
                ocrSection
                proSection
                dataSection
                aboutSection
            }
            .onAppear {
                treadmillProfile = TreadmillProfile.load()
                weightText = appSettings.bodyWeightKg == 65.0 ? "" : String(format: "%.1f", appSettings.bodyWeightKg)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
        .alert("データをエクスポート", isPresented: $showExportAlert) {
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("エクスポート機能はPro機能です。")
        }
        .alert("エクスポートできませんでした", isPresented: Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "")
        }
        .confirmationDialog("全データを削除しますか？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("すべて削除", role: .destructive) {
                for record in allRecords {
                    modelContext.delete(record)
                }
                WidgetDataManager.update(records: [])
            }
        }
        .sheet(isPresented: $showCalorieInfo) {
            calorieInfoSheet
        }
        .confirmationDialog("読み取り設定をリセットしますか？", isPresented: $showResetProfileConfirm, titleVisibility: .visible) {
            Button("リセットする", role: .destructive) {
                TreadmillProfile.reset()
                treadmillProfile = TreadmillProfile()
            }
        } message: {
            Text("マシンの表示レイアウト学習データが削除されます。次回の読み取りから再学習が始まります。")
        }
    }

    private var profileSection: some View {
        Section {
            // 性別
            HStack {
                Text("性別")
                    .font(.subheadline)
                Spacer()
                Picker("", selection: $appSettings.gender) {
                    Text("未設定").tag("")
                    Text("男性").tag("male")
                    Text("女性").tag("female")
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            // 体重
            HStack {
                Text("体重")
                    .font(.subheadline)
                Spacer()
                TextField("65", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .onChange(of: weightText) { _, v in
                        if let kg = Double(v), kg > 0 {
                            appSettings.bodyWeightKg = kg
                        }
                    }
                Text("kg")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            // 月間目標
            HStack {
                Text("月間目標")
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        if appSettings.monthlyGoal > 1 { appSettings.monthlyGoal -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(appSettings.monthlyGoal > 1 ? theme.primaryColor : .secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)

                    Text("\(appSettings.monthlyGoal)回")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 36, alignment: .center)

                    Button {
                        if appSettings.monthlyGoal < 31 { appSettings.monthlyGoal += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(appSettings.monthlyGoal < 31 ? theme.primaryColor : .secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 説明リンク
            Button {
                showCalorieInfo = true
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(theme.primaryColor)
                    Text("カロリー計算の仕組み")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

        } header: {
            Text("プロフィール")
        } footer: {
            Text("体重は消費カロリーの推計に使用します（任意）。月間目標はホーム画面の進捗バーに反映されます。")
                .font(.caption2)
        }
    }

    private var themeSection: some View {
        Section("テーマ") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AppTheme.allCases, id: \.self) { t in
                    themeCard(t)
                }
            }
            .padding(.vertical, 4)

            HStack {
                Text("明るさ")
                    .font(.subheadline)
                Spacer()
                Picker("", selection: $appSettings.brightness) {
                    ForEach(AppBrightness.allCases, id: \.self) { b in
                        Text(b.displayName).tag(b)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
    }

    private func themeCard(_ t: AppTheme) -> some View {
        Button {
            appSettings.theme = t
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(t.backgroundColor)
                        .frame(height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    appSettings.theme == t ? t.primaryColor : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    HStack(spacing: 4) {
                        Circle().fill(t.primaryColor).frame(width: 12, height: 12)
                        Circle().fill(t.secondaryColor).frame(width: 12, height: 12)
                        Circle().fill(t.accentColor).frame(width: 12, height: 12)
                    }
                }

                HStack(spacing: 4) {
                    if appSettings.theme == t {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(t.primaryColor)
                    }
                    Text(t.displayName)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var notificationSection: some View {
        Section("通知設定") {
            ForEach(NotificationSetting.allCases, id: \.self) { setting in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(setting.displayName)
                            .font(.subheadline)
                        if setting == .gentle {
                            Text("週1回のふり返り / 久しぶりのお知らせ / 先月のまとめ")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else if setting == .daily {
                            Text("毎日18:00にリマインド")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if appSettings.notificationSetting == setting {
                        Image(systemName: "checkmark")
                            .foregroundColor(theme.primaryColor)
                            .fontWeight(.semibold)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    appSettings.notificationSetting = setting
                    handleNotificationChange(setting)
                }
            }
        }
    }

    private func handleNotificationChange(_ setting: NotificationSetting) {
        let nm = NotificationManager.shared
        switch setting {
        case .off:
            nm.removeAllNotifications()
        case .gentle:
            Task {
                let granted = await nm.requestAuthorization()
                if granted { nm.scheduleGentleNotifications() }
            }
        case .daily:
            Task {
                let granted = await nm.requestAuthorization()
                if granted { nm.scheduleDailyReminder() }
            }
        }
    }

    private var proSection: some View {
        Section {
            if appSettings.isPro {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(theme.primaryColor)
                    Text("Pro版をご利用中です")
                        .font(.subheadline)
                    Spacer()
                    Text("✓")
                        .foregroundColor(theme.primaryColor)
                }
            } else {
                Button {
                    showProUpgrade = true
                } label: {
                    HStack {
                        Image(systemName: "leaf")
                            .foregroundColor(theme.primaryColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Proについて（買い切り \(purchaseManager.priceString)）")
                                .font(.subheadline)
                            Text("31件目以降の記録 / グラフ / 写真無制限 / PDF・CSV出力 / iCloud同期")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    Task { await purchaseManager.restorePurchases() }
                } label: {
                    Text("購入を復元する")
                        .font(.subheadline)
                        .foregroundColor(theme.primaryColor)
                }
            }
        } header: {
            Text("Pro")
        }
    }

    private var ocrSection: some View {
        Section {
            HStack {
                Image(systemName: "camera.viewfinder")
                    .foregroundColor(theme.primaryColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("トレッドミル読み取り")
                        .font(.subheadline)
                    Text(profileStatusText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(profileBadge)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(profileBadgeColor.opacity(0.15))
                    .foregroundColor(profileBadgeColor)
                    .clipShape(Capsule())
            }

            if treadmillProfile.hasLearned {
                Button(role: .destructive) {
                    showResetProfileConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("学習データをリセット")
                            .font(.subheadline)
                    }
                }
            }
        } header: {
            Text("写真からの自動読み取り")
        } footer: {
            Text("写真を撮るたびにトレッドミルの表示位置を学習し、2回目以降の読み取り精度が上がります。")
                .font(.caption2)
        }
    }

    private var profileStatusText: String {
        let count = treadmillProfile.minHitCount
        if count == 0 { return "まだ学習していません" }
        if count < 3  { return "学習中（\(count)回記録済み）" }
        return "学習済み（\(count)回の記録から最適化）"
    }

    private var profileBadge: String {
        let count = treadmillProfile.minHitCount
        if count == 0 { return "未学習" }
        if count < 3  { return "学習中" }
        return "学習済み"
    }

    private var profileBadgeColor: Color {
        let count = treadmillProfile.minHitCount
        if count == 0 { return .secondary }
        if count < 3  { return .orange }
        return theme.primaryColor
    }

    private var dataSection: some View {
        Section("その他") {
            Button {
                if appSettings.isPro {
                    exportData()
                } else {
                    showExportAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(theme.primaryColor)
                    Text("データをエクスポート（PDF / CSV）")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    if !appSettings.isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("すべてのデータを削除")
                        .font(.subheadline)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("このアプリについて") {
            HStack {
                Text("バージョン")
                    .font(.subheadline)
                Spacer()
                Text("1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            NavigationLink {
                helpView
            } label: {
                Text("ヘルプ・使い方")
                    .font(.subheadline)
            }
        }
    }

    private var calorieInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    infoCard(
                        icon: "function",
                        title: "計算式",
                        body: "消費カロリー = MET × 体重(kg) × 時間(h)\n\nMET（代謝当量）は運動強度を表す数値です。安静時を1とした場合の何倍のエネルギーを消費するかを示します。"
                    )

                    infoCard(
                        icon: "figure.walk",
                        title: "ペースとMETの関係",
                        body: "• 11分/km以上（ゆっくり歩き）→ MET 3.5\n• 8〜11分/km（速歩き）→ MET 5.0\n• 6〜8分/km（ジョギング）→ MET 8.0\n• 6分/km未満（ランニング）→ MET 9.0\n\nペースは入力した距離と時間から自動計算します。"
                    )

                    infoCard(
                        icon: "scalemass",
                        title: "体重が重要な理由",
                        body: "同じペース・同じ距離でも、体重が重いほどカロリー消費は大きくなります。体重入力のないトレッドミルは約70kgを仮定して計算するため、実際の体重を設定しておくことで精度が上がります。"
                    )

                    infoCard(
                        icon: "exclamationmark.triangle",
                        title: "精度の限界",
                        body: "この推計は目安です（誤差±15〜20%程度）。\n\n• 傾斜（インクライン）は考慮していません\n• 筋肉量・年齢・体脂肪率の個人差は含まれません\n• 体重と傾斜を入力できるトレッドミルの値が最も正確です"
                    )

                }
                .padding(16)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("カロリー計算の仕組み")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { showCalorieInfo = false }
                        .foregroundColor(theme.primaryColor)
                }
            }
        }
    }

    private func infoCard(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text(body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var helpView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                helpItem(title: "記録の仕方", body: "+ ボタンをタップして、距離・時間・カロリーを入力し保存します。写真は無料版で3枚まで、Proで枚数制限なく添付できます。")
                helpItem(title: "無料で使える機能", body: "30件までの記録、カレンダー、今月のレポート、連続記録を無料でご利用いただけます。記録一覧は直近30件を表示します。")
                helpItem(title: "Proとは", body: "買い切り\(purchaseManager.priceString)で、31件目以降の記録・グラフ・写真無制限・PDF/CSVエクスポート・iCloud同期が使えます。サブスクリプションはありません。")
                helpItem(title: "このアプリの考え方", body: "がんばりすぎなくていい。小さな一歩を大切に。自分のペースで続けられることが大事です。")
            }
            .padding()
        }
        .navigationTitle("ヘルプ")
        .background(theme.backgroundColor.ignoresSafeArea())
    }

    private func helpItem(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryColor)
            Text(body)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func exportData() {
        let records = allRecords.sorted { $0.date > $1.date }
        do {
            let csvURL = try makeCSVExportURL(records: records)
            let pdfURL = try makePDFExportURL(records: records)
            presentShareSheet(urls: [pdfURL, csvURL])
        } catch {
            exportErrorMessage = "書き出しファイルを作成できませんでした。空き容量を確認して、もう一度お試しください。"
        }
    }

    private func makeCSVExportURL(records: [WorkoutRecord]) throws -> URL {
        var csv = "日付,距離(km),時間(秒),カロリー(kcal),メモ\n"
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy/M/d"
        for r in records {
            let kcal = r.caloriesKcal.map { String(Int($0)) } ?? ""
            let memo = r.memo ?? ""
            csv += [
                f.string(from: r.date),
                String(r.distanceKm),
                String(r.durationSeconds),
                kcal,
                memo
            ].map(csvField).joined(separator: ",") + "\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("gymwalklog_export.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func makePDFExportURL(records: [WorkoutRecord]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("gymwalklog_export.pdf")
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let headingFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let smallFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping

        try renderer.writePDF(to: url) { context in
            var pageIndex = 0
            var y: CGFloat = 0

            func beginPage() {
                context.beginPage()
                pageIndex += 1
                y = 44
                let pageTitle = pageIndex == 1 ? "ジム歩走ログ エクスポート" : "ジム歩走ログ"
                pageTitle.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: titleFont])
                y += 34
                let generated = "作成日: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
                generated.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: smallFont, .foregroundColor: UIColor.secondaryLabel])
                y += 24
            }

            func ensureSpace(_ height: CGFloat) {
                if pageIndex == 0 || y + height > bounds.height - 44 {
                    beginPage()
                }
            }

            beginPage()

            for record in records {
                ensureSpace(110)

                let cardRect = CGRect(x: 36, y: y, width: bounds.width - 72, height: 96)
                let ctx = context.cgContext
                ctx.saveGState()
                UIBezierPath(roundedRect: cardRect, cornerRadius: 14).addClip()
                UIColor.secondarySystemBackground.setFill()
                UIRectFill(cardRect)
                ctx.restoreGState()

                let dateText = DateFormatter.localizedString(from: record.date, dateStyle: .medium, timeStyle: .none)
                dateText.draw(at: CGPoint(x: cardRect.minX + 16, y: cardRect.minY + 14), withAttributes: [.font: headingFont])

                let summary = [
                    "距離: \(String(format: "%.2f km", record.distanceKm))",
                    "時間: \(record.durationFormatted)",
                    "カロリー: \(record.caloriesKcal.map { "\(Int($0.rounded())) kcal" } ?? "-")"
                ].joined(separator: "   ")
                summary.draw(
                    in: CGRect(x: cardRect.minX + 16, y: cardRect.minY + 36, width: cardRect.width - 32, height: 18),
                    withAttributes: [.font: bodyFont]
                )

                let memo = record.memo?.isEmpty == false ? record.memo! : "メモなし"
                let memoText = "メモ: \(memo)"
                memoText.draw(
                    in: CGRect(x: cardRect.minX + 16, y: cardRect.minY + 56, width: cardRect.width - 32, height: 28),
                    withAttributes: [.font: bodyFont, .paragraphStyle: paragraph, .foregroundColor: UIColor.secondaryLabel]
                )

                y = cardRect.maxY + 12
            }
        }

        return url
    }

    private func presentShareSheet(urls: [URL]) {
        let vc = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }

    private func csvField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}
