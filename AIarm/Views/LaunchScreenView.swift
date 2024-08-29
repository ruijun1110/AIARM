import SwiftUI

/// Provides utility functions to create preview data entities for SwiftUI previews.
struct LaunchScreenView: View {
    var body: some View {
        ZStack (alignment:.center) {
            Color("BG").edgesIgnoringSafeArea(.all)
            
            Image("LaunchScreen")
                .resizable()
                .scaledToFit()
                .frame(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.width) * 0.5)
                .padding(.bottom, 50)

        }
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}
