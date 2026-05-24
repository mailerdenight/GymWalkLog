import SwiftUI
import SwiftData

struct RecordDetailView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    let record: WorkoutRecord

    @State private var memo: String = ""
    @State private var showDeleteConfirm = false

    var theme: AppTheme { appSettings.theme }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy/M/d(EEE) HH:mm"
        return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !record.photoDataList.isEmpty {
                    photoSection
                }

                detailsCard
                memoCard

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text("削除する")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .navigationTitle(dateFormatter.string(from: record.date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { saveMemo() }
                    .foregroundColor(theme.primaryColor)
            }
        }
        .onAppear { memo = record.memo ?? "" }
        .confirmationDialog("この記録を削除しますか？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                modelContext.delete(record)
                WidgetDataManager.update(records: records.filter { $0.id != record.id })
                dismiss()
            }
        }
    }

    private var photoSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(record.photoDataList.enumerated()), id: \.offset) { _, data in
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 220, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "clock", label: "時間", value: record.durationFormatted)
            Divider().padding(.leading, 52)
            detailRow(icon: "mappin.and.ellipse", label: "距離", value: String(format: "%.2f km", record.distanceKm))
            if let kcal = record.caloriesKcal {
                Divider().padding(.leading, 52)
                detailRow(icon: "flame", label: "消費カロリー", value: "\(Int(kcal)) kcal")
            }
            if let pace = record.paceMinPerKm {
                Divider().padding(.leading, 52)
                let mins = Int(pace)
                let secs = Int((pace - Double(mins)) * 60)
                detailRow(icon: "speedometer", label: "平均ペース", value: String(format: "%d:%02d /km", mins, secs))
            }
        }
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.primaryColor)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var memoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ（任意）")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            TextField("今日の気分や一言をメモできます", text: $memo, axis: .vertical)
                .lineLimit(3...8)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func saveMemo() {
        record.memo = memo.isEmpty ? nil : memo
        dismiss()
    }
}
