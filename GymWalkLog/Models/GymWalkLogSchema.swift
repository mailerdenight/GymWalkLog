import Foundation
import SwiftData

// Keep every released data model immutable. SwiftData identifies an existing
// store by its schema checksum, so changing an older schema in place can make an
// App Store update unable to open a customer's database.
enum GymWalkLogSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WorkoutRecord.self]
    }

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
    }
}

// Versions 1.0 (build 3) and 1.1 (build 1) shipped this model. In particular,
// `photos` was a non-optional relationship. Do not use this schema with
// CloudKit and do not edit it after release.
enum GymWalkLogSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WorkoutRecord.self, WorkoutPhoto.self]
    }

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
        @Relationship(deleteRule: .cascade, inverse: \WorkoutPhoto.record)
        var photos: [WorkoutPhoto] = []
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
}

// Version 1.2 makes every relationship optional, as required by SwiftData's
// CloudKit integration. All other stored fields retain their released names and
// types so the migration remains additive and preserves customer data.
enum GymWalkLogSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [WorkoutRecord.self, WorkoutPhoto.self]
    }

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
        @Relationship(deleteRule: .cascade, inverse: \WorkoutPhoto.record)
        var photos: [WorkoutPhoto]?
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
            photos: [WorkoutPhoto]? = nil,
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
}

enum GymWalkLogMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [GymWalkLogSchemaV1.self, GymWalkLogSchemaV2.self, GymWalkLogSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: GymWalkLogSchemaV1.self, toVersion: GymWalkLogSchemaV2.self),
            .lightweight(fromVersion: GymWalkLogSchemaV2.self, toVersion: GymWalkLogSchemaV3.self)
        ]
    }
}
