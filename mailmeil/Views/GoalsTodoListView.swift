import SwiftUI
import SwiftData

struct GoalTodoListView: View {
    var goal: Goal
    var goalColor: Color
    @Binding var isAdding: Bool
    @Binding var newText: String
    @Binding var todos: [Item]
    var onAdd: () -> Void
    var onToggle: (UUID) -> Void
    var onDelete: (UUID) -> Void
    var onTapRepeatDays: (Goal) -> Void
    @FocusState private var isFocused: Bool
    @State private var openRowID: UUID? = nil

    private var todayIndex: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    onTapRepeatDays(goal)
                }) {
                    HStack(spacing: 4) {
                        Text(goal.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(goalColor)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(goalColor)
                        Spacer()
                    }
                    .padding(.leading, 20)
                }
                .buttonStyle(PlainButtonStyle())

                ZStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openRowID = nil
                        }

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(todos.enumerated()).filter { !$0.element.isCompleted }, id: \.element.id) { offset, _ in
                                todoRow(todo: $todos[offset], onTapRepeatDays: {
                                    onTapRepeatDays(goal)
                                })
                            }

                            ForEach(Array(todos.enumerated()).filter { $0.element.isCompleted }, id: \.element.id) { offset, _ in
                                todoRow(todo: $todos[offset], onTapRepeatDays: {
                                    onTapRepeatDays(goal)
                                })
                            }
                        }
                    }
                }

                if isAdding {
                    HStack(spacing: 8) {
                        Circle()
                            .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 1))
                            .frame(width: 22, height: 22)
                        
                        TextField("", text: $newText)
                            .focused($isFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                if !newText.isEmpty {
                                    onAdd()
                                    isAdding = false
                                }
                            }
                    }
                    .padding(.leading, 20)
                } else {
                    HStack(spacing: 8) {
                        Circle()
                            .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 1))
                            .frame(width: 22, height: 22)
                        
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity, minHeight: 22)
                    }
                    .padding(.leading, 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isAdding = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    }
                }

                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 2)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func todoRow(todo: Binding<Item>, onTapRepeatDays: @escaping () -> Void) -> some View {
        TodoRowView(
            todo: todo,
            goalColor: goalColor,
            isDailyRepeat: goal.isDailyRepeat,
            isToday: todo.wrappedValue.repeatDays.contains(todayIndex),
            onTapRepeatDays: onTapRepeatDays,
            onToggle: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onToggle(todo.wrappedValue.id)
                }
            }
        )
    }
}

private struct TodoRowView: View {
    @Binding var todo: Item
    var goalColor: Color
    var isDailyRepeat: Bool
    var isToday: Bool
    var onTapRepeatDays: (() -> Void)?
    var onToggle: (() -> Void)?

    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                if isToday {
                    Button(action: {
                        onToggle?()
                    }) {
                        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundColor(todo.isCompleted ? goalColor : .gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                } else {
                    Color.clear
                        .frame(width: 22, height: 22)
                }

                if isEditing {
                    TextField("", text: $todo.content, onCommit: {
                        isEditing = false
                    })
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 4)
                    .padding(.trailing, 12)
                } else {
                    HStack {
                        Text(todo.content)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(todo.isCompleted ? .gray : (isToday ? .primary : .gray))
                            .onTapGesture {
                                isEditing = true
                            }

                        Spacer()

                        if isDailyRepeat {
                            HStack(spacing: 2) {
                                let weekdaySymbols = ["월", "화", "수", "목", "금", "토", "일"]

                                ForEach(0..<7, id: \.self) { index in
                                    let isSelected = todo.repeatDays.contains(index)
                                    let isCompleted = todo.completedDays.contains(index)

                                    if isSelected {
                                        ZStack {
                                            Circle()
                                                .fill(goalColor.opacity(0.2))
                                                .frame(width: 16, height: 16)

                                            if isCompleted {
                                                Circle()
                                                    .stroke(goalColor, lineWidth: 3)
                                                    .frame(width: 16, height: 16)
                                            }

                                            Text(weekdaySymbols[index])
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(minWidth: 16)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onTapRepeatDays?()
                            }
                        }
                    }
                    .padding(.trailing, 20)
                }
            }
            .padding(.leading, 20)
            .padding(.top, 8)

            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
                .padding(.top, 8)
                .padding(.leading, 20)
        }
    }
}

private struct SwipeableTodoRow: View {
    @Binding var todo: Item
    var goalColor: Color
    var onDelete: (UUID) -> Void
    @Binding var openRowID: UUID?

    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isEditing: Bool = false

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        offset = 0
                    }
                }

            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundColor(todo.isCompleted ? goalColor : .gray)
                            .onTapGesture {
                                withAnimation {
                                    todo.isCompleted.toggle()
                                }
                            }

                        if isEditing {
                            TextField("", text: $todo.content, onCommit: {
                                isEditing = false
                            })
                            .font(.system(size: 16, weight: .medium))
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 4)
                            .padding(.trailing, 12)
                            .padding(.leading, 0)
                        } else {
                            Text(todo.content)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(todo.isCompleted ? .gray : .primary)
                                .onTapGesture {
                                    isEditing = true
                                }
                        }
                    }
                    .padding(.leading, 20)

                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                        .padding(.top, 8)
                        .padding(.leading, 20)
                }
                .background(Color(.systemBackground))
                .offset(x: offset + dragOffset)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            if value.translation.width < 0 {
                                state = value.translation.width
                            }
                        }
                        .onEnded { value in
                            withAnimation {
                                if value.translation.width < -80 {
                                    offset = -80
                                    openRowID = todo.id
                                } else {
                                    offset = 0
                                    openRowID = nil
                                }
                            }
                        }
                )
                .onChange(of: openRowID) { newValue in
                    if newValue != todo.id {
                        withAnimation {
                            offset = 0
                        }
                    }
                }

                GeometryReader { geometry in
                    if offset < -20 {
                        HStack {
                            Spacer()
                            Button(action: {
                                onDelete(todo.id)
                            }) {
                                Text("삭제")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 60, height: geometry.size.height)
                                    .background(Color(.systemRed))
                            }
                            .padding(.trailing, 10)
                        }
                        .frame(height: geometry.size.height)
                    }
                }
            }
            .padding(.vertical, 3)
        }
    }
}
