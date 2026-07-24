import Foundation
import OSLog
import SwiftData

struct LegacyStoreRecoveryResult {
    let importedRecordCount: Int
    let importedPhotoCount: Int

    static let notNeeded = LegacyStoreRecoveryResult(
        importedRecordCount: 0,
        importedPhotoCount: 0
    )
}

enum LegacyStoreRecovery {
    private static let appGroupID = "group.com.gymwalklog.app"
    private static let completionKey = "legacyStoreRecovery.appLocalToAppGroup.v1.completed"
    private static let logger = Logger(
        subsystem: "com.gymwalklog.app",
        category: "LegacyStoreRecovery"
    )

    static func recoverIfNeeded(
        into destinationContainer: ModelContainer,
        schema: Schema
    ) throws -> LegacyStoreRecoveryResult {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: completionKey) else {
            return .notNeeded
        }

        let fileManager = FileManager.default
        let legacyStoreURL = try appLocalStoreURL(fileManager: fileManager)
        guard fileManager.fileExists(atPath: legacyStoreURL.path) else {
            defaults.set(true, forKey: completionKey)
            return .notNeeded
        }

        guard let destinationStoreURL = destinationContainer.configurations.first?.url else {
            throw RecoveryError.destinationStoreUnavailable
        }
        guard legacyStoreURL.standardizedFileURL != destinationStoreURL.standardizedFileURL else {
            defaults.set(true, forKey: completionKey)
            return .notNeeded
        }

        try backupLegacyStore(
            at: legacyStoreURL,
            fileManager: fileManager
        )

        let sourceConfiguration = ModelConfiguration(
            "LegacyAppLocalStore",
            schema: schema,
            url: legacyStoreURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let sourceContainer = try ModelContainer(
            for: schema,
            migrationPlan: GymWalkLogMigrationPlan.self,
            configurations: [sourceConfiguration]
        )

        let result = try mergeRecords(
            from: sourceContainer,
            into: destinationContainer
        )
        defaults.set(true, forKey: completionKey)
        logger.notice(
            "Legacy recovery completed: \(result.importedRecordCount, privacy: .public) records and \(result.importedPhotoCount, privacy: .public) photos imported"
        )
        return result
    }

    static func openLegacyStoreIfAvailable(schema: Schema) throws -> ModelContainer? {
        let fileManager = FileManager.default
        let legacyStoreURL = try appLocalStoreURL(fileManager: fileManager)
        guard fileManager.fileExists(atPath: legacyStoreURL.path) else {
            return nil
        }

        try backupLegacyStore(
            at: legacyStoreURL,
            fileManager: fileManager
        )
        let configuration = ModelConfiguration(
            "LegacyAppLocalFallback",
            schema: schema,
            url: legacyStoreURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: GymWalkLogMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private static func appLocalStoreURL(fileManager: FileManager) throws -> URL {
        guard let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw RecoveryError.legacyStoreLocationUnavailable
        }
        return applicationSupportURL.appendingPathComponent("default.store")
    }

    private static func backupLegacyStore(
        at legacyStoreURL: URL,
        fileManager: FileManager
    ) throws {
        guard let appGroupURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw RecoveryError.appGroupUnavailable
        }

        let backupDirectory = appGroupURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("RecoveryBackups", isDirectory: true)
            .appendingPathComponent("before-1.3-app-local", isDirectory: true)
        try fileManager.createDirectory(
            at: backupDirectory,
            withIntermediateDirectories: true
        )

        for sourceURL in storeFamilyURLs(for: legacyStoreURL) {
            guard fileManager.fileExists(atPath: sourceURL.path) else { continue }
            let destinationURL = backupDirectory.appendingPathComponent(
                sourceURL.lastPathComponent
            )
            guard !fileManager.fileExists(atPath: destinationURL.path) else { continue }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }

    private static func storeFamilyURLs(for storeURL: URL) -> [URL] {
        [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm")
        ]
    }

    private static func mergeRecords(
        from sourceContainer: ModelContainer,
        into destinationContainer: ModelContainer
    ) throws -> LegacyStoreRecoveryResult {
        let sourceContext = ModelContext(sourceContainer)
        let destinationContext = ModelContext(destinationContainer)
        let sourceRecords = try sourceContext.fetch(FetchDescriptor<WorkoutRecord>())
        let destinationRecords = try destinationContext.fetch(FetchDescriptor<WorkoutRecord>())
        var destinationByID = Dictionary(
            destinationRecords.map { ($0.id, $0) },
            uniquingKeysWith: { current, _ in current }
        )
        var importedRecordCount = 0
        var importedPhotoCount = 0

        for sourceRecord in sourceRecords {
            if let destinationRecord = destinationByID[sourceRecord.id] {
                importedPhotoCount += mergeMissingData(
                    from: sourceRecord,
                    into: destinationRecord
                )
                continue
            }

            let clonedRecord = clone(record: sourceRecord)
            importedPhotoCount += clonedRecord.photos?.count ?? 0
            destinationContext.insert(clonedRecord)
            destinationByID[clonedRecord.id] = clonedRecord
            importedRecordCount += 1
        }

        if destinationContext.hasChanges {
            try destinationContext.save()
        }
        return LegacyStoreRecoveryResult(
            importedRecordCount: importedRecordCount,
            importedPhotoCount: importedPhotoCount
        )
    }

    private static func clone(record source: WorkoutRecord) -> WorkoutRecord {
        let destination = WorkoutRecord(
            id: source.id,
            date: source.date,
            startTime: source.startTime,
            endTime: source.endTime,
            durationSeconds: source.durationSeconds,
            distanceKm: source.distanceKm,
            caloriesKcal: source.caloriesKcal,
            memo: source.memo,
            photos: [],
            photoData1: source.photoData1,
            photoData2: source.photoData2,
            photoData3: source.photoData3,
            workoutType: source.workoutType
        )
        destination.photos = (source.photos ?? []).map { sourcePhoto in
            let destinationPhoto = WorkoutPhoto(
                id: sourcePhoto.id,
                data: sourcePhoto.data,
                orderIndex: sourcePhoto.orderIndex,
                createdAt: sourcePhoto.createdAt,
                record: destination
            )
            return destinationPhoto
        }
        return destination
    }

    @discardableResult
    private static func mergeMissingData(
        from source: WorkoutRecord,
        into destination: WorkoutRecord
    ) -> Int {
        if destination.startTime == nil {
            destination.startTime = source.startTime
        }
        if destination.endTime == nil {
            destination.endTime = source.endTime
        }
        if destination.durationSeconds == 0 {
            destination.durationSeconds = source.durationSeconds
        }
        if destination.distanceKm == 0 {
            destination.distanceKm = source.distanceKm
        }
        if destination.caloriesKcal == nil {
            destination.caloriesKcal = source.caloriesKcal
        }
        if destination.memo?.isEmpty != false {
            destination.memo = source.memo
        }
        if destination.photoData1 == nil {
            destination.photoData1 = source.photoData1
        }
        if destination.photoData2 == nil {
            destination.photoData2 = source.photoData2
        }
        if destination.photoData3 == nil {
            destination.photoData3 = source.photoData3
        }

        var destinationPhotos = destination.photos ?? []
        var destinationPhotoIDs = Set(destinationPhotos.map(\.id))
        var importedPhotoCount = 0
        for sourcePhoto in source.photos ?? [] where !destinationPhotoIDs.contains(sourcePhoto.id) {
            let destinationPhoto = WorkoutPhoto(
                id: sourcePhoto.id,
                data: sourcePhoto.data,
                orderIndex: sourcePhoto.orderIndex,
                createdAt: sourcePhoto.createdAt,
                record: destination
            )
            destinationPhotos.append(destinationPhoto)
            destinationPhotoIDs.insert(sourcePhoto.id)
            importedPhotoCount += 1
        }
        destination.photos = destinationPhotos
        return importedPhotoCount
    }
}

private enum RecoveryError: LocalizedError {
    case appGroupUnavailable
    case destinationStoreUnavailable
    case legacyStoreLocationUnavailable

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "安全な復元先を確認できませんでした。"
        case .destinationStoreUnavailable:
            return "現在の保存先を確認できませんでした。"
        case .legacyStoreLocationUnavailable:
            return "旧バージョンの保存先を確認できませんでした。"
        }
    }
}

