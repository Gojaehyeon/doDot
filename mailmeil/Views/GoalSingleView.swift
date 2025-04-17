//
//  GoalSingleView.swift
//  mailmeil
//
//  Created by 고재현 on 4/13/25.
//

import SwiftUI
import SwiftData

struct GoalSingleView: View {
    var goal: Goal
    let goalColor: Color
    @Binding var isAdding: Bool
    @Binding var newText: String
    @Binding var todos: [Item]
    @FocusState private var isInputFocused: Bool
    let onAdd: () -> Void
    let onToggle: (UUID) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        let todayIndex = (Calendar.current.component(.weekday, from: Date()) + 5) % 7

        ScrollView {
            VStack(spacing: 24) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 20
                ) {
                    GoalCardView(goal: goal, todos: .constant(todos.filter { $0.repeatDays.contains(todayIndex) }))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                GoalTodoListView(
                    goal: goal,
                    goalColor: goalColor,
                    isAdding: $isAdding,
                    newText: $newText,
                    todos: Binding(
                        get: { todos.filter { $0.repeatDays.contains(todayIndex) } },
                        set: { newValue in
                            todos = newValue
                        }
                    ),
                    onAdd: onAdd,
                    onToggle: onToggle,
                    onDelete: onDelete,
                    onTapRepeatDays: { _ in }
                )
                .focused($isInputFocused)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefocusTodoInput"))) { notification in
                    if let goalId = notification.object as? UUID, goalId == goal.id {
                        isInputFocused = true
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
}
