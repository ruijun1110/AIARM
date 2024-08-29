import SwiftUI

/// A custom view modifier that adds a wiggle animation to a view.
struct WiggleModifier: ViewModifier {
    @Binding var shouldWiggle: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: shouldWiggle ? -5 : 0)
            .animation(
                shouldWiggle ?
                    Animation.easeInOut(duration: 0.1)
                    .repeatCount(3, autoreverses: true) :
                    .default,
                value: shouldWiggle
            )
            .onChange(of: shouldWiggle) { _, newValue in
                if newValue {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        shouldWiggle = false
                    }
                }
            }
    }
}

extension View {
    /// Applies the wiggle modifier to the view.
    /// - Parameter shouldWiggle: A binding to a Boolean that controls when the wiggle animation should occur.
    /// - Returns: A view that wiggles when `shouldWiggle` is true.
    func wiggle(_ shouldWiggle: Binding<Bool>) -> some View {
        modifier(WiggleModifier(shouldWiggle: shouldWiggle))
    }
}
