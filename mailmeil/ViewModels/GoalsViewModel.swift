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

    func addTodo(to goalID: UUID, content: String, repeatDays: [Int]) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else { return }
        var updatedGoal = goals[goalIndex]
        
        if updatedGoal.isDailyRepeat {
            let baseItem = Item(
                timestamp: Date(),
                content: content,
                isCompleted: false,
                order: updatedGoal.todos.count,
                repeatDays: [0,1,2,3,4,5,6],  // 모든 요일 선택
                isBase: true
            )
            updatedGoal.baseTodos.append(baseItem)
            
            let todayItem = Item(
                timestamp: Date(),
                content: content,
                isCompleted: false,
                order: updatedGoal.todos.count,
                repeatDays: [0,1,2,3,4,5,6],  // 모든 요일 선택
                isBase: false
            )
            updatedGoal.todos.append(todayItem)
        } else {
            let item = Item(
                timestamp: Date(),
                content: content,
                isCompleted: false,
                order: updatedGoal.todos.count,
                repeatDays: [],
                isBase: false
            )
            updatedGoal.todos.append(item)
        }
        
        goals[goalIndex] = updatedGoal
        objectWillChange.send()
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
                    // 완료된 항목들을 completedHistory에 추가
                    let completedTodos = updatedGoal.todos.filter { $0.isCompleted }
                    updatedGoal.completedHistory.append(contentsOf: completedTodos)
                    
                    // baseTodos에서 새로운 todos 생성 (삭제된 항목 제외)
                    let newTodos = updatedGoal.baseTodos
                        .filter { base in
                            !updatedGoal.deletedContents.contains(base.content)
                        }
                        .map { base in
                            // base의 모든 정보를 그대로 복사하여 새로운 Item 생성
                            Item(
                                id: UUID(),  // 새로운 ID 생성
                                timestamp: today,
                                content: base.content,
                                isCompleted: false,
                                order: base.order,
                                repeatDays: base.repeatDays,  // base의 repeatDays를 그대로 복사
                                isBase: false
                            )
                        }
                    
                    // 기존 todos를 새로운 todos로 교체
                    updatedGoal.todos = newTodos
                    updatedGoal.lastResetDate = today
                    goals[goalIndex] = updatedGoal
                }
            }
        }
        saveToDisk()
    }
    
    func saveToDisk() {
        do {
            // 디버그 로그 추가
            for goal in goals {
                print("🔍 Saving Goal: \(goal.title)")
                for baseTodo in goal.baseTodos {
                    print("  - Base Todo: \(baseTodo.content), Repeat Days: \(baseTodo.repeatDays)")
                }
            }
            
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
            
            // 디버그 로그 추가
            for goal in goals {
                print("🔍 Loaded Goal: \(goal.title)")
                for baseTodo in goal.baseTodos {
                    print("  - Base Todo: \(baseTodo.content), Repeat Days: \(baseTodo.repeatDays)")
                }
            }
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
        // 반복 설정이 켜질 때 모든 투두를 매일 반복으로 설정
        else if !updatedGoal.isDailyRepeat && isDailyRepeat {
            // 기존 todos를 baseTodos로 복사
            updatedGoal.baseTodos = updatedGoal.todos.map { todo in
                var baseTodo = todo
                baseTodo.repeatDays = [0,1,2,3,4,5,6]
                baseTodo.isBase = true
                return baseTodo
            }
            
            // 기존 todos도 매일 반복으로 설정
            updatedGoal.todos = updatedGoal.todos.map { todo in
                var updatedTodo = todo
                updatedTodo.repeatDays = [0,1,2,3,4,5,6]
                updatedTodo.isBase = false
                return updatedTodo
            }
        }
        
        updatedGoal.title = title
        updatedGoal.emoji = emoji
        updatedGoal.colorName = colorName
        updatedGoal.isDailyRepeat = isDailyRepeat
        goals[index] = updatedGoal
        saveToDisk()
    }
}
