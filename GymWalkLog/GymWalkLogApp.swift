import SwiftUI
import SwiftData

@main
struct GymWalkLogApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var purchaseManager: PurchaseManager
    @State private var modelContainer: ModelContainer
    @State private var persistenceStatus: PersistenceStatus

    init() {
        let settings = AppSettings()
        let persistence = Self.makeModelContainer(isPro: settings.isPro)
        _appSettings = StateObject(wrappedValue: settings)
        _purchaseManager = StateObject(wrappedValue: PurchaseManager(appSettings: settings))
        _modelContainer = State(initialValue: persistence.container)
        _persistenceStatus = State(initialValue: persistence.status)
        _ = settings.firstLaunchDate
    }

    private static func makeModelContainer(isPro: Bool) -> PersistenceResult {
        let schema = Schema([WorkoutRecord.self])
        if isPro {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            do {
                let container = try ModelContainer(for: schema, configurations: [cloudConfig])
                return PersistenceResult(container: container, status: .cloudSynced)
            } catch {
                return makeLocalModelContainer(
                    schema: schema,
                    fallbackReason: "iCloud同期を開始できなかったため、この端末内の保存に切り替えました。iCloud設定やネットワーク状態を確認してください。",
                    originalError: error
                )
            }
        }

        return makeLocalModelContainer(schema: schema)
    }

    private static func makeLocalModelContainer(
        schema: Schema,
        fallbackReason: String? = nil,
        originalError: Error? = nil
    ) -> PersistenceResult {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            return PersistenceResult(
                container: container,
                status: fallbackReason.map { .localFallback(message: $0) } ?? .localOnly
            )
        } catch {
            let message: String
            if fallbackReason != nil {
                message = "iCloud同期と端末内の保存を開始できなかったため、一時保存モードで起動しました。アプリを終了すると、この起動中に追加した記録は残りません。iCloud設定や空き容量を確認して、アプリを再起動してください。"
            } else {
                message = "端末内の保存を開始できなかったため、一時保存モードで起動しました。アプリを終了すると、この起動中に追加した記録は残りません。空き容量を確認して、アプリを再起動してください。"
            }
            return makeInMemoryModelContainer(
                schema: schema,
                fallbackMessage: message,
                cloudError: originalError,
                localError: error
            )
        }
    }

    private static func makeInMemoryModelContainer(
        schema: Schema,
        fallbackMessage: String,
        cloudError: Error?,
        localError: Error
    ) -> PersistenceResult {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            return PersistenceResult(container: container, status: .localFallback(message: fallbackMessage))
        } catch {
            let cloudErrorDescription = cloudError.map { "\nCloudKit error: \($0.localizedDescription)" } ?? ""
            fatalError(
                "ModelContainerの作成に失敗しました。\(cloudErrorDescription)\nLocal error: \(localError.localizedDescription)\nIn-memory error: \(error.localizedDescription)"
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appSettings)
                .environmentObject(purchaseManager)
                .modelContainer(modelContainer)
                .id(appSettings.isPro)
                .onChange(of: appSettings.isPro) { _, isPro in
                    let persistence = Self.makeModelContainer(isPro: isPro)
                    modelContainer = persistence.container
                    persistenceStatus = persistence.status
                }
                .alert("iCloud同期を開始できませんでした", isPresented: cloudFallbackAlertBinding) {
                    Button("OK", role: .cancel) {
                        persistenceStatus = .localOnly
                    }
                } message: {
                    Text(persistenceStatus.alertMessage ?? "")
                }
        }
    }

    private var cloudFallbackAlertBinding: Binding<Bool> {
        Binding(
            get: { persistenceStatus.alertMessage != nil },
            set: { if !$0 { persistenceStatus = .localOnly } }
        )
    }
}

private struct PersistenceResult {
    let container: ModelContainer
    let status: PersistenceStatus
}

private enum PersistenceStatus: Equatable {
    case cloudSynced
    case localOnly
    case localFallback(message: String)

    var alertMessage: String? {
        if case .localFallback(let message) = self {
            return message
        }
        return nil
    }
}
