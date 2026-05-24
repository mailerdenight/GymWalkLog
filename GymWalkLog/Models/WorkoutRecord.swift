import SwiftData
import Foundation

@Model
final class WorkoutRecord {
    var id: UUID
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var durationSeconds: Int
    var distanceKm: Double
    var caloriesKcal: Double?
    var memo: String?
    var photoData1: Data?
    var photoData2: Data?
    var photoData3: Data?
    var workoutType: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        startTime: Date? = nil,
        endTime: Date? = nil,
        durationSeconds: Int = 0,
        distanceKm: Double = 0,
        caloriesKcal: Double? = nil,
        memo: String? = nil,
        photoData1: Data? = nil,
        photoData2: Data? = nil,
        photoData3: Data? = nil,
        workoutType: String = "walk"
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.distanceKm = distanceKm
        self.caloriesKcal = caloriesKcal
        self.memo = memo
        self.photoData1 = photoData1
        self.photoData2 = photoData2
        self.photoData3 = photoData3
        self.workoutType = workoutType
    }

    var paceMinPerKm: Double? {
        guard distanceKm > 0, durationSeconds > 0 else { return nil }
        return Double(durationSeconds) / 60.0 / distanceKm
    }

    var durationFormatted: String {
        let h = durationSeconds / 3600
        let m = (durationSeconds % 3600) / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    var photoDataList: [Data] {
        [photoData1, photoData2, photoData3].compactMap { $0 }
    }
}
