import StoreKit
import SwiftUI

@MainActor
class PurchaseManager: ObservableObject {
    static let proProductID = "com.gymwalklog.app.pro"

    @Published var products: [Product] = []
    @Published var isLoadingProducts = false
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    private var appSettings: AppSettings
    private var updatesTask: Task<Void, Never>?

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        updatesTask = observeTransactionUpdates()
        Task { await loadProducts() }
        Task { await checkExistingPurchases() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        do {
            products = try await Product.products(for: [Self.proProductID])
            if products.isEmpty {
                purchaseError = "App Storeから購入プランを取得できませんでした。通信状況をご確認のうえ、もう一度お試しください。"
            } else {
                purchaseError = nil
            }
        } catch {
            products = []
            purchaseError = "購入プランを読み込めませんでした。しばらくしてからもう一度お試しください。"
        }
        isLoadingProducts = false
    }

    func purchasePro() async {
        if products.isEmpty {
            await loadProducts()
        }
        guard let product = products.first else {
            purchaseError = "購入プランを取得できませんでした。App Storeに接続できる状態で、もう一度お試しください。"
            return
        }
        isPurchasing = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .userCancelled:
                break
            case .pending:
                purchaseError = "購入は保留中です。App Storeの承認が完了したあとに反映されます。"
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
            await loadProducts()
        } catch {
            purchaseError = "復元に失敗しました。"
        }
    }

    private func checkExistingPurchases() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID {
                hasPro = true
            }
        }
        appSettings.isPro = hasPro
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                await handle(result)
            }
        }
    }

    private func handle(_ verification: VerificationResult<StoreKit.Transaction>) async {
        switch verification {
        case .verified(let transaction):
            if transaction.productID == Self.proProductID {
                appSettings.isPro = true
                purchaseError = nil
            }
            await transaction.finish()
        case .unverified:
            purchaseError = "購入の確認ができませんでした。"
        }
    }

    var proProduct: Product? { products.first }
    var isProductReady: Bool { proProduct != nil }

    var priceString: String {
        proProduct?.displayPrice ?? "App Storeで確認"
    }
}
