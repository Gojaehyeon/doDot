import Foundation
import SwiftData
import SwiftUI

class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    
    private var saveURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("goals.json")
    }

    init() {
        loadFromDisk()
        resetDailyGoalsIfNeeded()
    }

    func addGoal(title: String, emoji: String, colorName: String, isDailyRepeat: Bool) {
        let newGoal = Goal(title: title, emoji: emoji, colorName: colorName, isDailyRepeat: isDailyRepeat)
        goals.append(newGoal)
        objectWillChange.send()
        saveToDisk()
    }

    func addTodo(to goalID: UUID, content: String, repeatDays: [Int] = [0, 1, 2, 3, 4, 5, 6]) {
        print("🧩 addTodo called for goalID: \(goalID), content: \(content)")

        guard let index = goals.firstIndex(where: { $0.id == goalID }) else {
            print("❌ Couldn't find goal with ID: \(goalID)")
            return
        }

        print("✅ Found goal at index: \(index)")
        let newTodo = Item(timestamp: Date(), content: content, repeatDays: repeatDays)

        if goals[index].isDailyRepeat {
            goals[index].baseTodos.append(newTodo)
            goals[index].todos.append(newTodo)
        } else {
            goals[index].todos.append(newTodo)
        }

        print("📥 New todo added. Current todos: \(goals[index].todos.map { $0.content })")

        objectWillChange.send()
        saveToDisk()
    }

    func toggleTodo(goalID: UUID, todoID: UUID) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else { return }
        guard let todoIndex = goals[goalIndex].todos.firstIndex(where: { $0.id == todoID }) else { return }
        
        withAnimation {
            goals[goalIndex].todos[todoIndex].isCompleted.toggle()
            goals[goalIndex].todos[todoIndex].timestamp = Date()
            objectWillChange.send()
            saveToDisk()
        }
    }

    func resetDailyGoalsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? .distantPast
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastReset) {
            for i in goals.indices {
                if goals[i].isDailyRepeat {
                    // 완료된 항목만 보존 (이전 날짜의 항목들)
                    let completedTodos = goals[i].todos.filter { $0.isCompleted }
                    
                    // 기존 baseTodos를 기반으로 새로운 항목 생성
                    let newTodos = goals[i].baseTodos.map { base in
                        Item(timestamp: Date(), content: base.content, isCompleted: false, repeatDays: base.repeatDays)
                    }
                    
                    // 완료된 이전 항목들과 새로운 항목들을 합침
                    goals[i].todos = newTodos + completedTodos
                }
            }
            UserDefaults.standard.set(Date(), forKey: "lastResetDate")
            saveToDisk()
        }
    }
    
    func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(goals)
            try data.write(to: saveURL)
        } catch {
            print("❌ Failed to save goals:", error)
        }
    }

    private func loadFromDisk() {
        do {
            let data = try Data(contentsOf: saveURL)
            goals = try JSONDecoder().decode([Goal].self, from: data)
        } catch {
            print("❌ Failed to load goals:", error)
        }
    }

    func deleteTodo(goalID: UUID, todoID: UUID) {
        guard let index = goals.firstIndex(where: { $0.id == goalID }) else { return }
        
        // 삭제하려는 항목 찾기
        if let todoToDelete = goals[index].todos.first(where: { $0.id == todoID }) {
            if todoToDelete.isCompleted {
                // 완료된 항목은 todos에서 삭제하지 않음
                // baseTodos에서만 삭제하여 다음날 생성되지 않도록 함
                if goals[index].isDailyRepeat {
                    goals[index].baseTodos.removeAll { $0.id == todoID }
                }
            } else {
                // 완료되지 않은 항목은 모두 삭제
                goals[index].todos.removeAll { $0.id == todoID }
                if goals[index].isDailyRepeat {
                    goals[index].baseTodos.removeAll { $0.id == todoID }
                }
            }
        }

        saveToDisk()
    }

    func loadSampleGoals() {
        self.goals = [
            Goal(
                title: "운동하기",
                emoji: "💪",
                colorName: "red",
                isDailyRepeat: false,
                baseTodos: [],
                todos: [
                    Item(timestamp: Date(), content: "런닝 30분", isCompleted: false),
                    Item(timestamp: Date(), content: "푸쉬업 20회", isCompleted: true)
                ]
            )
        ]
    }

    func moveGoal(from source: IndexSet, to destination: Int) {
        goals.move(fromOffsets: source, toOffset: destination)
        saveToDisk()
    }

    func deleteGoal(_ id: UUID) {
        goals.removeAll { $0.id == id }
        saveToDisk()
    }

    func updateGoal(id: UUID, title: String, emoji: String, colorName: String, isDailyRepeat: Bool) {
        guard let index = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[index].title = title
        goals[index].emoji = emoji
        goals[index].colorName = colorName
        goals[index].isDailyRepeat = isDailyRepeat
        saveToDisk()
    }
    
    func processRepeatingTodosIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastProcessed = UserDefaults.standard.object(forKey: "lastProcessedDate") as? Date
        
        guard lastProcessed == nil || Calendar.current.compare(today, to: lastProcessed!, toGranularity: .day) == .orderedDescending else {
            return
        }
        
        let todayIndex = (Calendar.current.component(.weekday, from: Date()) + 5) % 7
        
        for i in goals.indices {
            var updatedTodos: [Item] = []
            for todo in goals[i].todos {
                if todo.repeatDays.contains(todayIndex) {
                    if todo.isCompleted {
                        updatedTodos.append(todo)
                    }
                    let newTodo = Item(timestamp: Date(), content: todo.content, isCompleted: false, repeatDays: todo.repeatDays)
                    updatedTodos.append(newTodo)
                } else {
                    updatedTodos.append(todo)
                }
            }
            goals[i].todos = updatedTodos
        }
        
        UserDefaults.standard.set(today, forKey: "lastProcessedDate")
        saveToDisk()
    }
}
