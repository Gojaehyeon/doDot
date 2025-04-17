import Foundation

struct Item: Codable, Equatable, Identifiable {
    var id: UUID
    var timestamp: Date
    var content: String
    var isCompleted: Bool
    var order: Int
    var repeatDays: [Int]
    var completedDays: [Int]
    var isBase: Bool  // 기본 루틴인지 여부
    
    init(
        id: UUID = UUID(),
        timestamp: Date,
        content: String,
        isCompleted: Bool = false,
        order: Int = 0,
        repeatDays: [Int] = [],
        completedDays: [Int] = [],
        isBase: Bool = false  // 기본값은 false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.content = content
        self.isCompleted = isCompleted
        self.order = order
        self.repeatDays = repeatDays
        self.completedDays = completedDays
        self.isBase = isBase
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id &&
               lhs.timestamp == rhs.timestamp &&
               lhs.content == rhs.content &&
               lhs.isCompleted == rhs.isCompleted &&
               lhs.order == rhs.order &&
               lhs.repeatDays == rhs.repeatDays &&
               lhs.completedDays == rhs.completedDays &&
               lhs.isBase == rhs.isBase
    }
}
