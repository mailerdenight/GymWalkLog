import SwiftUI
import SwiftData

struct RecordListView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var allRecords: [WorkoutRecord]
    @State private var showProUpgrade = false
    @State private var sortOrder: RecordSortOrder = .newest
    @State private var deleteErrorMessage: String?

    var theme: AppTheme { appSettings.theme }

    private var visibleRecords: [WorkoutRecord] {
        let limited = appSettings.isPro ? allRecords : Array(allRecords.prefix(30))
        return limited.sorted {
            sortOrder == .newest ? $0.date > $1.date : $0.date < $1.date
        }
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
            if monthStarts[key] == nil { monthStarts[key] = start }
        }
        return groups.sorted { lhs, rhs in
            sortOrder == .newest
                ? (monthStarts[lhs.0] ?? .distantPast) > (monthStarts[rhs.0] ?? .distantPast)
                : (monthStarts[lhs.0] ?? .distantPast) < (monthStarts[rhs.0] ?? .distantPast)
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
                    Menu {
                        ForEach(RecordSortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                Label(order.title, systemImage: sortOrder == order ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label(sortOrder.title, systemImage: "arrow.up.arrow.down")
                            .labelStyle(.iconOnly)
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
        .alert("削除できませんでした", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "")
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

            ForEach(groupedRecords, id: \.0) { monthKey, monthRecords in
                Section(header: Text(monthKey).font(.subheadline).fontWeight(.semibold)) {
                    ForEach(monthRecords) { record in
                        NavigationLink(destination: RecordDetailView(record: record)) {
                            RecordListRow(record: record)
                        }
                    }
                    .onDelete { indexSet in
                        let deletedIDs = Set(indexSet.map { monthRecords[$0].id })
                        let remainingRecords = allRecords.filter { !deletedIDs.contains($0.id) }
                        for index in indexSet {
                            modelContext.delete(monthRecords[index])
                        }
                        do {
                            try modelContext.save()
                            WidgetDataManager.update(records: remainingRecords)
                            Task {
                                await NotificationManager.shared.refreshNotifications(
                                    for: appSettings.notificationSetting,
                                    lastWorkoutDate: remainingRecords.map(\.endTime).compactMap { $0 }.max() ?? remainingRecords.map(\.date).max()
                                )
                            }
                        } catch {
                            modelContext.rollback()
                            deleteErrorMessage = "記録を削除できませんでした。通信状況や空き容量を確認して、もう一度お試しください。"
                        }
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

private enum RecordSortOrder: CaseIterable {
    case newest
    case oldest

    var title: String {
        switch self {
        case .newest: return "新しい順"
        case .oldest: return "古い順"
        }
    }
}

struct RecordListRow: View {
    @EnvironmentObject var appSettings: AppSettings
    let record: WorkoutRecord

    var theme: AppTheme { appSettings.theme }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d(EEE)"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            if let data = record.primaryPhotoData, let uiImage = UIImage(data: data) {
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

            VStack(alignment: .leading, spacing: 6) {
                Text(Self.dateFormatter.string(from: record.date))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryColor)

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
                if let speed = record.averageSpeedKmh {
                    Text(String(format: "%.1f km/h", speed))
                        .font(.caption)
                        .foregroundColor(theme.primaryColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
