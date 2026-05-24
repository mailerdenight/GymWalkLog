import SwiftUI
import SwiftData

@main
struct GymWalkLogApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var purchaseManager: PurchaseManager

    init() {
        let settings = AppSettings()
        _appSettings = StateObject(wrappedValue: settings)
        _purchaseManager = StateObject(wrappedValue: PurchaseManager(appSettings: settings))
        _ = settings.firstLaunchDate
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([WorkoutRecord.self])
        let isPro = UserDefaults.standard.bool(forKey: "isPro")
        let config: ModelConfiguration
        if isPro {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        } else {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // CloudKit失敗時はローカル保存にフォールバック
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appSettings)
                .environmentObject(purchaseManager)
                .modelContainer(sharedModelContainer)
        }
    }
}
