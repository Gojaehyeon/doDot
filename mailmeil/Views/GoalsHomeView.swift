//
//  GoalsHomeView.swift
//  mailmeil
//
//  Created by 고재현 on 4/11/25.
//

import SwiftData
import SwiftUI
import CoreHaptics
import Foundation
 
extension Goal: Hashable {
    static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id
    }

 
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    private func todayIndex() -> Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }
}

private struct GoalCardPreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct GoalsHomeView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @State private var showAddGoalSheet = false
    @State private var showEditGoalSheet = false
    @State private var isAddingTodoDict: [UUID: Bool] = [:]
    @State private var newTodoTextDict: [UUID: String] = [:]
    @State private var reorderedGoals: [Goal] = []
    @State private var draggedItem: Goal?
    @State private var dragOffset: CGSize = .zero
    @State private var dragStartLocation: CGPoint?
    @State private var selectedGoalForAction: Goal?
    @State private var showGoalActionSheet = false
    @State private var isEditing = false
    @State private var cardFrames: [UUID: CGRect] = [:]
    @State private var lastSwapIndex: Int? = nil
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var lastHapticTime = Date()
    @State private var dragDirection: CGFloat = 0
    @State private var lastSwapTime = Date()
    @State private var selectedGoalToView: Goal? = nil

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.goals.isEmpty {
                    emptyGoalsView
                } else if viewModel.goals.count == 1, let goal = viewModel.goals.first {
                    singleGoalView(goal: goal)
                } else {
                    multipleGoalsView
                }
                NavigationLink(
                    destination: selectedGoalToView.map { GoalDetailView(goal: $0) },
                    isActive: Binding(
                        get: { selectedGoalToView != nil },
                        set: { newValue in
                            if !newValue {
                                selectedGoalToView = nil
                            }
                        }
                    )
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("나의 목표")
            .navigationDestination(for: Goal.self) { goal in
                GoalDetailView(goal: goal)
            }
            .toolbar {
                if !viewModel.goals.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: {
                                showAddGoalSheet = true
                            }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddGoalSheet) {
                AddGoalView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: Binding(
                get: {
                    showEditGoalSheet && selectedGoalForAction != nil
                },
                set: { newValue in
                    showEditGoalSheet = newValue
                }
            )) {
                if let goal = selectedGoalForAction {
                    EditGoalView(goal: goal)
                        .presentationDetents([.medium, .large])
                }
            }
            .onAppear {
                reorderedGoals = viewModel.goals
                viewModel.processRepeatingTodosIfNeeded()
            }
            .onReceive(viewModel.$goals) { newGoals in
                reorderedGoals = newGoals
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ReorderGoalsExternally"))) { notification in
                if let newOrder = notification.object as? [Goal] {
                    viewModel.goals = newOrder
                }
            }
        }
    }

    private var emptyGoalsView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                HStack {
                    Text("매일의 루틴을 통해 이루고 싶은 목표를 추가하세요.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
            }

            Button(action: {
                showAddGoalSheet = true
            }) {
                Label("목표 추가", systemImage: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }

    private func singleGoalView(goal: Goal) -> some View {
    if isAddingTodoDict[goal.id] == nil {
        isAddingTodoDict[goal.id] = false
    }
    return NavigationLink(value: goal) {
            GoalSingleView(
                goal: goal,
                goalColor: goal.color,
                isAdding: Binding(
                    get: { isAddingTodoDict[goal.id] ?? false },
                    set: { isAddingTodoDict[goal.id] = $0 }
                ),
                newText: Binding(
                    get: { newTodoTextDict[goal.id] ?? "" },
                    set: { newTodoTextDict[goal.id] = $0 }
                ),
                todos: Binding(
                    get: { goal.todos },
                    set: { newValue in
                        if let index = viewModel.goals.firstIndex(where: { $0.id == goal.id }) {
                            viewModel.goals[index].todos = newValue
                        }
                    }
                ),
                onAdd: {
                    let content = (newTodoTextDict[goal.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !content.isEmpty else { return }
                    viewModel.addTodo(to: goal.id, content: content)
                    newTodoTextDict[goal.id] = ""
                    isAddingTodoDict[goal.id] = false
                },
                onToggle: { todoID in
                    viewModel.toggleTodo(goalID: goal.id, todoID: todoID)
                },
                onDelete: { todoID in
                    viewModel.deleteTodo(goalID: goal.id, todoID: todoID)
                }
            )
        }
        .contextMenu {
            Button {
                selectedGoalForAction = goal
                DispatchQueue.main.async {
                    showEditGoalSheet = true
                }
            } label: {
                Label("편집", systemImage: "square.and.pencil")
            }

            Button(role: .destructive) {
                viewModel.deleteGoal(goal.id)
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private var goalCardGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 12
        ) {
            ForEach(reorderedGoals, id: \.id) { goal in
                goalCardView(for: goal)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onPreferenceChange(GoalCardPreferenceKey.self) { preferences in
            cardFrames = preferences
        }
    }

    private func goalCardView(for goal: Goal) -> some View {
        NavigationLink(value: goal) {
            GoalCardView(
                goal: goal,
                todos: Binding(
                    get: { goal.todos },
                    set: { newValue in
                        if let index = viewModel.goals.firstIndex(where: { $0.id == goal.id }) {
                            viewModel.goals[index].todos = newValue
                        }
                    }
                )
            )
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: GoalCardPreferenceKey.self, value: [goal.id: proxy.frame(in: .global)])
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(draggedItem?.id == goal.id ? 1.05 : 1)
            .shadow(color: Color.black.opacity(draggedItem?.id == goal.id ? 0.2 : 0), radius: 10, x: 0, y: 6)
            .offset(draggedItem?.id == goal.id ? dragOffset : .zero)
            .zIndex(draggedItem?.id == goal.id ? 1 : 0)
            .simultaneousGesture(TapGesture().onEnded {
                if !isEditing {
                    selectedGoalToView = goal
                }
            })
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { drag in
                        if draggedItem == nil {
                            draggedItem = goal
                            dragStartLocation = drag.startLocation
                            lastSwapIndex = nil
                            hapticGenerator.prepare()
                            lastSwapTime = Date()
                            lastHapticTime = Date()
                            dragDirection = 0
                        }

                        dragOffset = drag.translation
                        dragDirection = drag.translation.height

                        guard let fromIndex = reorderedGoals.firstIndex(where: { $0.id == goal.id }) else { return }
                        guard let draggedFrame = cardFrames[goal.id]?.offsetBy(dx: dragOffset.width, dy: dragOffset.height) else { return }

                        for (otherID, otherFrame) in cardFrames where otherID != goal.id {
                            let draggedMidY = draggedFrame.midY
                            let otherMidY = otherFrame.midY
                            let draggedMidX = draggedFrame.midX
                            let otherMidX = otherFrame.midX

                            let isMovingDown = dragDirection > 0
                            let condition = isMovingDown ? draggedMidY > otherMidY : draggedMidY < otherMidY

                            let heightDifference = abs(draggedMidY - otherMidY)
                            let similarHeight = heightDifference < 20

                            let xDistance = draggedFrame.maxX > otherFrame.maxX
                                ? otherFrame.maxX - draggedFrame.minX
                                : draggedFrame.maxX - otherFrame.minX

                            let wideXOverlap = xDistance > (otherFrame.width * 0.5)
                            let strictXOverlap = xDistance > (otherFrame.width * 0.66)

                            let yOverlapEnough = similarHeight || draggedFrame.intersects(otherFrame)
                            let validSwap = yOverlapEnough && (similarHeight ? wideXOverlap : strictXOverlap)

                            if condition, validSwap,
                               let toIndex = reorderedGoals.firstIndex(where: { $0.id == otherID }),
                               toIndex != fromIndex,
                               Date().timeIntervalSince(lastSwapTime) > 0.2 {

                                withAnimation(.spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0.4)) {
                                    reorderedGoals.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                                    lastSwapIndex = toIndex
                                    lastSwapTime = Date()

                                    if Date().timeIntervalSince(lastHapticTime) > 0.2 {
                                        hapticGenerator.impactOccurred()
                                        lastHapticTime = Date()
                                    }
                                }
                                break
                            }
                        }
                    }
                    .onEnded { _ in
                        draggedItem = nil
                        dragOffset = .zero
                        dragStartLocation = nil
                        lastSwapIndex = nil
                        NotificationCenter.default.post(name: Notification.Name("ReorderGoalsExternally"), object: reorderedGoals)
                    }
            )
            .contextMenu {
                Button {
                    selectedGoalForAction = goal
                    DispatchQueue.main.async {
                        showEditGoalSheet = true
                    }
                } label: {
                    Label("편집", systemImage: "square.and.pencil")
                }

                Button(role: .destructive) {
                    viewModel.deleteGoal(goal.id)
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            }
        }
    }

    private var goalTodoLists: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(viewModel.goals, id: \.id) { goal in
                goalListView(for: goal)
            }
        }
    }

    private var multipleGoalsView: some View {
        ZStack {
            if draggedItem != nil {
                Color.black.opacity(0.05)
                    .edgesIgnoringSafeArea(.all)
            }

            ScrollView {
                VStack(spacing: 24) {
                    goalCardGrid
                    goalTodoLists
                }
            }
        }
    }
    @ViewBuilder
    private func goalListView(for goal: Goal) -> some View {
        let isAdding = isAddingTodoDict[goal.id] ?? false
        let newText = newTodoTextDict[goal.id] ?? ""
 
        GoalTodoListView(
            goal: goal,
            goalColor: goal.color,
            isAdding: Binding(
                get: { isAddingTodoDict[goal.id] ?? false },
                set: { isAddingTodoDict[goal.id] = $0 }
            ),
            newText: Binding(
                get: { newTodoTextDict[goal.id] ?? "" },
                set: { newTodoTextDict[goal.id] = $0 }
            ),
            todos: Binding(
                get: {
                    if let index = viewModel.goals.firstIndex(where: { $0.id == goal.id }) {
                        return viewModel.goals[index].todos.filter { $0.repeatDays.contains(todayIndex()) }
                    }
                    return []
                },
                set: { newValue in
                    if let index = viewModel.goals.firstIndex(where: { $0.id == goal.id }) {
                        viewModel.goals[index].todos = newValue
                    }
                }
            ),
            onAdd: {
                let content = newText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !content.isEmpty else { return }
                viewModel.addTodo(to: goal.id, content: content)
                newTodoTextDict[goal.id] = ""
                isAddingTodoDict[goal.id] = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: Notification.Name("RefocusTodoInput"), object: goal.id)
                }
            },
            onToggle: { todoID in
                viewModel.toggleTodo(goalID: goal.id, todoID: todoID)
            },
            onDelete: { todoID in
                viewModel.deleteTodo(goalID: goal.id, todoID: todoID)
            },
            onTapRepeatDays: { _ in selectedGoalToView = goal }
        )
    }

    private func todayIndex() -> Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }
}

struct GoalDropDelegate: DropDelegate {
    let item: Goal
    @Binding var items: [Goal]

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let fromID = UUID(uuidString: info.itemProviders(for: [.text]).first?.loadItem(forTypeIdentifier: "public.text", options: nil, completionHandler: { _, _ in }) as? String ?? ""),
              let fromIndex = items.firstIndex(where: { $0.id == fromID }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }),
              fromIndex != toIndex
        else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.2)) {
            let movedItem = items.remove(at: fromIndex)
            items.insert(movedItem, at: toIndex)
            NotificationCenter.default.post(name: Notification.Name("ReorderGoalsExternally"), object: items)
        }
    }
}


#Preview {
    let viewModel = GoalsViewModel()
    viewModel.goals = []
    return GoalsHomeView()
        .environmentObject(viewModel)
}

