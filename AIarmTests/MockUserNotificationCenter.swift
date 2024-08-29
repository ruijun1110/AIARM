import UserNotifications
@testable import AIarm

class MockUserNotificationCenter: NotificationCenterProtocol {
    var requests: [UNNotificationRequest] = []
    var triggeredNotifications: [UNNotificationRequest] = []
    var delegate: UNUserNotificationCenterDelegate?
    
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        requests.append(request)
        completionHandler?(nil)
    }
    
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        requests.removeAll { identifiers.contains($0.identifier) }
    }
    
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        completionHandler(requests)
    }
    
    func simulateTriggerNotification(withIdentifier identifier: String) {
        guard let request = requests.first(where: { $0.identifier == identifier }) else {
            return
        }
        
        triggeredNotifications.append(request)
        requests.removeAll { $0.identifier == identifier }
            
        if let alarmManager = delegate as? AlarmManager {
            alarmManager.handleTriggeredNotification(request: request)
        }
    }
}
