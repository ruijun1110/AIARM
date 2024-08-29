import SwiftUI

@main
struct AIarmApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isActive = false
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isActive {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .preferredColorScheme(.dark)
                    
                }
                else{
                    LaunchScreenView()
                }
            }
            .onChange(of: scenePhase) { oldValue, newValue in
                if newValue == .active {
                    AlarmManager.shared.checkAndUpdateAlarmStatus()
                    if !isActive {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
                    requestNotificationAuthorization()
                }
            }
        }
    }
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
                FileLogger.shared.log("Error requesting notification authorization: \(error)")
            }
        }
    }
}

/// The application delegate for handling app lifecycle events.
class AppDelegate: NSObject, UIApplicationDelegate {
    /// Called when the application finishes launching.
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - launchOptions: A dictionary indicating the reason the app was launched.
    /// - Returns: `true` if the app was launched successfully, otherwise `false`.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize AlarmManager
        _ = AlarmManager.shared
        return true
    }
}
