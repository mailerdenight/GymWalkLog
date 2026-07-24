import Foundation

typealias WorkoutRecord = GymWalkLogSchemaV3.WorkoutRecord
typealias WorkoutPhoto = GymWalkLogSchemaV3.WorkoutPhoto

extension GymWalkLogSchemaV3.WorkoutRecord {
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
        let modernPhotos = (photos ?? [])
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
