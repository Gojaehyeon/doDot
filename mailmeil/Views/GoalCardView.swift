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
                    Text("\(todos.wrappedValue.count)")
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

