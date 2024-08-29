import SwiftUI
import CoreData

/// Displays a list of agents and provides options to edit or add new agents.
struct AgentsView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - FetchRequest
    @FetchRequest(
        entity: AgentEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AgentEntity.name, ascending: true)]
    ) var agentEntities: FetchedResults<AgentEntity>
        
    // MARK: - State
    @State private var selectedAgent: AgentEntity?
    @Binding var showingAddAgentView: Bool

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Persona")
                        .font(.system(size: 38))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(Color("Highlight"))
                        .padding(.top, 50)
                    ForEach(agentEntities, id: \.self) { agentEntity in
                        AgentCard(agent: agent(from: agentEntity))
                            .onTapGesture{
                                selectedAgent = agentEntity
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color("BG"))
        .sheet(item: $selectedAgent) { agent in
                    AgentEditView(agent: Agent(agentEntity: agent), isEditing: true, onSave: { savedAgent in
                        updateAgent(savedAgent)
                        selectedAgent = nil
                    }, onDelete: {
                        deleteAgent(agent)
                        selectedAgent = nil
                    })
                }
        .sheet(isPresented: $showingAddAgentView) {
            AgentEditView(agent: nil, isEditing: false, onSave: { savedAgent in
                addAgent(savedAgent)
                showingAddAgentView = false
            }, onDelete: {})
        }
    }
    
    // MARK: - Private Views
    private func agent(from agentEntity: AgentEntity) -> Binding<Agent> {
            Binding(
                get: { Agent(agentEntity: agentEntity) },
                set: { updatedAgent in
                    updateAgent(updatedAgent)
                }
            )
        }
    
    // MARK: - CRUD Operations
    /// Adds a new agent to the context and saves it.
    private func addAgent(_ agent: Agent) {
        var cleanedAgent = agent
        removeEmptyMotivations(agent: &cleanedAgent)
        let agentEntity = cleanedAgent.toAgentEntity(context: viewContext)
        saveContext()
    }
    
    /// Updates an existing agent's details in the context and saves it.
    private func updateAgent(_ agent: Agent) {
        var cleanedAgent = agent
        removeEmptyMotivations(agent: &cleanedAgent)
        if let existingEntity = agentEntities.first(where: { $0.id == cleanedAgent.id }) {
            updateAgentEntity(existingEntity, with: cleanedAgent)
            saveContext()
        }
    }
    
    /// Deletes an agent from the context and saves the changes.
    private func deleteAgent(_ agentEntity: AgentEntity) {
        AgentManager.shared.deleteAgent(agentEntity)
    }
    
    /// Remove motivations that have no text entry in the list
    private func removeEmptyMotivations(agent: inout Agent) {
        agent.motivations.removeAll { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    /// Updates the properties of the `AgentEntity` from the `Agent` model.
    private func updateAgentEntity(_ entity: AgentEntity, with agent: Agent) {
        entity.name = agent.name
        entity.character = agent.character
        entity.mood = agent.mood
        entity.motivations = agent.motivations.joined(separator: ",")
    }
    
    /// Saves the current state of the context to the persistent store.
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
            FileLogger.shared.log("Error saving managed object context: \(error)")
        }
    }
}

#Preview {
    AgentsView(showingAddAgentView: .constant(false))
}
