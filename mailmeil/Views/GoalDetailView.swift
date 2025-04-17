import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: GoalsViewModel
    let goal: Goal
    @State private var isAddingTodo = false
    @State private var newTodoText = ""
    @State private var showEditSheet = false
    @State private var isEditing = false
    @State private var selectedTodo: Item?
    @State private var showEditTodoPage = false
    
    private var todayIndex: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }
    
    private var routines: [Item] {
        goal.todos.sorted { item1, item2 in
            if item1.isCompleted == item2.isCompleted {
                return true
            }
            return !item1.isCompleted
        }
    }
    
    private var completedTodos: [Item] {
        goal.completedHistory
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                Section(header: Text(goal.isDailyRepeat ? "루틴" : "할 일").padding(.leading, -10)) {
                    ForEach(routines) { todo in
                        todoRow(todo)
                    }
                    .onDelete { indexSet in
                        let todosToDelete = indexSet.map { routines[$0] }
                        todosToDelete.forEach { todo in
                            if todo.isCompleted {
                                viewModel.toggleTodo(goalID: goal.id, todoID: todo.id)
                            }
                            if goal.isDailyRepeat {
                                goal.baseTodos.removeAll { $0.content == todo.content }
                            }
                            viewModel.deleteTodo(goalID: goal.id, todoID: todo.id)
                        }
                        viewModel.saveToDisk()
                    }
                    .onMove { from, to in
                        var todos = goal.todos
                        todos.move(fromOffsets: from, toOffset: to)
                        goal.todos = todos
                    }
                }
                
                if !completedTodos.isEmpty {
                    Section(header: Text("완료한 일").padding(.leading, -10)) {
                        ForEach(completedTodos) { todo in
                            todoRow(todo, isCompletedSection: true)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            // 항목 추가 UI
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    TextField("항목 추가하기", text: $newTodoText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .onSubmit {
                            let content = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !content.isEmpty else { return }
                            viewModel.addTodo(to: goal.id, content: content, repeatDays: [0,1,2,3,4,5,6])
                            newTodoText = ""
                        }
                    
                    Button(action: {
                        let content = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !content.isEmpty else { return }
                        viewModel.addTodo(to: goal.id, content: content, repeatDays: [0,1,2,3,4,5,6])
                        newTodoText = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(goal.color))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: -2)
            }
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        isEditing.toggle()
                    }
                }) {
                    Text(isEditing ? "완료" : "편집")
                }
            }
        }
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .navigationDestination(isPresented: $showEditTodoPage) {
            if let todo = selectedTodo {
                EditTodoView(goal: goal, todo: todo)
            }
        }
    }
    
    private func todoRow(_ todo: Item, isCompletedSection: Bool = false) -> some View {
        HStack {
            Button {
                if !isCompletedSection {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.toggleTodo(goalID: goal.id, todoID: todo.id)
                    }
                }
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? Color(goal.color) : (goal.isDailyRepeat && !todo.repeatDays.contains(todayIndex) ? Color(goal.color).opacity(0.3) : .gray))
                    .font(.title3)
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(isCompletedSection || (goal.isDailyRepeat && !todo.repeatDays.contains(todayIndex)))
            
            if isCompletedSection {
                VStack(alignment: .leading, spacing: 4) {
                    Text(todo.content)
                        .foregroundColor(.gray)
                    
                    Text(formatDate(todo.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(todo.content)
                        .foregroundColor(todo.isCompleted ? .gray : (goal.isDailyRepeat && !todo.repeatDays.contains(todayIndex) ? Color(goal.color).opacity(0.3) : .primary))
                    
                    if goal.isDailyRepeat {
                        HStack(spacing: 4) {
                            ForEach(0..<7) { index in
                                ZStack {
                                    Circle()
                                        .fill(todo.repeatDays.contains(index) ? Color(goal.color).opacity(0.2) : Color.clear)
                                        .frame(width: 16, height: 16)
                                    
                                    Text(["월", "화", "수", "목", "금", "토", "일"][index])
                                        .font(.system(size: 10))
                                        .foregroundColor(todo.repeatDays.contains(index) ? .primary : .gray)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                if goal.isDailyRepeat {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if goal.isDailyRepeat && !isCompletedSection {
                selectedTodo = todo
                showEditTodoPage = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}
