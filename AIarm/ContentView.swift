import SwiftUI

/// Enum representing the available tabs in the app.
enum Tab {
    case alarms, characters, testing, setting
}

/// The main content view of the application.
struct ContentView: View {
    // MARK: - Properties
    @State var selectedTab: Tab = .alarms
    @State var index: Int = 0
    @State private var showingAddAlarmView = false
    @State private var showingAddAgentView = false
    @State private var needsRefresh = false
    @State private var showSettingsAlert = false
    @Environment(\.scenePhase) private var scenePhase

    
    var body: some View {
        VStack {
            mainContent
            Spacer()
            CustomTabs(index: self.$index, showingAddAlarmView: $showingAddAlarmView, showingAddAgentView: $showingAddAgentView)
        }
        .ignoresSafeArea()
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && index != 3 {
                checkUserSettings()
            }
        }
        .onChange(of: self.index) { oldValue, newValue in
            if newValue != 3{
                checkUserSettings()
            }
        }
        .alert("Setup Required", isPresented: $showSettingsAlert) {
            Button("Go to Settings") {
                index = 3 // Switch to the Settings tab
            }
        } message: {
            Text("Please set up your username and API key in the Settings before using the app.")
        }
    }
    
    // MARK: - Private Methods
    /// The main content of the view, determined by the selected tab.
    private var mainContent: some View {
        Group {
            switch index {
            case 0:
                Home(showingAddAlarmView: $showingAddAlarmView)
                    .offset(y: 43)
            case 1:
                AgentsView(showingAddAgentView: $showingAddAgentView)
                    .offset(y: 43)
            case 2:
                AgentTestingView()
                    .offset(y: 43)
            case 3:
                SettingView()
                    .offset(y: 43)
            default:
                EmptyView()
            }
        }
    }

    /// Checks if the user has set up their username and API key.
    private func checkUserSettings() {
        let username = OpenAISettings.shared.username
        let apiKey = OpenAISettings.shared.apiKey
        if username.isEmpty || apiKey.isEmpty {
            showSettingsAlert = true
        }
    }
}

#Preview {
    ContentView()
}
