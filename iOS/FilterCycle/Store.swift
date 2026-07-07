import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    @Published var items: [FilterCycleItem] = []
    @Published var isPro: Bool = false

    /// Free tier limit. Kept comfortably above seed count so a fresh install
    /// never immediately hits the paywall.
    static let freeLimit = 6

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("filtercycle_items.json")
        load()
    }

    var canAddMore: Bool {
        isPro || items.count < Store.freeLimit
    }

    func add(_ item: FilterCycleItem) {
        items.append(item)
        save()
    }

    func update(_ item: FilterCycleItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func delete(_ item: FilterCycleItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    private func seedIfNeeded() -> [FilterCycleItem] {
        [
            FilterCycleItem(name: "HVAC Filter", detail: "Furnace Room", extra: 90, date: Date()),
            FilterCycleItem(name: "Fridge Water Filter", detail: "Kitchen", extra: 180, date: Date()),
            FilterCycleItem(name: "Fridge Air Filter", detail: "Kitchen", extra: 60, date: Date())
        ]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([FilterCycleItem].self, from: data) else {
            items = seedIfNeeded()
            save()
            return
        }
        items = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
