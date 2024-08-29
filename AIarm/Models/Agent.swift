//  Represents an agent with characteristics that can influence alarm behavior.

import Foundation
import SwiftUI
import CoreData

/// A model representing an agent with unique characteristics.
struct Agent: Identifiable {
    let id: String
    let name: String
    var character: String
    var mood: String
    var motivations: [String]
    let voice: String
    
    /// Initializes a new Agent.
    /// - Parameters:
    ///   - id: A unique identifier for the agent, defaulting to a new UUID string.
    ///   - name: The name of the agent.
    ///   - character: The character trait of the agent.
    ///   - mood: The current mood of the agent.
    ///   - motivations: A list of motivations associated with the agent.
    init(id: String = UUID().uuidString, name: String, character: String, mood: String, motivations: [String], voice: String) {
        self.id = id
        self.name = name
        self.character = character
        self.mood = mood
        self.motivations = motivations
        self.voice = voice
    }
    
    /// Initializes an agent from a Core Data entity.
    /// - Parameter agentEntity: The Core Data entity to convert to an Agent model.
    init(agentEntity: AgentEntity) {
        self.id = agentEntity.id ?? UUID().uuidString
        self.name = agentEntity.name ?? ""
        self.character = agentEntity.character ?? ""
        self.mood = agentEntity.mood ?? ""
        self.motivations = agentEntity.motivations?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
        self.voice = agentEntity.voice ?? "alloy"
    }
    
    /// Converts this agent to a Core Data entity.
    /// - Parameter context: The managed object context for Core Data operations.
    /// - Returns: An `AgentEntity` that represents this agent.
    func toAgentEntity(context: NSManagedObjectContext) -> AgentEntity {
        let fetchRequest: NSFetchRequest<AgentEntity> = AgentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        let existingAgents = try? context.fetch(fetchRequest)
        let agentEntity = existingAgents?.first ?? AgentEntity(context: context)

        agentEntity.id = id
        agentEntity.name = name
        agentEntity.character = character
        agentEntity.mood = mood
        agentEntity.voice = voice
        if motivations.isEmpty {
            agentEntity.motivations = nil
        } else {
            agentEntity.motivations = motivations.joined(separator: ",")
        }


        return agentEntity
    }

}
