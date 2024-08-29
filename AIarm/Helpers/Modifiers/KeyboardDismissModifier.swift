import SwiftUI

/// A custom view modifier that allows dismissing the keyboard by tapping outside of text input fields.
struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    /// Applies the keyboard dismiss modifier to the view.
    /// - Returns: A view that dismisses the keyboard when tapped.
    func dismissKeyboardOnTap() -> some View {
        modifier(KeyboardDismissModifier())
    }
}
