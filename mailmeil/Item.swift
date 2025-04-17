import Foundation

struct Item: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var timestamp: Date
    var content: String
    var isCompleted: Bool = false
    var order: Int = 0
    var repeatDays: [Int] = []
    var completedDays: [Int] = []

    init(timestamp: Date, content: String, isCompleted: Bool = false, order: Int = 0, repeatDays: [Int] = [], completedDays: [Int] = []) {
        self.timestamp = timestamp
        self.content = content
        self.isCompleted = isCompleted
        self.order = order
        self.repeatDays = repeatDays
        self.completedDays = completedDays
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id &&
               lhs.timestamp == rhs.timestamp &&
               lhs.content == rhs.content &&
               lhs.isCompleted == rhs.isCompleted &&
               lhs.order == rhs.order &&
               lhs.repeatDays == rhs.repeatDays &&
               lhs.completedDays == rhs.completedDays
    }
}
