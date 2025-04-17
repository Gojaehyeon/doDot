import SwiftUI
import SwiftData

struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: GoalsViewModel
    let goal: Goal
    let todo: Item
    @State private var content: String
    @State private var repeatDays: [Int]
    
    init(goal: Goal, todo: Item) {
        self.goal = goal
        self.todo = todo
        _content = State(initialValue: todo.content)
        _repeatDays = State(initialValue: todo.repeatDays)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Content Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("루틴 내용")
                        .font(.title2)
                        .bold()
                    
                    TextField("루틴 내용을 입력하세요", text: $content)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: content) { newValue in
                            updateTodo()
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Repeat Days Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("반복 요일")
                        .font(.title2)
                        .bold()
                    
                    HStack(spacing: 12) {
                        ForEach(0..<7, id: \.self) { index in
                            Button(action: {
                                if repeatDays.contains(index) {
                                    repeatDays.removeAll { $0 == index }
                                } else {
                                    repeatDays.append(index)
                                }
                                updateTodo()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(repeatDays.contains(index) ? Color(goal.color).opacity(0.2) : Color(.systemGray5))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(repeatDays.contains(index) ? Color(goal.color) : Color.clear, lineWidth: 2)
                                        )
                                    
                                    Text(["월", "화", "수", "목", "금", "토", "일"][index])
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("루틴 편집")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func updateTodo() {
        if let goalIndex = viewModel.goals.firstIndex(where: { $0.id == goal.id }),
           let todoIndex = viewModel.goals[goalIndex].todos.firstIndex(where: { $0.id == todo.id }) {
            viewModel.goals[goalIndex].todos[todoIndex].content = content
            viewModel.goals[goalIndex].todos[todoIndex].repeatDays = repeatDays
            viewModel.saveToDisk()
        }
    }
} 