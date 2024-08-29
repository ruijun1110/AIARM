import Foundation
import CoreData

/// Represents an alarm with scheduling details and an optional associated agent.
public struct Alarm: Identifiable {
    public var id: String
    public var time: Date
    public var isOn: Bool
    public var goal: String
    public var repeatCount: Int
    public var interval: Int
    var agent: Agent?
    
    // Initializer for creating a new Alarm
    init(id: String = UUID().uuidString, time: Date, isOn: Bool, goal: String, repeatCount: Int ,interval: Int, agent: Agent? = nil) {
        self.id = id
        self.time = time
        self.isOn = isOn
        self.goal = goal
        self.repeatCount = repeatCount
        self.interval = interval
        self.agent = agent
    }
    
    /// Initializes a new Alarm.
    /// - Parameters:
    ///   - id: A unique identifier for the alarm, defaulting to a new UUID string.
    ///   - time: The time at which the alarm is set to trigger.
    ///   - isOn: A Boolean indicating whether the alarm is active.
    ///   - goal: A brief description of the alarm's purpose.
    ///   - agent: An optional `Agent` associated with the alarm.
    init(alarmEntity: AlarmEntity) {
        self.id = alarmEntity.id ?? UUID().uuidString
        self.time = alarmEntity.time ?? Date()
        self.isOn = alarmEntity.isOn
        self.goal = alarmEntity.goal ?? ""
        self.interval = Int(alarmEntity.interval)
        self.repeatCount = Int(alarmEntity.repeatCount)
        self.agent = alarmEntity.agent.map { Agent(agentEntity: $0) }
    }
    
    /// Converts this alarm to a Core Data entity.
    /// - Parameter context: The managed object context for Core Data operations.
    /// - Returns: An `AlarmEntity` that represents this alarm.
    func toAlarmEntity(context: NSManagedObjectContext) -> AlarmEntity {
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        let existingAlarms = try? context.fetch(fetchRequest)
        let alarmEntity = existingAlarms?.first ?? AlarmEntity(context: context)
        
        alarmEntity.id = id
        alarmEntity.time = time
        alarmEntity.isOn = isOn
        alarmEntity.goal = goal
        alarmEntity.interval = Int64(interval)
        alarmEntity.repeatCount = Int64(repeatCount)
        alarmEntity.agent = agent?.toAgentEntity(context: context)
        return alarmEntity
    }
}
