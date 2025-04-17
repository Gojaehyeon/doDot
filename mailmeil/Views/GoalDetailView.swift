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
        goal.todos.sorted { !$0.isCompleted && $1.isCompleted }
    }
    
    private var completedTodos: [Item] {
        goal.todos.filter { $0.isCompleted }
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
                            viewModel.deleteTodo(goalID: goal.id, todoID: todo.id)
                        }
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
            HStack(spacing: 12) {
                TextField("새로운 항목", text: $newTodoText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    let content = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !content.isEmpty else { return }
                    viewModel.addTodo(to: goal.id, content: content)
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
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if isEditing {
                        EditButton()
                    }
                    Button(isEditing ? "완료" : "편집") {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }
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
                if !isCompletedSection && (goal.isDailyRepeat ? todo.repeatDays.contains(todayIndex) : true) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.toggleTodo(goalID: goal.id, todoID: todo.id)
                        if let index = goal.todos.firstIndex(where: { $0.id == todo.id }) {
                            let item = goal.todos.remove(at: index)
                            goal.todos.append(item)
                        }
                    }
                }
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? Color(goal.color) : 
                        (goal.isDailyRepeat ? 
                            (todo.repeatDays.contains(todayIndex) ? .gray : Color(goal.color).opacity(0.3)) :
                            .gray))
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
                        .foregroundColor(goal.isDailyRepeat ?
                            (todo.repeatDays.contains(todayIndex) ? 
                                (todo.isCompleted ? .gray : .primary) : 
                                Color(goal.color).opacity(0.3)) :
                            (todo.isCompleted ? .gray : .primary))
                    
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
                    Button {
                        selectedTodo = todo
                        showEditTodoPage = true
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}
