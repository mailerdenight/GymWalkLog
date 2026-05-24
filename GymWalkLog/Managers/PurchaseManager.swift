import StoreKit
import SwiftUI

@MainActor
class PurchaseManager: ObservableObject {
    static let proProductID = "com.gymwalklog.app.pro"

    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    private var appSettings: AppSettings

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        Task { await loadProducts() }
        Task { await checkExistingPurchases() }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.proProductID])
        } catch {
            // Products unavailable in sandbox/development
        }
    }

    func purchasePro() async {
        guard let product = products.first else {
            purchaseError = "購入情報を取得できませんでした。しばらくしてからもう一度お試しください。"
            return
        }
        isPurchasing = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    appSettings.isPro = true
                case .unverified:
                    purchaseError = "購入の確認ができませんでした。"
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = "購入に失敗しました: \(error.localizedDescription)"
        }
        isPurchasing = false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkExistingPurchases()
        } catch {
            purchaseError = "復元に失敗しました。"
        }
    }

    private func checkExistingPurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID {
                appSettings.isPro = true
            }
        }
    }

    var proProduct: Product? { products.first }

    var priceString: String {
        proProduct?.displayPrice ?? "¥300"
    }
}
