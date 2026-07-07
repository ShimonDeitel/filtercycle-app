import Foundation

struct FilterCycleItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var detail: String
    var extra: Int
    var date: Date
    var photoData: Data? = nil
}