enum RecordStoreIntegrity {
    static func removeLogicalDuplicates(in container: ModelContainer) throws -> Int {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<WorkoutRecord>())
        let groupedRecords = Dictionary(grouping: records, by: \.id)
        var removedCount = 0

        for duplicates in groupedRecords.values where duplicates.count > 1 {
            let survivor = duplicates.max { lhs, rhs in
                informationScore(for: lhs) < informationScore(for: rhs)
            }!

            for duplicate in duplicates where duplicate !== survivor {
                mergeMissingData(from: duplicate, into: survivor)
                context.delete(duplicate)
                removedCount += 1
            }
        }

        if context.hasChanges {
            try context.save()
        }
        return removedCount
    }

    private static func informationScore(for record: WorkoutRecord) -> Int {
        var score = (record.photos?.count ?? 0) * 10
        score += [record.photoData1, record.photoData2, record.photoData3]
            .compactMap { $0 }
            .count * 5
        score += record.memo?.isEmpty == false ? 3 : 0
        score += record.startTime == nil ? 0 : 1
        score += record.endTime == nil ? 0 : 1
        score += record.durationSeconds == 0 ? 0 : 1
        score += record.distanceKm == 0 ? 0 : 1
        score += record.caloriesKcal == nil ? 0 : 1
        return score
    }

    private static func mergeMissingData(
        from source: WorkoutRecord,
        into destination: WorkoutRecord
    ) {
        if destination.startTime == nil {
            destination.startTime = source.startTime
        }
        if destination.endTime == nil {
            destination.endTime = source.endTime
        }
        if destination.durationSeconds == 0 {
            destination.durationSeconds = source.durationSeconds
        }
        if destination.distanceKm == 0 {
            destination.distanceKm = source.distanceKm
        }
        if destination.caloriesKcal == nil {
            destination.caloriesKcal = source.caloriesKcal
        }
        if destination.memo?.isEmpty != false {
            destination.memo = source.memo
        }
        if destination.photoData1 == nil {
            destination.photoData1 = source.photoData1
        }
        if destination.photoData2 == nil {
            destination.photoData2 = source.photoData2
        }
        if destination.photoData3 == nil {
            destination.photoData3 = source.photoData3
        }

        var destinationPhotos = destination.photos ?? []
        var destinationPhotoIDs = Set(destinationPhotos.map(\.id))
        for sourcePhoto in source.photos ?? [] where !destinationPhotoIDs.contains(sourcePhoto.id) {
            let destinationPhoto = WorkoutPhoto(
                id: sourcePhoto.id,
                data: sourcePhoto.data,
                orderIndex: sourcePhoto.orderIndex,
                createdAt: sourcePhoto.createdAt,
                record: destination
            )
            destinationPhotos.append(destinationPhoto)
            destinationPhotoIDs.insert(sourcePhoto.id)
        }
        destination.photos = destinationPhotos
    }
}
