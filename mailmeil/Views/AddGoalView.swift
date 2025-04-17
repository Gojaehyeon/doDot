import SwiftUI

struct AddGoalView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var selectedEmoji: String = "😀"
    @State private var selectedColor: Color = .red
    @State private var selectedColorName: String = "red"
    @State private var isDailyRepeat: Bool = true
    @FocusState private var isTitleFocused: Bool

    let availableEmojis = [
        "😀", "😁", "🤣", "😊", "😉",
        "😍", "🥰", "😘", "😋", "😜", "😎",
        "🥹", "🏃‍♂️", "🔥", "🍎", "😴", "✍️",
        "📖", "🧠", "💡", "🧘", "📅", "🎧",
        "❤️", "🧡", "💛", "💚", "💙", "💜",
        "🤍", "🩶", "🖤", "❤️‍🔥", "💕", "💞",
        "✅", "💬", "🥗", "🛠️", "🧺", "💧"
    ]
    let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo,
        .purple, .pink, .brown, .gray, .teal, .cyan
    ]

    private var colorPickerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(Array(availableColors.enumerated()), id: \.offset) { index, color in
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                .opacity(selectedColor == color ? 1 : 0)
                        )
                        .onTapGesture {
                            selectedColor = color
                            selectedColorName = ["red", "orange", "yellow", "green", "blue", "indigo", "purple", "pink", "brown", "gray", "teal", "cyan"][index]
                        }
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .frame(height: 120)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))

                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 80, height: 80)
                                Text(selectedEmoji)
                                    .font(.system(size: 40))
                            }
                            .padding(.top)

                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemBackground))

                                TextField("목표 이름", text: $title)
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .focused($isTitleFocused)
                            }
                            .padding(.horizontal)

                            HStack {
                                Toggle("리스트 반복", isOn: $isDailyRepeat)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                    .padding(.horizontal)

                    colorPickerSection

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(availableEmojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 48, height: 48)
                                    .background(selectedEmoji == emoji ? Color.gray.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedEmoji = emoji
                                    }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTitleFocused = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("새로운 목표")
                        .font(.headline)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        if !title.isEmpty {
                            viewModel.addGoal(title: title, emoji: selectedEmoji, colorName: selectedColorName, isDailyRepeat: isDailyRepeat)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddGoalView()
            .environmentObject(GoalsViewModel())
    }
}
