import SwiftUI
import SwiftData

struct RecordListView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var allRecords: [WorkoutRecord]
    @State private var showProUpgrade = false

    var theme: AppTheme { appSettings.theme }

    private var visibleRecords: [WorkoutRecord] {
        appSettings.isPro ? allRecords : Array(allRecords.prefix(30))
    }

    private var groupedRecords: [(String, [WorkoutRecord])] {
        var groups: [String: [WorkoutRecord]] = [:]
        var monthStarts: [String: Date] = [:]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"

        for record in visibleRecords {
            let key = formatter.string(from: record.date)
            groups[key, default: []].append(record)
            let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: record.date)) ?? record.date
            monthStarts[key] = max(monthStarts[key] ?? .distantPast, start)
        }
        return groups.sorted { lhs, rhs in
            (monthStarts[lhs.0] ?? .distantPast) > (monthStarts[rhs.0] ?? .distantPast)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allRecords.isEmpty {
                    emptyState
                } else {
                    recordsList
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("記録一覧")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(theme.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
    }

    private var recordsList: some View {
        List {
            if !appSettings.isPro && allRecords.count > 30 {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(theme.primaryColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("31件目以降の記録はProへ")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("記録一覧は直近30件まで表示しています")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("見る") { showProUpgrade = true }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.primaryColor)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(theme.primaryColor.opacity(0.06))
            }

            if !appSettings.isPro {
                Section {
                    Text("近30件まで表示しています")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .listRowBackground(Color.clear)
            }

            ForEach(groupedRecords, id: \.0) { monthKey, monthRecords in
                Section(header: Text(monthKey).font(.subheadline).fontWeight(.semibold)) {
                    ForEach(monthRecords) { record in
                        NavigationLink(destination: RecordDetailView(record: record)) {
                            RecordListRow(record: record)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(monthRecords[index])
                        }
                        WidgetDataManager.update(records: allRecords.filter { record in
                            !indexSet.contains { monthRecords[$0].id == record.id }
                        })
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryColor.opacity(0.4))
            Text("まだ記録がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("+ ボタンから最初の記録を始めましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RecordListRow: View {
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
            if let data = record.photoData1, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.primaryColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "figure.walk")
                            .font(.system(size: 18))
                            .foregroundColor(theme.primaryColor.opacity(0.5))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String(format: "%.2f km", record.distanceKm))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(record.durationFormatted)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let kcal = record.caloriesKcal {
                        Text("\(Int(kcal)) kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                if let pace = record.paceMinPerKm {
                    let mins = Int(pace)
                    let secs = Int((pace - Double(mins)) * 60)
                    Text(String(format: "%d:%02d /km", mins, secs))
                        .font(.caption)
                        .foregroundColor(theme.primaryColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
