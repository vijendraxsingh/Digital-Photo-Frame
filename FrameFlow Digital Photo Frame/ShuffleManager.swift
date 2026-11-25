import Foundation

final class ShuffleManager {
    private var items: [String] = []
    private var currentIndex = 0
    private let orderMode: SettingsStore.OrderMode

    init(orderMode: SettingsStore.OrderMode = .random) {
        self.orderMode = orderMode
    }

    func setItems(_ newItems: [String], avoidIdentifier: String? = nil) {
        if orderMode == .sequential {
            items = newItems
        } else {
            var pool = newItems.filter { $0 != avoidIdentifier }
            pool.shuffle()
            if let avoidIdentifier { pool.append(avoidIdentifier) }
            items = pool
        }
        currentIndex = 0
    }

    func nextItem() -> String? {
        guard currentIndex < items.count else { return nil }
        let item = items[currentIndex]
        currentIndex += 1
        return item
    }

    func lastDisplayedIdentifier() -> String? {
        currentIndex > 0 ? items[currentIndex - 1] : nil
    }
}
