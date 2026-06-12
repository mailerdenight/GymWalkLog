import SwiftUI
import SwiftData

@main
struct GymWalkLogApp: App {
    @StateObject private var appSettings: AppSettings
    @StateObject private var purchaseManager: PurchaseManager
    @State private var modelContainer: ModelContainer
    @State private var persistenceStatus: PersistenceStatus

    init() {
        let settings = AppSettings()
        let persistence = Self.makeModelContainer()
        _appSettings = StateObject(wrappedValue: settings)
        _purchaseManager = StateObject(wrappedValue: PurchaseManager(appSettings: settings))
        _modelContainer = State(initialValue: persistence.container)
        _persistenceStatus = State(initialValue: persistence.status)
        _ = settings.firstLaunchDate
    }

    private static func makeModelContainer() -> PersistenceResult {
        let schema = Schema([WorkoutRecord.self, WorkoutPhoto.self])
        return makeLocalModelContainer(schema: schema)
    }

    private static func makeLocalModelContainer(
        schema: Schema,
        fallbackReason: String? = nil
    ) -> PersistenceResult {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            return PersistenceResult(
                container: container,
                status: fallbackReason.map { .localFallback(message: $0) } ?? .localOnly
            )
        } catch {
            let message: String
            if fallbackReason != nil {
                message = "保存を開始できなかったため、一時保存モードで起動しました。アプリを終了すると、この起動中に追加した記録は残りません。空き容量を確認して、アプリを再起動してください。"
            } else {
                message = "端末内の保存を開始できなかったため、一時保存モードで起動しました。アプリを終了すると、この起動中に追加した記録は残りません。空き容量を確認して、アプリを再起動してください。"
            }
            return makeInMemoryModelContainer(
                schema: schema,
                fallbackMessage: message,
                localError: error
            )
        }
    }

    private static func makeInMemoryModelContainer(
        schema: Schema,
        fallbackMessage: String,
        localError: Error
    ) -> PersistenceResult {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            return PersistenceResult(container: container, status: .localFallback(message: fallbackMessage))
        } catch {
            fatalError(
                "ModelContainerの作成に失敗しました。\nLocal error: \(localError.localizedDescription)\nIn-memory error: \(error.localizedDescription)"
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appSettings)
                .environmentObject(purchaseManager)
                .modelContainer(modelContainer)
                .preferredColorScheme(appSettings.preferredColorScheme)
                .alert("保存を開始できませんでした", isPresented: fallbackAlertBinding) {
                    Button("OK", role: .cancel) {
                        persistenceStatus = .localOnly
                    }
                } message: {
                    Text(persistenceStatus.alertMessage ?? "")
                }
        }
    }

    private var fallbackAlertBinding: Binding<Bool> {
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
    case localOnly
    case localFallback(message: String)

    var alertMessage: String? {
        if case .localFallback(let message) = self {
            return message
        }
        return nil
    }
}
