import SwiftData
import Foundation

@Model
final class WorkoutRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var startTime: Date?
    var endTime: Date?
    var durationSeconds: Int = 0
    var distanceKm: Double = 0
    var caloriesKcal: Double?
    var memo: String?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutPhoto.record) var photos: [WorkoutPhoto] = []
    var photoData1: Data?
    var photoData2: Data?
    var photoData3: Data?
    var workoutType: String = "walk"

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        startTime: Date? = nil,
        endTime: Date? = nil,
        durationSeconds: Int = 0,
        distanceKm: Double = 0,
        caloriesKcal: Double? = nil,
        memo: String? = nil,
        photos: [WorkoutPhoto] = [],
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
        self.photos = photos
        self.photoData1 = photoData1
        self.photoData2 = photoData2
        self.photoData3 = photoData3
        self.workoutType = workoutType
    }

    var paceMinPerKm: Double? {
        guard distanceKm > 0, durationSeconds > 0 else { return nil }
        return Double(durationSeconds) / 60.0 / distanceKm
    }

    var averageSpeedKmh: Double? {
        guard distanceKm > 0, durationSeconds > 0 else { return nil }
        return distanceKm / (Double(durationSeconds) / 3600.0)
    }

    var durationFormatted: String {
        let h = durationSeconds / 3600
        let m = (durationSeconds % 3600) / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    var paceFormatted: String? {
        guard let paceMinPerKm else { return nil }
        let totalSeconds = Int((paceMinPerKm * 60).rounded())
        return String(format: "%d:%02d /km", totalSeconds / 60, totalSeconds % 60)
    }

    var photoDataList: [Data] {
        let modernPhotos = photos
            .sorted { lhs, rhs in
                if lhs.orderIndex == rhs.orderIndex {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.orderIndex < rhs.orderIndex
            }
            .map(\.data)
        if !modernPhotos.isEmpty {
            return modernPhotos
        }
        return [photoData1, photoData2, photoData3].compactMap { $0 }
    }

    var primaryPhotoData: Data? {
        photoDataList.first
    }
}

@Model
final class WorkoutPhoto {
    var id: UUID = UUID()
    var data: Data = Data()
    var orderIndex: Int = 0
    var createdAt: Date = Date()
    var record: WorkoutRecord?

    init(
        id: UUID = UUID(),
        data: Data,
        orderIndex: Int,
        createdAt: Date = Date(),
        record: WorkoutRecord? = nil
    ) {
        self.id = id
        self.data = data
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.record = record
    }
}
