//
//  GoalCardView.swift
//  mailmeil
//
//  Created by 고재현 on 4/11/25.
//

import SwiftUI

struct GoalCardView: View {
    let goal: Goal
    var todos: Binding<[Item]>

    private var todayIndex: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }

    private var remainingTodosCount: Int {
        if goal.isDailyRepeat {
            return todos.wrappedValue.filter { todo in
                todo.repeatDays.contains(todayIndex) && !todo.isCompleted
            }.count
        } else {
            return todos.wrappedValue.filter { !$0.isCompleted }.count
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.fromName(goal.colorName),
                            Color.fromName(goal.colorName).opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(goal.emoji)
                        .font(.system(size: 35))
                        .padding(.leading, -6)
                    Spacer()
                    Text("\(remainingTodosCount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(goal.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(width: 175, height: 90)
    }
}

