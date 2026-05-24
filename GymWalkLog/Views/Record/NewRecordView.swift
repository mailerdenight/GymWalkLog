import SwiftUI
import SwiftData
import PhotosUI

struct NewRecordView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]

    @State private var date = Date()
    @State private var startTime = Date()
    @State private var durationHoursText = "0"
    @State private var durationMinutesText = "0"
    @State private var distanceText = ""
    @State private var caloriesText = ""
    @State private var memo = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var showProPrompt = false
    @State private var showPhotoSource = false
    @State private var showCamera = false
    @State private var isAnalyzing = false
    @State private var ocrBannerText: String? = nil
    @State private var lastOCRResult: OCRResult? = nil
    @State private var validationMessage: String? = nil

    var theme: AppTheme { appSettings.theme }

    private var isAtFreeLimit: Bool {
        !appSettings.isPro && records.count >= 30
    }

    private var totalDurationSeconds: Int {
        (Int(durationHoursText) ?? 0) * 3600 + (Int(durationMinutesText) ?? 0) * 60
    }

    private var calculatedEndTime: Date {
        startTime.addingTimeInterval(TimeInterval(totalDurationSeconds))
    }

    // 距離・時間・体重から推定カロリーを計算
    private var estimatedCalories: Int? {
        guard let km = Double(distanceText), km > 0,
              totalDurationSeconds > 0 else { return nil }
        let hours = Double(totalDurationSeconds) / 3600
        let paceMinPerKm = hours * 60 / km
        let met: Double = paceMinPerKm < 6 ? 9.0
                        : paceMinPerKm < 8 ? 8.0
                        : paceMinPerKm < 11 ? 5.0
                        : 3.5
        let weight = appSettings.bodyWeightKg
        return Int(met * weight * hours)
    }

    private let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isAtFreeLimit { freePromptBanner }

                    basicInfoCard
                    photoSection

                    if isAnalyzing {
                        HStack(spacing: 8) {
                            ProgressView().tint(theme.primaryColor)
                            Text("トレッドミルの数値を読み取り中…")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(12)
                        .background(theme.cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    if let banner = ocrBannerText {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.primaryColor)
                            Text(banner).font(.caption).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                        .background(theme.primaryColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    metricsCard
                    if let validationMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text(validationMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    saveButton
                    Spacer(minLength: 40)
                }
                .padding(16)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("新しい記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }.foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showProPrompt) { ProUpgradeView() }
    }

    // MARK: - 基本情報

    private var basicInfoCard: some View {
        formRow(label: "日付") {
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
        }
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - 計測データ

    private var metricsCard: some View {
        VStack(spacing: 0) {

            // 時間（テキスト入力・秒なし）
            HStack {
                Text("時間").font(.subheadline)
                Spacer()
                HStack(spacing: 4) {
                    TextField("0", text: $durationHoursText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 36)
                        .onChange(of: durationHoursText) { _, v in
                            durationHoursText = String(v.prefix(2).filter(\.isNumber))
                        }
                    Text("時間")
                        .font(.subheadline).foregroundColor(.secondary)
                    TextField("0", text: $durationMinutesText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 36)
                        .onChange(of: durationMinutesText) { _, v in
                            let n = Int(v.filter(\.isNumber)) ?? 0
                            durationMinutesText = String(min(n, 59))
                        }
                    Text("分")
                        .font(.subheadline).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider().padding(.leading, 16)

            // 距離
            formRow(label: "距離（km）") {
                TextField("3.00", text: $distanceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            Divider().padding(.leading, 16)

            // カロリー + 自動推定
            VStack(spacing: 0) {
                formRow(label: "消費カロリー（kcal）") {
                    TextField("180", text: $caloriesText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                if let est = estimatedCalories, caloriesText.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Button {
                            caloriesText = "\(est)"
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("目安 \(est) kcal を入力")
                            }
                            .font(.caption)
                            .foregroundColor(theme.primaryColor)
                        }
                        Text("※体重入力機能のないトレッドミルより精度が高い場合があります")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            Divider().padding(.leading, 16)

            // 開始時刻
            formRow(label: "開始時刻") {
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            Divider().padding(.leading, 16)

            // 終了時刻（自動計算）
            HStack {
                Text("終了時刻").font(.subheadline)
                Spacer()
                HStack(spacing: 4) {
                    Text(timeFmt.string(from: calculatedEndTime))
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("（自動）")
                        .font(.caption2).foregroundColor(theme.primaryColor.opacity(0.7))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider().padding(.leading, 16)

            // メモ
            VStack(alignment: .leading, spacing: 8) {
                Text("メモ（任意）")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding(.horizontal, 16).padding(.top, 12)
                TextField("今日の気分や一言をメモできます", text: $memo, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(.horizontal, 16).padding(.bottom, 12)
            }
        }
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - 写真

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("写真（最大3枚）")
                    .font(.subheadline).fontWeight(.medium)
                Spacer()
                Text("撮影で数値を自動読み取り")
                    .font(.caption2).foregroundColor(theme.primaryColor.opacity(0.8))
            }

            HStack(spacing: 12) {
                ForEach(Array(photoImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable().scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Button {
                            photoImages.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5).clipShape(Circle()))
                                .padding(4)
                        }
                    }
                }

                if photoImages.count < 3 {
                    Button { showPhotoSource = true } label: {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.primaryColor.opacity(0.4),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            .frame(width: 80, height: 80)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 22))
                                        .foregroundColor(theme.primaryColor)
                                    Text("追加")
                                        .font(.caption2).foregroundColor(theme.primaryColor)
                                }
                            )
                    }
                    .confirmationDialog("写真を追加", isPresented: $showPhotoSource) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button("カメラで撮影") { showCamera = true }
                        }
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 3 - photoImages.count,
                            matching: .images
                        ) {
                            Text("アルバムから選ぶ")
                        }
                        .onChange(of: selectedPhotos) { _, items in
                            Task {
                                var newImages: [UIImage] = []
                                for item in items {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let img = UIImage(data: data) {
                                        photoImages.append(img)
                                        newImages.append(img)
                                    }
                                }
                                selectedPhotos = []
                                if let first = newImages.first { analyzePhoto(first) }
                            }
                        }
                        Button("キャンセル", role: .cancel) {}
                    }
                    .sheet(isPresented: $showCamera) {
                        CameraView { image in
                            photoImages.append(image)
                            analyzePhoto(image)
                        }
                        .ignoresSafeArea()
                    }
                }
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - 保存ボタン

    private var saveButton: some View {
        Button { saveRecord() } label: {
            Text("保存する")
                .font(.headline).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(theme.primaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: theme.primaryColor.opacity(0.3), radius: 6, y: 3)
        }
    }

    // MARK: - 無料上限バナー

    private var freePromptBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 28)).foregroundColor(theme.primaryColor)
            Text("ここまで続けましたね！").font(.headline)
            Text("ジム 30回 達成！古い記録もずっと残しませんか？")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button { showProPrompt = true } label: {
                Text("Proにする（買い切り \(purchaseManager.priceString)）")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(theme.primaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Button("あとで") { }.font(.subheadline).foregroundColor(.secondary)
        }
        .padding(20).background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
    }

    // MARK: - ヘルパー

    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            content()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - OCR

    private func analyzePhoto(_ image: UIImage) {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        ocrBannerText = nil
        Task {
            let profile = TreadmillProfile.load()
            let result = await PhotoOCRManager.extractWorkoutData(from: image, profile: profile)
            await MainActor.run {
                isAnalyzing = false
                lastOCRResult = result
                var filled: [String] = []
                if let secs = result.durationSeconds, totalDurationSeconds == 0 {
                    durationHoursText   = "\(secs / 3600)"
                    durationMinutesText = "\((secs % 3600) / 60)"
                    startTime = Date().addingTimeInterval(-TimeInterval(secs))
                    filled.append("時間")
                }
                if let km = result.distanceKm, distanceText.isEmpty {
                    distanceText = String(format: "%.2f", km)
                    filled.append("距離")
                }
                if let kcal = result.caloriesKcal, caloriesText.isEmpty {
                    caloriesText = "\(Int(kcal))"
                    filled.append("カロリー")
                }
                if !filled.isEmpty {
                    let suffix = profile.minHitCount >= 3 ? "（学習済み）" : "（確認してください）"
                    ocrBannerText = "\(filled.joined(separator: "・"))を読み取りました\(suffix)"
                    Task {
                        try? await Task.sleep(for: .seconds(4))
                        await MainActor.run { ocrBannerText = nil }
                    }
                }
            }
        }
    }

    // MARK: - 保存

    private func saveRecord() {
        validationMessage = nil
        guard totalDurationSeconds > 0 else {
            validationMessage = "時間を入力してください。"
            return
        }
        guard let distance = Double(distanceText), distance > 0 else {
            validationMessage = "距離を入力してください。"
            return
        }
        let calories = Double(caloriesText)
        if let ocr = lastOCRResult, !ocr.isEmpty {
            var profile = TreadmillProfile.load()
            profile.learn(distanceBox: ocr.distanceBox, durationBox: ocr.durationBox, caloriesBox: ocr.caloriesBox)
            profile.save()
        }
        let record = WorkoutRecord(
            date: date,
            startTime: startTime,
            endTime: calculatedEndTime,
            durationSeconds: totalDurationSeconds,
            distanceKm: distance,
            caloriesKcal: calories,
            memo: memo.isEmpty ? nil : memo,
            photoData1: photoImages.count > 0 ? photoImages[0].jpegData(compressionQuality: 0.8) : nil,
            photoData2: photoImages.count > 1 ? photoImages[1].jpegData(compressionQuality: 0.8) : nil,
            photoData3: photoImages.count > 2 ? photoImages[2].jpegData(compressionQuality: 0.8) : nil,
            workoutType: "walk"
        )
        modelContext.insert(record)
        WidgetDataManager.update(records: [record] + records)
        if appSettings.notificationSetting == .gentle {
            NotificationManager.shared.rescheduleAbsenceReminder(lastWorkoutDate: date)
        }
        dismiss()
    }
}
