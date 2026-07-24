import CloudKit
import CoreData
import OSLog
import SwiftData
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }
}

@main
struct GymWalkLogApp: App {
    private static let appGroupID = "group.com.gymwalklog.app"
    private static let cloudContainerID = "iCloud.com.gymwalklog.app"
    private static let logger = Logger(subsystem: "com.gymwalklog.app", category: "Persistence")

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appSettings: AppSettings
    @StateObject private var purchaseManager: PurchaseManager
    @State private var modelContainer: ModelContainer
    @State private var persistenceStatus: PersistenceStatus
    @State private var recoveredRecordCount: Int
    @State private var legacyFallbackMessage: String?

    init() {
        let settings = AppSettings()
        let persistence = Self.makeModelContainer(useCloud: settings.isPro)
        settings.cloudSyncStatus = Self.initialCloudSyncStatus(
            isPro: settings.isPro,
            persistenceStatus: persistence.status
        )
        _appSettings = StateObject(wrappedValue: settings)
        _purchaseManager = StateObject(wrappedValue: PurchaseManager(appSettings: settings))
        _modelContainer = State(initialValue: persistence.container)
        _persistenceStatus = State(initialValue: persistence.status)
        _recoveredRecordCount = State(
            initialValue: persistence.recoveryResult.importedRecordCount
        )
        if case .legacyFallback(let message) = persistence.status {
            _legacyFallbackMessage = State(initialValue: message)
        } else {
            _legacyFallbackMessage = State(initialValue: nil)
        }
        _ = settings.firstLaunchDate
    }

    private static func makeModelContainer(useCloud: Bool) -> PersistenceResult {
        let schema = Schema(versionedSchema: GymWalkLogSchemaV3.self)
        do {
            let container: ModelContainer
            let status: PersistenceStatus
            if useCloud {
                do {
                    container = try persistentContainer(schema: schema, useCloud: true)
                    status = .cloudConfigured
                } catch {
                    logger.error("CloudKit-backed store could not be opened: \(error.localizedDescription, privacy: .public)")
                    container = try persistentContainer(schema: schema, useCloud: false)
                    status = .localAfterCloudFailure(
                        "iCloud同期を開始できなかったため、記録は引き続きこの端末内に安全に保存しています。次回の起動時に自動で再試行します。"
                    )
                }
            } else {
                container = try persistentContainer(schema: schema, useCloud: false)
                status = .localOnly
            }

            let recoveryResult = try LegacyStoreRecovery.recoverIfNeeded(
                into: container,
                schema: schema
            )
            let removedDuplicateCount = try RecordStoreIntegrity.removeLogicalDuplicates(
                in: container
            )
            if removedDuplicateCount > 0 {
                logger.notice(
                    "Removed \(removedDuplicateCount, privacy: .public) duplicate records after recovery"
                )
            }
            return PersistenceResult(
                container: container,
                status: status,
                recoveryResult: recoveryResult
            )
        } catch {
            logger.fault("Persistent store recovery failed: \(error.localizedDescription, privacy: .public)")
            do {
                if let legacyContainer = try LegacyStoreRecovery.openLegacyStoreIfAvailable(
                    schema: schema
                ) {
                    return PersistenceResult(
                        container: legacyContainer,
                        status: .legacyFallback(
                            message: "旧バージョンの保存先から記録を読み込みました。記録は利用できます。安全な統合は次回の起動時に自動で再試行します。"
                        ),
                        recoveryResult: .notNeeded
                    )
                }
            } catch {
                logger.fault("Legacy fallback store could not be opened: \(error.localizedDescription, privacy: .public)")
            }
            return makeRecoveryRequiredContainer(
                schema: schema,
                message: "過去の記録を安全に読み込めなかったため、データを変更せず停止しました。アプリを削除せず、「もう一度確認」を押してください。改善しない場合も再インストールはしないでください。"
            )
        }
    }

