import XCTest
import CoreData
@testable import AIarm

class AlarmTests: CoreDataTestCase {
    func testCreateAlarm() throws {
        // Given
        let date = Date()
        let newAlarm = Alarm(time: date, isOn: true, goal: "Test Alarm", repeatCount: 3, interval: 5)
        
        // When
        let alarmEntity = newAlarm.toAlarmEntity(context: viewContext)
        try viewContext.save()
        
        // Then
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "One alarm should be created")
        XCTAssertEqual(results.first?.time, date, "Alarm time should match")
        XCTAssertEqual(results.first?.isOn, true, "Alarm should be on")
        XCTAssertEqual(results.first?.goal, "Test Alarm", "Alarm goal should match")
        XCTAssertEqual(results.first?.repeatCount, 3, "Alarm repeat count should match")
        XCTAssertEqual(results.first?.interval, 5, "Alarm interval should match")
    }

    func testUpdateAlarm() throws {
        // Given
        let originalDate = Date()
        let alarm = Alarm(time: originalDate, isOn: true, goal: "Original Goal", repeatCount: 1, interval: 1)
        let alarmEntity = alarm.toAlarmEntity(context: viewContext)
        try viewContext.save()
        
        // When
        let updatedDate = Date().addingTimeInterval(3600) // 1 hour later
        alarmEntity.time = updatedDate
        alarmEntity.isOn = false
        alarmEntity.goal = "Updated Goal"
        alarmEntity.repeatCount = 2
        alarmEntity.interval = 10
        try viewContext.save()
        
        // Then
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "There should still be only one alarm")
        XCTAssertEqual(results.first?.time, updatedDate, "Alarm time should be updated")
        XCTAssertEqual(results.first?.isOn, false, "Alarm should be turned off")
        XCTAssertEqual(results.first?.goal, "Updated Goal", "Alarm goal should be updated")
        XCTAssertEqual(results.first?.repeatCount, 2, "Alarm repeat count should be updated")
        XCTAssertEqual(results.first?.interval, 10, "Alarm interval should be updated")
    }

    func testDeleteAlarm() throws {
        // Given
        let alarm = Alarm(time: Date(), isOn: true, goal: "Alarm to Delete", repeatCount: 1, interval: 1)
        let alarmEntity = alarm.toAlarmEntity(context: viewContext)
        try viewContext.save()
        
        // When
        viewContext.delete(alarmEntity)
        try viewContext.save()
        
        // Then
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 0, "No alarms should remain after deletion")
    }
}
