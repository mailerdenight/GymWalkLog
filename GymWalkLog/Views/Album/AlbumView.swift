import SwiftUI
import SwiftData

struct AlbumView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]

    var theme: AppTheme { appSettings.theme }
    private let calendar = Calendar.current

    private var recordsWithPhotos: [WorkoutRecord] {
        records.filter { $0.photoData1 != nil || $0.photoData2 != nil || $0.photoData3 != nil }
    }

    private var groupedByMonth: [(String, [WorkoutRecord])] {
        var seen: [String: Date] = [:]
        let grouped = Dictionary(grouping: recordsWithPhotos) { record -> String in
            let c = calendar.dateComponents([.year, .month], from: record.date)
            let key = "\(c.year!)年\(c.month!)月"
            if seen[key] == nil { seen[key] = record.date }
            return key
        }
        return grouped.sorted { a, b in (seen[a.0] ?? .distantPast) > (seen[b.0] ?? .distantPast) }
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
            VStack(alignment: .leading, spacing: 24) {
                ForEach(groupedByMonth, id: \.0) { month, monthRecords in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(month)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)

                        let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
                        LazyVGrid(columns: cols, spacing: 2) {
                            ForEach(photoItems(from: monthRecords)) { item in
                                NavigationLink(destination: RecordDetailView(record: item.record)) {
                                    Image(uiImage: item.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: UIScreen.main.bounds.width / 3)
                                        .clipped()
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
    }

    private struct PhotoItem: Identifiable {
        let id = UUID()
        let image: UIImage
        let record: WorkoutRecord
    }

    private func photoItems(from records: [WorkoutRecord]) -> [PhotoItem] {
        records.flatMap { record -> [PhotoItem] in
            [record.photoData1, record.photoData2, record.photoData3]
                .compactMap { $0 }
                .compactMap { UIImage(data: $0) }
                .map { PhotoItem(image: $0, record: record) }
        }
    }
}
