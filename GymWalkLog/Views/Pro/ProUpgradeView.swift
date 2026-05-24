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
            Image(systemName: "leaf.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryColor)
                .padding(.top, 12)

            Text("あなたの記録が、\n資産になります。")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("過去を振り返ることで、\n未来の自分が変わります。")
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
                featureRow(icon: "calendar", title: "30件以前の記録も表示", desc: "過去の全記録を振り返れます")
                featureRow(icon: "photo.stack", title: "写真つき記録を保存", desc: "記録ごとに最大3枚まで追加できます")
                featureRow(icon: "chart.bar.fill", title: "週・月・年の振り返りグラフ", desc: "成長の軌跡が一目でわかります")
                featureRow(icon: "square.and.arrow.up", title: "データをCSVで書き出し", desc: "記録を手元に残せます")
                featureRow(icon: "icloud", title: "iCloudバックアップ（自動）", desc: "購入後すぐに同期設定へ切り替わります")
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