    private static func persistentContainer(schema: Schema, useCloud: Bool) throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupID),
            cloudKitDatabase: useCloud ? .private(cloudContainerID) : .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: GymWalkLogMigrationPlan.self,
            configurations: [config]
        )
    }

    private static func makeRecoveryRequiredContainer(
        schema: Schema,
        message: String
    ) -> PersistenceResult {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: GymWalkLogMigrationPlan.self,
                configurations: [config]
            )
            return PersistenceResult(
                container: container,
                status: .recoveryRequired(message: message),
                recoveryResult: .notNeeded
            )
        } catch {
            fatalError("復元待機画面の作成に失敗しました: \(error.localizedDescription)")
        }
    }

    private static func initialCloudSyncStatus(
        isPro: Bool,
        persistenceStatus: PersistenceStatus
    ) -> CloudSyncStatus {
        guard isPro else { return .unavailableForFree }
        switch persistenceStatus {
        case .cloudConfigured:
            return .checkingAccount
        case .localOnly, .legacyFallback:
            return .localOnly
        case .localAfterCloudFailure(let message), .recoveryRequired(let message):
            return .failed(message: message)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if case .recoveryRequired(let message) = persistenceStatus {
                    DataRecoveryRequiredView(message: message) {
                        retryPersistence()
                    }
                } else {
                    MainTabView()
                        .environmentObject(appSettings)
                        .environmentObject(purchaseManager)
                        .modelContainer(modelContainer)
                        .onChange(of: appSettings.isPro) { _, isPro in
                            if isPro {
                                if persistenceStatus != .cloudConfigured {
                                    appSettings.cloudSyncStatus = .activationPending
                                }
                            } else {
                                appSettings.cloudSyncStatus = .unavailableForFree
                            }
                        }
                        .task {
                            await refreshCloudStatus()
                        }
                        .onReceive(NotificationCenter.default.publisher(
                            for: NSPersistentCloudKitContainer.eventChangedNotification
                        )) { notification in
                            handleCloudKitEvent(notification)
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .CKAccountChanged)) { _ in
                            Task { await refreshCloudStatus() }
                        }
                        .alert("記録を復元しました", isPresented: recoveredRecordsAlertBinding) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text("旧バージョンに保存されていた\(recoveredRecordCount)件の記録を復元しました。")
                        }
                        .alert("記録を一時復旧しました", isPresented: legacyFallbackAlertBinding) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text(legacyFallbackMessage ?? "")
                        }
                }
            }
            .environmentObject(appSettings)
            .preferredColorScheme(appSettings.preferredColorScheme)
        }
    }

    private var recoveredRecordsAlertBinding: Binding<Bool> {
        Binding(
            get: { recoveredRecordCount > 0 },
            set: {
                if !$0 {
                    recoveredRecordCount = 0
                }
            }
        )
    }

    private var legacyFallbackAlertBinding: Binding<Bool> {
        Binding(
            get: { legacyFallbackMessage != nil },
            set: {
                if !$0 {
                    legacyFallbackMessage = nil
                }
            }
        )
    }

    private func retryPersistence() {
        let persistence = Self.makeModelContainer(useCloud: appSettings.isPro)
        modelContainer = persistence.container
        persistenceStatus = persistence.status
        recoveredRecordCount = persistence.recoveryResult.importedRecordCount
        if case .legacyFallback(let message) = persistence.status {
            legacyFallbackMessage = message
        } else {
            legacyFallbackMessage = nil
        }
        appSettings.cloudSyncStatus = Self.initialCloudSyncStatus(
            isPro: appSettings.isPro,
            persistenceStatus: persistence.status
        )
    }

    @MainActor
    private func refreshCloudStatus() async {
        guard appSettings.isPro, persistenceStatus == .cloudConfigured else { return }
        appSettings.cloudSyncStatus = .checkingAccount
        do {
            let status = try await CKContainer(identifier: Self.cloudContainerID).accountStatus()
            switch status {
            case .available:
                appSettings.cloudSyncStatus = .syncing
            case .noAccount:
                appSettings.cloudSyncStatus = .failed(
                    message: "iPhoneの設定でApple Accountにサインインし、iCloud Driveを有効にしてください。記録はこの端末にも保存されています。"
                )
            case .restricted:
                appSettings.cloudSyncStatus = .failed(
                    message: "この端末ではiCloudの利用が制限されています。記録はこの端末にも保存されています。"
                )
            case .temporarilyUnavailable:
                appSettings.cloudSyncStatus = .failed(
                    message: "iCloudは一時的に利用できません。記録はこの端末にも保存され、接続が戻ると自動で同期されます。"
                )
            case .couldNotDetermine:
                appSettings.cloudSyncStatus = .failed(
                    message: "iCloudの状態を確認できませんでした。記録はこの端末にも保存され、次回起動時に再確認します。"
                )
            @unknown default:
                appSettings.cloudSyncStatus = .failed(
                    message: "iCloudの状態を確認できませんでした。記録はこの端末にも安全に保存されています。"
                )
            }
        } catch {
            Self.logger.error("CloudKit account status failed: \(error.localizedDescription, privacy: .public)")
            appSettings.cloudSyncStatus = .failed(
                message: "iCloudの状態を確認できませんでした。記録はこの端末にも保存され、次回起動時に再確認します。"
            )
        }
    }

    @MainActor
    private func handleCloudKitEvent(_ notification: Notification) {
        guard appSettings.isPro,
              persistenceStatus == .cloudConfigured,
              let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
              ] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        if event.endDate == nil {
            appSettings.cloudSyncStatus = .syncing
            return
        }
        if event.error != nil {
            appSettings.cloudSyncStatus = .failed(
                message: "iCloudとの同期を完了できませんでした。記録はこの端末にも保存され、接続が戻ると自動で再試行されます。"
            )
        } else {
            do {
                let removedCount = try RecordStoreIntegrity.removeLogicalDuplicates(
                    in: modelContainer
                )
                if removedCount > 0 {
                    Self.logger.notice(
                        "Removed \(removedCount, privacy: .public) duplicate records after CloudKit sync"
                    )
                }
            } catch {
                Self.logger.error(
                    "Could not reconcile duplicate records after CloudKit sync: \(error.localizedDescription, privacy: .public)"
                )
            }
            appSettings.cloudSyncStatus = .synced
        }
    }
}

private struct PersistenceResult {
    let container: ModelContainer
    let status: PersistenceStatus
    let recoveryResult: LegacyStoreRecoveryResult
}

private enum PersistenceStatus: Equatable {
    case cloudConfigured
    case localOnly
    case localAfterCloudFailure(String)
    case legacyFallback(message: String)
    case recoveryRequired(message: String)
}

private struct DataRecoveryRequiredView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(.orange)

            Text("記録を保護しています")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("もう一度確認", action: retry)
                .buttonStyle(.borderedProminent)

            Text("アプリを削除すると、端末内の記録を復元できなくなる場合があります。")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.red)
        }
        .padding(28)
    }
}
