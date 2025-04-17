import SwiftUI

final class Goal: Identifiable, ObservableObject, Codable {
    var id = UUID()
    var title: String
    var emoji: String
    var colorName: String
    var isDailyRepeat: Bool
    @Published var baseTodos: [Item] = []
    @Published var todos: [Item] = []

    init(
        title: String,
        emoji: String,
        colorName: String,
        isDailyRepeat: Bool,
        baseTodos: [Item] = [],
        todos: [Item] = []
    ) {
        self.title = title
        self.emoji = emoji
        self.colorName = colorName
        self.isDailyRepeat = isDailyRepeat
        self.baseTodos = baseTodos
        self.todos = todos
    }

    var color: Color {
        let lowercasedName = colorName.lowercased()

        switch lowercasedName {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "yellow": return .yellow
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        default:
            if let uiColor = UIColor(named: colorName) {
                return Color(uiColor)
            } else {
                return .blue // fallback
            }
        }
    }

    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }

    enum CodingKeys: CodingKey {
        case id, title, emoji, colorName, isDailyRepeat, baseTodos, todos
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        emoji = try container.decode(String.self, forKey: .emoji)
        colorName = try container.decode(String.self, forKey: .colorName)
        isDailyRepeat = try container.decode(Bool.self, forKey: .isDailyRepeat)
        baseTodos = try container.decode([Item].self, forKey: .baseTodos)
        todos = try container.decode([Item].self, forKey: .todos)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(colorName, forKey: .colorName)
        try container.encode(isDailyRepeat, forKey: .isDailyRepeat)
        try container.encode(baseTodos, forKey: .baseTodos)
        try container.encode(todos, forKey: .todos)
    }
}
