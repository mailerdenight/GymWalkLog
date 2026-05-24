import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    @State private var selectedTab = 0
    @State private var showNewRecord = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }
                .tag(0)
            RecordListView()
                .tabItem { Label("記録", systemImage: "list.bullet") }
                .tag(1)
            CalendarFullView()
                .tabItem { Label("カレンダー", systemImage: "calendar") }
                .tag(2)
            AlbumView()
                .tabItem { Label("アルバム", systemImage: "photo.on.rectangle") }
                .tag(3)
            NavigationStack {
                StatsView()
            }
            .tabItem { Label("統計", systemImage: "chart.bar") }
            .tag(4)
        }
        .tint(appSettings.theme.primaryColor)
        .onAppear {
            WidgetDataManager.update(records: records)
        }
        .onOpenURL { url in
            guard url.scheme == "gymwalklog", url.host == "newrecord" else { return }
            selectedTab = 0
            showNewRecord = true
        }
        .sheet(isPresented: $showNewRecord) {
            NewRecordView()
        }
        .fullScreenCover(isPresented: Binding(
            get: { !appSettings.hasSeenOnboarding },
            set: { if !$0 { appSettings.hasSeenOnboarding = true } }
        )) {
            OnboardingView()
        }
    }
}
