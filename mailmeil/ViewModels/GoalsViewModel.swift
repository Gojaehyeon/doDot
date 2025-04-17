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
        let newGoal = Goal(
            title: title,
            emoji: emoji,
            colorName: colorName,
            isDailyRepeat: isDailyRepeat,
            baseTodos: [],
            todos: [],
            completedHistory: [],
            deletedContents: [],
            lastResetDate: Date()
        )
        goals.append(newGoal)
        objectWillChange.send()
        saveToDisk()
    }

    func addTodo(to goalID: UUID, content: String) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else { return }
        var updatedGoal = goals[goalIndex]
        
        let newItem = Item(
            timestamp: Date(),
            content: content,
            isCompleted: false,
            order: updatedGoal.todos.count,
            repeatDays: updatedGoal.isDailyRepeat ? [0,1,2,3,4,5,6] : [],
            isBase: updatedGoal.isDailyRepeat
        )
        
        if updatedGoal.isDailyRepeat {
            updatedGoal.baseTodos.append(newItem)
            let todayItem = Item(
                timestamp: Date(),
                content: content,
                isCompleted: false,
                order: updatedGoal.todos.count,
                repeatDays: [0,1,2,3,4,5,6],
                isBase: false
            )
            updatedGoal.todos.append(todayItem)
        } else {
            updatedGoal.todos.append(newItem)
        }
        
        goals[goalIndex] = updatedGoal
        saveToDisk()
    }

    func toggleTodo(goalID: UUID, todoID: UUID) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else { return }
        guard let todoIndex = goals[goalIndex].todos.firstIndex(where: { $0.id == todoID }) else { return }
        
        withAnimation {
            var updatedGoal = goals[goalIndex]
            var updatedTodo = updatedGoal.todos[todoIndex]
            updatedTodo.isCompleted.toggle()
            updatedTodo.timestamp = Date()
            
            updatedGoal.todos[todoIndex] = updatedTodo
            
            if updatedTodo.isCompleted {
                updatedGoal.completedHistory.append(updatedTodo)
            }
            
            goals[goalIndex] = updatedGoal
            objectWillChange.send()
            saveToDisk()
        }
    }

    func deleteTodo(goalID: UUID, todoID: UUID) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else { return }
        var updatedGoal = goals[goalIndex]
        
        guard let todoToDelete = updatedGoal.todos.first(where: { $0.id == todoID }) else { return }
        
        if updatedGoal.isDailyRepeat {
            // 기본 루틴에서 해당 항목 삭제
            updatedGoal.baseTodos.removeAll { todo in
                todo.content == todoToDelete.content
            }
            
            // 현재 활성화된 루틴에서 해당 항목 삭제
            updatedGoal.todos.removeAll { todo in
                todo.content == todoToDelete.content
            }
            
            // 삭제된 항목 기록 추가
            updatedGoal.deletedContents.append(todoToDelete.content)
        } else {
            updatedGoal.todos.removeAll { $0.id == todoID }
        }
        
        goals[goalIndex] = updatedGoal
        objectWillChange.send()
        saveToDisk()
    }

    private func todayIndex() -> Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }

    func resetDailyGoalsIfNeeded() {
        let calendar = Calendar.current
        let today = Date()
        
        for goalIndex in goals.indices {
            var updatedGoal = goals[goalIndex]
            if updatedGoal.isDailyRepeat {
                if !calendar.isDate(updatedGoal.lastResetDate, inSameDayAs: today) {
                    // 현재 활성화된 todos에서 완료된 항목들 유지
                    let completedTodos = updatedGoal.todos.filter { $0.isCompleted }
                    
                    // 기본 루틴에서 새로운 항목 생성 (삭제된 항목 제외)
                    let newTodos = updatedGoal.baseTodos
                        .filter { base in
                            // 삭제된 항목 목록에 없는 것만 포함
                            !updatedGoal.deletedContents.contains(base.content)
                        }
                        .map { base in
                            Item(
                                timestamp: today,
                                content: base.content,
                                isCompleted: false,
                                order: base.order,
                                repeatDays: base.repeatDays,
                                isBase: false
                            )
                        }
                    
                    // 완료된 항목과 새로운 항목을 합침
                    updatedGoal.todos = completedTodos + newTodos
                    updatedGoal.lastResetDate = today
                    goals[goalIndex] = updatedGoal
                }
            }
        }
        saveToDisk()
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

    func loadSampleGoals() {
        self.goals = [
            Goal(
                title: "운동하기",
                emoji: "💪",
                colorName: "red",
                isDailyRepeat: false,
                baseTodos: [],
                todos: [
                    Item(
                        timestamp: Date(),
                        content: "런닝 30분",
                        isCompleted: false,
                        order: 0,
                        repeatDays: [],
                        isBase: false
                    ),
                    Item(
                        timestamp: Date(),
                        content: "푸쉬업 20회",
                        isCompleted: true,
                        order: 1,
                        repeatDays: [],
                        isBase: false
                    )
                ],
                completedHistory: [],
                deletedContents: [],
                lastResetDate: Date()
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
        var updatedGoal = goals[index]
        
        // 반복 설정이 꺼질 때 모든 투두의 repeatDays 초기화
        if updatedGoal.isDailyRepeat && !isDailyRepeat {
            updatedGoal.todos = updatedGoal.todos.map { todo in
                var updatedTodo = todo
                updatedTodo.repeatDays = []
                updatedTodo.isBase = false
                return updatedTodo
            }
            updatedGoal.baseTodos = []
        }
        
        updatedGoal.title = title
        updatedGoal.emoji = emoji
        updatedGoal.colorName = colorName
        updatedGoal.isDailyRepeat = isDailyRepeat
        goals[index] = updatedGoal
        saveToDisk()
    }
}
