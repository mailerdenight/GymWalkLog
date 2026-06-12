import SwiftUI
import SwiftData
import PhotosUI

struct NewRecordView: View {
    let editingRecord: WorkoutRecord?

    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]

    @State private var date = Date()
    @State private var endTime = Date()
    @State private var durationHoursText = "0"
    @State private var durationMinutesText = "0"
    @State private var distanceText = ""
    @State private var caloriesText = ""
    @State private var memo = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var pendingPhotoImages: [UIImage] = []
    @State private var showProPrompt = false
    @State private var showCamera = false
    @State private var isAnalyzing = false
    @State private var ocrBannerText: String? = nil
    @State private var lastOCRResult: OCRResult? = nil
    @State private var validationMessage: String? = nil
    @State private var didLoadInitialValues = false

    init(record: WorkoutRecord? = nil) {
        self.editingRecord = record
    }

    var theme: AppTheme { appSettings.theme }

    private var isAtFreeLimit: Bool {
        editingRecord == nil && !appSettings.isPro && records.count >= 30
    }

    private var totalDurationSeconds: Int {
        durationSeconds(hoursText: durationHoursText, minutesText: durationMinutesText)
    }

    private var normalizedEndTime: Date {
        combinedDate(date, withTimeFrom: endTime)
    }

    private var calculatedStartTime: Date {
        normalizedEndTime.addingTimeInterval(-TimeInterval(totalDurationSeconds))
    }

    private var inputDistanceKm: Double? {
        normalizedDecimal(distanceText)
    }

    private var averageSpeedKmh: Double? {
        guard let km = inputDistanceKm, km > 0, totalDurationSeconds > 0 else { return nil }
        return km / (Double(totalDurationSeconds) / 3600.0)
    }

    private var photoLimit: Int? {
        if appSettings.isPro { return nil }
        return max(3, editingRecord?.photoDataList.count ?? 0)
    }

    private var remainingPhotoSlots: Int? {
        guard let photoLimit else { return nil }
        return max(photoLimit - photoImages.count, 0)
    }

    private var canAddMorePhotos: Bool {
        remainingPhotoSlots ?? 1 > 0
    }

    private var photoLimitDescription: String {
        if appSettings.isPro {
            return "カメラで撮った写真は、記録に追加されてiPhoneの写真アプリにも保存されます。"
        }
        return "無料版は写真3枚までです。Proにすると枚数制限なく保存できます。"
    }

    // 距離・時間・体重から推定カロリーを計算
    private var estimatedCalories: Int? {
        guard let km = normalizedDecimal(distanceText), km > 0,
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
                            Image(systemName: banner.contains("読み取れません") || banner.contains("判定できません") ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                .foregroundColor(banner.contains("読み取れません") || banner.contains("判定できません") ? .orange : theme.primaryColor)
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
            .navigationTitle(editingRecord == nil ? "新しい記録" : "記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }.foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showProPrompt) { ProUpgradeView() }
        .onAppear { loadInitialValuesIfNeeded() }
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
                            durationHoursText = String(normalizedDigits(v).prefix(2))
                        }
                    Text("時間")
                        .font(.subheadline).foregroundColor(.secondary)
                    TextField("0", text: $durationMinutesText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 36)
                        .onChange(of: durationMinutesText) { _, v in
                            let n = Int(normalizedDigits(v)) ?? 0
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

            if let speed = averageSpeedKmh {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("平均速度")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f km/h", speed))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryColor)
                    }
                    Text("距離(km) ÷ 時間(h) で計算しています。例: 3.0km ÷ 0.5時間 = 6.0km/h")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                Divider().padding(.leading, 16)
            }

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

            // 終了時刻
            formRow(label: "終了時刻") {
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            Divider().padding(.leading, 16)

            // 開始時刻（自動計算）
            HStack {
                Text("開始時刻").font(.subheadline)
                Spacer()
                HStack(spacing: 4) {
                    Text(timeFmt.string(from: calculatedStartTime))
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
            VStack(alignment: .leading, spacing: 4) {
                Text("トレッドミルの画面を撮影してください")
                    .font(.headline)
                Text(photoLimitDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                checklistRow("時間・距離・カロリーが写っている")
                checklistRow("数字がはっきり見える")
                checklistRow("画面全体が入るように四角の上へ合わせる")
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 12) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        if canAddMorePhotos {
                            showCamera = true
                        } else {
                            showProPrompt = true
                        }
                    } label: {
                        photoActionLabel(title: "カメラ", icon: "camera.fill", filled: true)
                    }
                }

                PhotosPicker(
                    selection: $selectedPhotos,
                    matching: .images
                ) {
                    photoActionLabel(title: "アルバム", icon: "photo.on.rectangle", filled: !UIImagePickerController.isSourceTypeAvailable(.camera))
                }
                .disabled(isAnalyzing)
                .onChange(of: selectedPhotos) { _, items in
                    Task {
                        var newImages: [UIImage] = []
                        for item in items {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                newImages.append(img)
                            }
                        }
                        selectedPhotos = []
                        startPhotoAnalysis(with: newImages)
                    }
                }

                .sheet(isPresented: $showCamera) {
                    CameraView { image in
                        startPhotoAnalysis(with: [image])
                    }
                    .ignoresSafeArea()
                }
            }
            .disabled(isAnalyzing)
            .opacity(isAnalyzing ? 0.72 : 1.0)

            ZStack(alignment: .topTrailing) {
                Group {
                    if let image = photoImages.first {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Group {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button {
                                    showCamera = true
                                } label: {
                                    placeholderCaptureView
                                }
                                .buttonStyle(.plain)
                            } else {
                                placeholderCaptureView
                            }
                        }
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(theme.primaryColor.opacity(photoImages.isEmpty ? 0.22 : 0.0), style: StrokeStyle(lineWidth: 1.5, dash: photoImages.isEmpty ? [6] : []))
                )
                .overlay {
                    if isAnalyzing {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial)

                            VStack(spacing: 10) {
                                ProgressView()
                                    .tint(theme.primaryColor)
                                    .scaleEffect(1.15)
                                Text("解析中…")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("写真を反映する前にトレッドミルの数値を読み取っています")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                        }
                    }
                }

                if !photoImages.isEmpty {
                    Button {
                        photoImages.removeFirst()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.45).clipShape(Circle()))
                            .padding(10)
                    }
                }
            }

            if !photoImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(photoImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Button {
                                    guard index != 0 else { return }
                                    let selected = photoImages.remove(at: index)
                                    photoImages.insert(selected, at: 0)
                                } label: {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(index == 0 ? theme.primaryColor : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    photoImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.45).clipShape(Circle()))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            if let remainingPhotoSlots, remainingPhotoSlots == 0 {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(theme.primaryColor)
                    Text("無料版の写真は3枚までです。続きを保存するにはProをご利用ください。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func photoActionLabel(title: String, icon: String, filled: Bool) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(filled ? .white : theme.primaryColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(filled ? theme.primaryColor : theme.primaryColor.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var placeholderCaptureView: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 38))
                .foregroundColor(theme.primaryColor)
            Text("画面全体が入るように撮影")
                .font(.subheadline)
                .fontWeight(.medium)
            Text("四角の上に合わせて追加すると自動で読み取りを試します")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.primaryColor.opacity(0.06))
    }

    private func checklistRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(theme.primaryColor)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
        }
    }

    // MARK: - 保存ボタン

    private var saveButton: some View {
        Button { saveRecord() } label: {
            Text(isAnalyzing ? "解析中…" : isAtFreeLimit ? "Proで記録を続ける" : editingRecord == nil ? "保存する" : "更新する")
                .font(.headline).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(theme.primaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: theme.primaryColor.opacity(0.3), radius: 6, y: 3)
        }
        .disabled(isAnalyzing)
        .opacity(isAnalyzing ? 0.7 : 1.0)
    }

    // MARK: - 無料上限バナー

    private var freePromptBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 28)).foregroundColor(theme.primaryColor)
            Text("ここまで続けましたね！").font(.headline)
            Text("無料版は30件まで記録できます。Proでこの先も続けましょう。")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button { showProPrompt = true } label: {
                Text("Proにする（買い切り \(purchaseManager.priceString)）")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(theme.primaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Button("あとで") { dismiss() }.font(.subheadline).foregroundColor(.secondary)
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

    private func durationSeconds(hoursText: String, minutesText: String) -> Int {
        let hours = Int(normalizedDigits(hoursText)) ?? 0
        let minutes = min(Int(normalizedDigits(minutesText)) ?? 0, 59)
        return hours * 3600 + minutes * 60
    }

    private func normalizedDigits(_ text: String) -> String {
        text.applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .filter(\.isNumber) ?? text.filter(\.isNumber)
    }

    private func normalizedDecimal(_ text: String) -> Double? {
        let normalized = text
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? text.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private func combinedDate(_ date: Date, withTimeFrom time: Date) -> Date {
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        return Calendar.current.date(from: dateComponents) ?? date
    }

    // MARK: - OCR

    private func startPhotoAnalysis(with images: [UIImage]) {
        guard !images.isEmpty, !isAnalyzing else { return }
        let acceptedImages: [UIImage]
        if let remainingPhotoSlots {
            guard remainingPhotoSlots > 0 else {
                validationMessage = "無料版の写真は3枚までです。"
                showProPrompt = true
                return
            }
            acceptedImages = Array(images.prefix(remainingPhotoSlots))
            if acceptedImages.count < images.count {
                validationMessage = "無料版では写真は3枚まで保存できます。追加分は反映されません。"
                showProPrompt = true
            }
        } else {
            acceptedImages = images
        }
        guard !acceptedImages.isEmpty else { return }
        pendingPhotoImages = acceptedImages
        analyzePhoto(acceptedImages[0])
    }

    private func analyzePhoto(_ image: UIImage) {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        ocrBannerText = nil
        Task {
            let analysisStart = ContinuousClock.now
            let profile = TreadmillProfile.load()
            let result = await PhotoOCRManager.extractWorkoutData(from: image, profile: profile)
            let minimumDisplayTime: Duration = .seconds(1.2)
            let elapsed = analysisStart.duration(to: .now)
            if elapsed < minimumDisplayTime {
                try? await Task.sleep(for: minimumDisplayTime - elapsed)
            }
            await MainActor.run {
                isAnalyzing = false
                if !pendingPhotoImages.isEmpty {
                    photoImages = pendingPhotoImages + photoImages
                    pendingPhotoImages.removeAll()
                }
                lastOCRResult = result
                var filled: [String] = []
                if let secs = result.durationSeconds, totalDurationSeconds == 0 {
                    durationHoursText   = "\(secs / 3600)"
                    durationMinutesText = "\((secs % 3600) / 60)"
                    endTime = Date()
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
                } else if result.recognizedTextCount > 0 {
                    ocrBannerText = "文字は検出しましたが、距離・時間・カロリーとして判定できませんでした。正面から明るく撮り直すか、手入力してください。"
                } else {
                    ocrBannerText = "文字を検出できませんでした。画面全体が入るように明るく撮り直すか、手入力してください。"
                }
            }
        }
    }

    private func loadInitialValuesIfNeeded() {
        guard !didLoadInitialValues, let record = editingRecord else { return }
        didLoadInitialValues = true

        date = record.date
        endTime = record.endTime ?? record.date
        durationHoursText = "\(record.durationSeconds / 3600)"
        durationMinutesText = "\((record.durationSeconds % 3600) / 60)"
        distanceText = String(format: "%.2f", record.distanceKm)
        if let calories = record.caloriesKcal {
            caloriesText = "\(Int(calories.rounded()))"
        }
        memo = record.memo ?? ""
        photoImages = record.photoDataList.compactMap { UIImage(data: $0) }
    }

    private func replaceRecordPhotos(for record: WorkoutRecord) {
        for photo in record.photos {
            modelContext.delete(photo)
        }
        record.photos.removeAll()
        record.photoData1 = nil
        record.photoData2 = nil
        record.photoData3 = nil

        for (index, image) in photoImages.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            let photo = WorkoutPhoto(data: data, orderIndex: index, record: record)
            modelContext.insert(photo)
            record.photos.append(photo)
        }
    }

    // MARK: - 保存

    private func saveRecord() {
        validationMessage = nil
        guard !isAtFreeLimit else {
            showProPrompt = true
            return
        }
        guard totalDurationSeconds > 0 else {
            validationMessage = "時間を入力してください。"
            return
        }
        guard let distance = normalizedDecimal(distanceText), distance > 0 else {
            validationMessage = "距離を入力してください。"
            return
        }
        let calories = normalizedDecimal(caloriesText)
        if let ocr = lastOCRResult, !ocr.isEmpty {
            var profile = TreadmillProfile.load()
            profile.learn(distanceBox: ocr.distanceBox, durationBox: ocr.durationBox, caloriesBox: ocr.caloriesBox)
            profile.save()
        }
        let target = editingRecord ?? WorkoutRecord()
        target.date = Calendar.current.startOfDay(for: date)
        target.startTime = calculatedStartTime
        target.endTime = normalizedEndTime
        target.durationSeconds = totalDurationSeconds
        target.distanceKm = distance
        target.caloriesKcal = calories
        target.memo = memo.isEmpty ? nil : memo
        target.workoutType = editingRecord?.workoutType ?? "walk"

        if editingRecord == nil {
            modelContext.insert(target)
        }
        replaceRecordPhotos(for: target)
        do {
            try modelContext.save()
        } catch {
            validationMessage = "保存できませんでした。もう一度お試しください。"
            return
        }
        WidgetDataManager.update(records: editingRecord == nil ? [target] + records : records)
        if appSettings.notificationSetting == .gentle {
            NotificationManager.shared.rescheduleAbsenceReminder(lastWorkoutDate: normalizedEndTime)
        }
        dismiss()
    }
}
