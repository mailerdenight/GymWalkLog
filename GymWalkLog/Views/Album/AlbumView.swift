import SwiftUI
import SwiftData

struct AlbumView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    @State private var sortOrder: AlbumSortOrder = .newest

    var theme: AppTheme { appSettings.theme }
    private let calendar = Calendar.current

    private var recordsWithPhotos: [WorkoutRecord] {
        records.filter { !$0.photoDataList.isEmpty }
    }

    private var groupedByMonth: [AlbumMonthSection] {
        var monthStarts: [String: Date] = [:]
        let grouped = Dictionary(grouping: recordsWithPhotos) { record -> String in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            let key = "\(components.year!)年\(components.month!)月"
            if monthStarts[key] == nil {
                monthStarts[key] = calendar.date(from: components) ?? record.date
            }
            return key
        }

        let sections = grouped.map { key, records in
            AlbumMonthSection(
                title: key,
                startDate: monthStarts[key] ?? .distantPast,
                items: photoItems(from: records)
            )
        }

        return sections.sorted {
            sortOrder == .newest ? $0.startDate > $1.startDate : $0.startDate < $1.startDate
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if recordsWithPhotos.isEmpty {
                    emptyState
                } else {
                    albumContent
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("アルバム")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(AlbumSortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                Label(order.title, systemImage: sortOrder == order ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(sortOrder.title)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .font(.subheadline)
                        .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryColor.opacity(0.4))
            Text("まだ写真がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("記録に写真を追加するとここに表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var albumContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(groupedByMonth) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(section.title)
                                .font(.headline)
                            Spacer()
                            NavigationLink {
                                AlbumMonthView(section: section)
                            } label: {
                                HStack(spacing: 2) {
                                    Text("すべて見る")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(section.items.prefix(12)) { item in
                                    NavigationLink(destination: RecordDetailView(record: item.record)) {
                                        VStack(spacing: 6) {
                                            Image(uiImage: item.image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 78, height: 78)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                                                )
                                            Text(item.shortDate)
                                                .font(.caption2)
                                                .foregroundColor(.primary)
                                        }
                                        .frame(width: 78)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
    }

    private func photoItems(from records: [WorkoutRecord]) -> [AlbumPhotoItem] {
        let sortedRecords = records.sorted {
            sortOrder == .newest ? $0.date > $1.date : $0.date < $1.date
        }

        return sortedRecords.flatMap { record -> [AlbumPhotoItem] in
            record.photoDataList
                .enumerated()
                .compactMap { index, data -> AlbumPhotoItem? in
                    guard let image = UIImage(data: data) else { return nil }
                    return AlbumPhotoItem(
                        id: "\(record.id.uuidString)-\(index)",
                        image: image,
                        record: record,
                        date: record.date
                    )
                }
        }
    }
}

private enum AlbumSortOrder: CaseIterable {
    case newest
    case oldest

    var title: String {
        switch self {
        case .newest: return "新しい順"
        case .oldest: return "古い順"
        }
    }
}

private struct AlbumMonthSection: Identifiable {
    var id: String { title }
    let title: String
    let startDate: Date
    let items: [AlbumPhotoItem]
}

private struct AlbumPhotoItem: Identifiable {
    let id: String
    let image: UIImage
    let record: WorkoutRecord
    let date: Date

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

private struct AlbumMonthView: View {
    @EnvironmentObject var appSettings: AppSettings
    let section: AlbumMonthSection

    var theme: AppTheme { appSettings.theme }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(section.items) { item in
                    NavigationLink(destination: RecordDetailView(record: item.record)) {
                        VStack(spacing: 6) {
                            Image(uiImage: item.image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 106)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .clipped()
                            Text(item.shortDate)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
