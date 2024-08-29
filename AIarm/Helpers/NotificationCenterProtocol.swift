import UserNotifications

protocol NotificationCenterProtocol {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void)
}

// Extend UNUserNotificationCenter to conform to our protocol
extension UNUserNotificationCenter: NotificationCenterProtocol {}
