import Foundation
import StoreKit

/// Derives Pro entitlement live from StoreKit 2's current entitlements.
/// Same pattern used across sibling apps: DEBUG-only env overrides let
/// simulator/local runs force Pro on or fully disable StoreKit.
@MainActor
final class EntitlementsStore: ObservableObject {
    static let proMonthlyProductID = "com.shimondeitel.filtercycle.pro.monthly"

    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts: Bool = false
    @Published var lastError: String?

    private var transactionListenerTask: Task<Void, Never>?

    #if DEBUG
    /// Forces isPro = true regardless of real entitlements. For simulator/dev only.
    private var forcePro: Bool {
        ProcessInfo.processInfo.environment["FILTERCYCLE_FORCE_PRO"] == "1"
    }
    /// Disables all real StoreKit calls (e.g. for unit tests / previews).
    var skipStoreKit: Bool {
        ProcessInfo.processInfo.environment["FILTERCYCLE_NO_SK"] == "1"
    }
    #else
    private var forcePro: Bool { false }
    var skipStoreKit: Bool { false }
    #endif

    init() {
        #if DEBUG
        if forcePro {
            isPro = true
        }
        if skipStoreKit {
            return
        }
        #endif
        transactionListenerTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
        Task { [weak self] in
            await self?.loadProducts()
            await self?.refreshEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    func loadProducts() async {
        #if DEBUG
        if skipStoreKit { return }
        #endif
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: [Self.proMonthlyProductID])
        } catch {
            lastError = error.localizedDescription
        }
    }

    func purchasePro() async {
        #if DEBUG
        if skipStoreKit { return }
        #endif
        guard let product = products.first(where: { $0.id == Self.proMonthlyProductID }) else {
            await loadProducts()
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        #if DEBUG
        if skipStoreKit { return }
        #endif
        do {
            try await AppStore.sync()
        } catch {
            lastError = error.localizedDescription
        }
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        #if DEBUG
        if forcePro {
            isPro = true
            return
        }
        if skipStoreKit { return }
        #endif
        var foundPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proMonthlyProductID,
               transaction.revocationDate == nil {
                foundPro = true
            }
        }
        isPro = foundPro
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
            await refreshEntitlements()
        }
    }
}
