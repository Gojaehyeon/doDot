//
//  ContentView.swift
//  mailmeil
//
//  Created by 고재현 on 4/11/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = GoalsViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.goals.flatMap { $0.todos }) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let goal = Goal(title: "테스트", emoji: "🧪", colorName: "blue", isDailyRepeat: false)
            let item = Item(timestamp: Date(), content: "")
            goal.todos.append(item)
            viewModel.goals.append(goal)
            viewModel.saveToDisk()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let flatItems = viewModel.goals.flatMap { $0.todos }
                guard index < flatItems.count else { continue }
                let itemToDelete = flatItems[index]
                for goal in viewModel.goals.indices {
                    if let idx = viewModel.goals[goal].todos.firstIndex(where: { $0.id == itemToDelete.id }) {
                        viewModel.goals[goal].todos.remove(at: idx)
                        break
                    }
                }
            }
            viewModel.saveToDisk()
        }
    }
}

#Preview {
    ContentView()
}
