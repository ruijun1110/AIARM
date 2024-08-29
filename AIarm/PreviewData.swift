import SwiftUI
import Foundation
import CoreData

/// Provides utility functions to create preview data entities for SwiftUI previews.
struct PreviewData {
    /// Creates a preview `AgentEntity` with predefined attributes for use in SwiftUI previews.
    /// - Parameter context: The managed object context used to create the entity.
    /// - Returns: A pre-configured `AgentEntity` instance.
    static func createPreviewAgentEntity(context: NSManagedObjectContext) -> AgentEntity {
        let agent = AgentEntity(context: context)
        agent.id = UUID().uuidString
        agent.name = "Tina"
        agent.character = "Crazy mom"
        agent.mood = "Chill"
        agent.motivations = "Motivation 1,Motivation 2"
        return agent
    }

    /// Creates a preview `AlarmEntity` linked to a preview `AgentEntity` for use in SwiftUI previews.
    /// - Parameter context: The managed object context used to create the entities.
    /// - Returns: A pre-configured `AlarmEntity` instance.
    static func createPreviewAlarmEntity(context: NSManagedObjectContext) -> AlarmEntity {
        let alarm = AlarmEntity(context: context)
        alarm.id = UUID().uuidString
        alarm.time = Date()
        alarm.isOn = true
        alarm.goal = "wake up"
        let agent = createPreviewAgentEntity(context: context)
        alarm.agent = agent
        return alarm
    }
}
