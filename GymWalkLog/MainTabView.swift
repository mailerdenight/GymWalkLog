import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    @State private var selectedTab = 0
    @State private var showNewRecord = false
    @State private var showLaunchLogo = true

    var body: some View {
        ZStack {
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
                .tabItem { Label("レポート", systemImage: "chart.bar") }
                .tag(4)
            }
            .tint(appSettings.theme.primaryColor)

            if showLaunchLogo {
                LaunchLogoView(theme: appSettings.theme)
                    .transition(.opacity)
            }
        }
        .onAppear {
            WidgetDataManager.update(records: records)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeOut(duration: 0.25)) {
                    showLaunchLogo = false
                }
            }
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
            get: { !appSettings.hasSeenOnboarding && !showLaunchLogo },
            set: { if !$0 { appSettings.hasSeenOnboarding = true } }
        )) {
            OnboardingView()
        }
    }
}

private struct LaunchLogoView: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 18) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 148, height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

                Text("ジム歩走ログ")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
    }
}
