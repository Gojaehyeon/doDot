import SwiftUI

struct AddTodoInputView: View {
    @Binding var text: String
    var onCommit: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Circle()
                .strokeBorder(Color.gray, lineWidth: 1)
                .frame(width: 22, height: 22)

            TextField("", text: $text)
                .submitLabel(.done)
                .onSubmit {
                    onCommit()
                }
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .focused($isFocused)
                .onChange(of: text) { newValue in
                    guard newValue != text else { return }
                    print("✏️ AddTodoInputView - text changed: \(newValue)")
                }
                .onChange(of: isFocused) { oldValue, newValue in
                    if !newValue && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        text = ""
                    }
                }
        }
        .padding(.leading, 0)
    }
}

struct AddTodoInputView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
            .previewLayout(.sizeThatFits)
            .padding()
    }

    struct PreviewWrapper: View {
        @State private var sampleText = ""

        var body: some View {
            AddTodoInputView(text: $sampleText) {
                print("Committed")
            }
        }
    }
}
