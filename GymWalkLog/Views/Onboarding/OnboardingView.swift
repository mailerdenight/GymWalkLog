import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var currentPage = 0

    var theme: AppTheme { appSettings.theme }

    private var pages: [OnboardingPage] {[
        OnboardingPage(
            icon: "figure.walk",
            title: "ジム歩走ログへ",
            body: "トレッドミルでの歩き・走りを\nシンプルに記録するアプリです。\nがんばりすぎなくていい。\n自分のペースで続けていきましょう。",
            isLast: false
        ),
        OnboardingPage(
            icon: "camera.viewfinder",
            title: "写真から自動入力",
            body: "トレッドミルの画面を撮るだけで\n距離・時間・カロリーを自動読み取り。\n使えば使うほど、あなたのマシンの\n表示位置を学習して精度が上がります。",
            isLast: false
        ),
        OnboardingPage(
            icon: "calendar",
            title: "続けた日が積み重なる",
            body: "カレンダーに記録した日が\nひとつずつ埋まっていきます。\n連続記録、月の達成状況、\nグラフでふり返ることができます。",
            isLast: false
        ),
        OnboardingPage(
            icon: "leaf.fill",
            title: "自分のペースで始めよう",
            body: "最初の30件まで無料で記録できます。\nもっと続けたくなったら\n買い切り（\(purchaseManager.priceString)）のProにアップグレード。\nサブスクリプションはありません。",
            isLast: true
        ),
    ]}

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                bottomArea
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.primaryColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(theme.primaryColor)
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    private var bottomArea: some View {
        VStack(spacing: 20) {
            // ページインジケーター
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? theme.primaryColor : theme.primaryColor.opacity(0.25))
                        .frame(width: i == currentPage ? 20 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }

            if currentPage < pages.count - 1 {
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("次へ")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.primaryColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: theme.primaryColor.opacity(0.3), radius: 8, y: 4)
                }

                Button {
                    appSettings.hasSeenOnboarding = true
                } label: {
                    Text("スキップ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Button {
                    appSettings.hasSeenOnboarding = true
                } label: {
                    Text("はじめる")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.primaryColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: theme.primaryColor.opacity(0.3), radius: 8, y: 4)
                }
            }
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
    let isLast: Bool
}
