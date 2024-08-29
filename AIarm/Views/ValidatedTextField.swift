import SwiftUI

/// A custom text field with built-in validation and visual feedback.
struct ValidatedTextField: View {
    // MARK: - Properties
    @Binding var text: String
    let placeholder: String
    @Binding var isValid: Bool
    @Binding var shouldWiggle: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color("Placeholder")))
            .foregroundStyle(Color("Highlight"))
            .focused($isFocused)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color("Theme") : Color("warning"))
            )
            .onChange(of: text) { _, newValue in
                isValid = !newValue.isEmpty && newValue.containsOnlyAlphabets
            }
            .wiggle($shouldWiggle)
    }
}

// MARK: - String Extension
extension String {
    /// Checks if the string contains only alphabetic characters and whitespaces.
    var containsOnlyAlphabets: Bool {
        let alphabetSet = CharacterSet.letters.union(.whitespaces)
        return self.unicodeScalars.allSatisfy { alphabetSet.contains($0) }
    }
}
