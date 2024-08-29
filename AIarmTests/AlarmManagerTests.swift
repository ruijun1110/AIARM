import XCTest
import CoreData
import UserNotifications
@testable import AIarm

class AlarmManagerTests: CoreDataTestCase {
    var alarmManager: AlarmManager!
    var mockNotificationCenter: MockUserNotificationCenter!

    override func setUp() {
        super.setUp()
        mockNotificationCenter = MockUserNotificationCenter()
        alarmManager = AlarmManager(notificationCenter: mockNotificationCenter)
    }

    override func tearDown() {
        alarmManager = nil
        mockNotificationCenter = nil
        super.tearDown()
    }

    func testScheduleAlarm() throws {
        // Given
        let alarm = Alarm(time: Date().addingTimeInterval(60), isOn: true, goal: "Test Alarm", repeatCount: 1, interval: 1)
        
        // When
        alarmManager.scheduleAlarm(for: alarm)
        
        // Then
        XCTAssertEqual(mockNotificationCenter.requests.count, 1, "One notification should be scheduled")
        XCTAssertEqual(mockNotificationCenter.requests.first?.identifier, "\(alarm.id)_0", "Notification identifier should match")
    }

    func testCancelAlarm() throws {
        // Given
        let alarm = Alarm(time: Date().addingTimeInterval(60), isOn: true, goal: "Test Alarm", repeatCount: 1, interval: 1)
        alarmManager.scheduleAlarm(for: alarm)
        
        // When
        alarmManager.cancelAlarm(for: alarm)
        
        // Then
        XCTAssertEqual(mockNotificationCenter.requests.count, 0, "No notifications should remain after cancellation")
    }
    
    func testTriggerAlarmNotification() throws {
        // Given
        let alarm = Alarm(time: Date().addingTimeInterval(60), isOn: true, goal: "Test Alarm", repeatCount: 1, interval: 1)
        let alarmEntity = alarm.toAlarmEntity(context: viewContext)
        try viewContext.save()
        alarmManager.scheduleAlarm(for: alarm)

        // When
        mockNotificationCenter.simulateTriggerNotification(withIdentifier: "\(alarm.id)_0")

        // Then
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", alarm.id)
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "Alarm should still exist")
        XCTAssertFalse(results.first!.isOn, "Alarm should be turned off after triggering")
        XCTAssertEqual(mockNotificationCenter.triggeredNotifications.count, 1, "One notification should have been triggered")
        XCTAssertEqual(mockNotificationCenter.requests.count, 0, "No pending notifications should remain")
    }
}
