import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    var goal: Goal

    @State private var newTodoText = ""
    @State private var todos: [Item] = []
    @State private var isEditing = false
    @State private var selectedTodo: Item?

    var body: some View {
        let todayIndex = (Calendar.current.component(.weekday, from: Date()) + 5) % 7
        let visibleTodos = todos.enumerated().filter { $0.element.repeatDays.contains(todayIndex) }
        let hiddenTodos = todos.enumerated().filter { !$0.element.repeatDays.contains(todayIndex) }
        let completedTodos = todos.enumerated().filter { $0.element.isCompleted }

        let todoList = List {
            if !visibleTodos.isEmpty {
                Section(header:
                    Text("오늘 할 일")
                        .textCase(nil)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, -15)
                ) {
                    ForEach(visibleTodos, id: \.offset) { index, _ in
                        NavigationLink(destination: TodoRepeatSettingsView(todo: $todos[index], goal: goal)) {
                            HStack {
                                Image(systemName: todos[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(Color(goal.color))
                                    .font(.system(size: 22))
                                Text(todos[index].content)
                                    .foregroundColor(todos[index].isCompleted ? .gray : .primary)
                                Spacer()
                                    .foregroundColor(.gray)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { offset in
                            let index = visibleTodos[offset].offset
                            viewModel.deleteTodo(goalID: goal.id, todoID: todos[index].id)
                            todos.remove(at: index)
                        }
                    }
                    .onMove { indices, newOffset in
                        let resolved = indices.map { visibleTodos[$0].offset }
                        todos.move(fromOffsets: IndexSet(resolved), toOffset: newOffset)
                        updateOrder()
                    }
                }
            }

            if !hiddenTodos.isEmpty {
                Section(header:
                    Text("숨겨진 할 일")
                        .textCase(nil)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, -15)
                ) {
                    ForEach(hiddenTodos, id: \.offset) { index, _ in
                        NavigationLink(destination: TodoRepeatSettingsView(todo: $todos[index], goal: goal)) {
                            HStack {
                                Image(systemName: todos[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(Color(goal.color))
                                    .font(.system(size: 22))
                                Text(todos[index].content)
                                    .foregroundColor(todos[index].isCompleted ? .gray : .primary)
                                Spacer()
                                    .foregroundColor(.gray)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { offset in
                            let index = hiddenTodos[offset].offset
                            viewModel.deleteTodo(goalID: goal.id, todoID: todos[index].id)
                            todos.remove(at: index)
                        }
                    }
                    .onMove { indices, newOffset in
                        let resolved = indices.map { hiddenTodos[$0].offset }
                        todos.move(fromOffsets: IndexSet(resolved), toOffset: newOffset)
                        updateOrder()
                    }
                }
            }
            
            if !completedTodos.isEmpty {
                Section(header:
                    Text("완료한 일")
                        .textCase(nil)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, -15)
                ) {
                    ForEach(completedTodos, id: \.offset) { index, _ in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(goal.color))
                                .font(.system(size: 22))
                            Text(todos[index].content)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(formattedDate(todos[index].timestamp))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))

        return VStack {
            todoList
            HStack {
                TextField(" 루틴 추가하기", text: $newTodoText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                Button(action: {
                    guard !newTodoText.isEmpty else { return }
                    let newOrder = (todos.map { $0.order }.max() ?? 0) + 1
                    let newTodo = Item(timestamp: Date(), content: newTodoText, isCompleted: false, order: newOrder)
                    viewModel.addTodo(to: goal.id, content: newTodoText)
                    withAnimation {
                        todos.append(newTodo)
                    }
                    newTodoText = ""
                    sortTodos()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(goal.color))
                }
            }
            .padding()
        }
        .onAppear {
            todos = goal.todos
            sortTodos()
        }
        .navigationTitle("\(goal.emoji) \(goal.title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "완료" : "편집") {
                    withAnimation {
                        isEditing.toggle()
                    }
                }
            }
        }
    }

    private func sortTodos() {
        todos.sort { (lhs: Item, rhs: Item) -> Bool in
            if lhs.isCompleted == rhs.isCompleted {
                return lhs.order < rhs.order
            } else {
                return !lhs.isCompleted && rhs.isCompleted
            }
        }
    }

    private func updateOrder() {
        for (index, _) in todos.enumerated() {
            todos[index].order = index
        }
    }

    private func moveItem(from source: IndexSet, to destination: Int) {
        todos.move(fromOffsets: source, toOffset: destination)
        updateOrder()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct TodoRepeatSettingsView: View {
    @Binding var todo: Item
    var goal: Goal
    let days = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        VStack(spacing: 20) {
            Text("반복을 원하는 요일을 선택하세요")
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    Button(action: {
                        var updatedDays = todo.repeatDays
                        if updatedDays.contains(index) {
                            updatedDays.removeAll { $0 == index }
                        } else {
                            updatedDays.append(index)
                        }
                        todo.repeatDays = updatedDays
                    }) {
                        ZStack {
                            Circle()
                                .fill(todo.repeatDays.contains(index) ? Color(goal.color).opacity(0.2) : Color(.systemGray5))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(todo.repeatDays.contains(index) ? Color(goal.color) : Color.clear, lineWidth: 2)
                                )

                            Text(days[index])
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .padding(.top, -100)
        .padding()
        .navigationTitle("반복 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}
