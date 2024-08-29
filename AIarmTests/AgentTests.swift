import XCTest
import CoreData
@testable import AIarm

class AgentTests: CoreDataTestCase {
    func testCreateAgent() throws {
        // Given
        let newAgent = Agent(name: "Test Agent", character: "Test Character", mood: "Happy", motivations: ["Test Motivation"], voice: "Alloy")
        
        // When
        let agentEntity = newAgent.toAgentEntity(context: viewContext)
        try viewContext.save()
        
        // Then
        let fetchRequest: NSFetchRequest<AgentEntity> = AgentEntity.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "One agent should be created")
        XCTAssertEqual(results.first?.name, "Test Agent", "Agent name should match")
        XCTAssertEqual(results.first?.character, "Test Character", "Agent character should match")
        XCTAssertEqual(results.first?.mood, "Happy", "Agent mood should match")
        XCTAssertEqual(results.first?.motivations, "Test Motivation", "Agent motivations should match")
        XCTAssertEqual(results.first?.voice, "Alloy", "Agent voice should match")
    }

    func testUpdateAgent() throws {
        // Given
        let agent = Agent(name: "Original Name", character: "Original Character", mood: "Happy", motivations: ["Original Motivation"], voice: "Alloy")
        let agentEntity = agent.toAgentEntity(context: viewContext)
        try viewContext.save()
        
        // When
        agentEntity.name = "Updated Name"
        agentEntity.character = "Updated Character"
        agentEntity.mood = "Sad"
        agentEntity.motivations = "Updated Motivation"
        agentEntity.voice = "Echo"
        try viewContext.save()
        
        // Then
        let fetchRequest: NSFetchRequest<AgentEntity> = AgentEntity.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "There should still be only one agent")
        XCTAssertEqual(results.first?.name, "Updated Name", "Agent name should be updated")
        XCTAssertEqual(results.first?.character, "Updated Character", "Agent character should be updated")
        XCTAssertEqual(results.first?.mood, "Sad", "Agent mood should be updated")
        XCTAssertEqual(results.first?.motivations, "Updated Motivation", "Agent motivations should be updated")
        XCTAssertEqual(results.first?.voice, "Echo", "Agent voice should be updated")
    }

    func testDeleteAgent() throws {
        // Given
        let agent = Agent(name: "Agent to Delete", character: "Character", mood: "Happy", motivations: ["Motivation"], voice: "Alloy")
        let agentEntity = agent.toAgentEntity(context: viewContext)
        try viewContext.save()
        
        // When
        viewContext.delete(agentEntity)
        try viewContext.save()
        
        // Then
        let fetchRequest: NSFetchRequest<AgentEntity> = AgentEntity.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 0, "No agents should remain after deletion")
    }
}
