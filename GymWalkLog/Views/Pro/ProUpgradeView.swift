import SwiftUI

struct ProUpgradeView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var theme: AppTheme { appSettings.theme }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    featuresSection
                    purchaseSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if !purchaseManager.isProductReady {
                    await purchaseManager.loadProducts()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("あとで") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            ThemePlantIllustration(theme: theme, size: 92)
                .padding(.top, 8)

            Text("もっと振り返る。\nもっと自分を好きになる。")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Proにすると、あなたの記録がもっと価値になります。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 12) {
            Text("Pro機能")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                featureRow(icon: "calendar", title: "31件目以降の記録も続けられる", desc: "無料版の30件を超えても保存できます")
                featureRow(icon: "chart.bar.fill", title: "月別・年別のレポートが見える", desc: "変化の流れをグラフで確認できます")
                featureRow(icon: "photo.on.rectangle", title: "写真を何枚でも保存できる", desc: "トレッドミル画面もまとめて残せます")
                featureRow(icon: "doc.text", title: "PDFとCSVで出力できる", desc: "自分の記録を手元に残せます")
                featureRow(icon: "list.bullet.rectangle", title: "全履歴を一覧で振り返れる", desc: "長く続けた分まで見返せます")
            }
        }
        .padding(16)
        .background(theme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(theme.primaryColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryColor)
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("買い切り・サブスクリプションなし")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let error = purchaseManager.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            if purchaseManager.isLoadingProducts && !purchaseManager.isProductReady {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("購入プランを確認しています…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.cardColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if purchaseManager.isProductReady {
                Button {
                    Task {
                        await purchaseManager.purchasePro()
                        if appSettings.isPro { dismiss() }
                    }
                } label: {
                    Group {
                        if purchaseManager.isPurchasing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Proにする（買い切り \(purchaseManager.priceString)）")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.primaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: theme.primaryColor.opacity(0.4), radius: 8, y: 4)
                }
                .disabled(purchaseManager.isPurchasing)
            } else {
                VStack(spacing: 10) {
                    Text("現在、購入プランを表示できません。")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("App Storeに接続できる状態で再読み込みしてください。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Task { await purchaseManager.loadProducts() }
                    } label: {
                        Text("もう一度確認する")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.primaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Button {
                Task { await purchaseManager.restorePurchases() }
            } label: {
                Text("購入を復元する")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
