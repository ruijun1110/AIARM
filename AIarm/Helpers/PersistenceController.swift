import CoreData

// Manage the Core Data stack
struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AIarmModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        createDefaultAgentIfNeeded()
    }
    
    private func createDefaultAgentIfNeeded() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<AgentEntity> = AgentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Default")
        
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                let defaultAgent = AgentEntity(context: context)
                defaultAgent.id = "default_agent_123"
                defaultAgent.name = "Default"
                defaultAgent.character = "Best Friend"
                defaultAgent.mood = "Joyful"
                defaultAgent.voice = "Alloy"
                
                try context.save()
            }
        } catch {
            print("Error creating default agent: \(error)")
        }
    }
    
    func clearAllData() {
        let entities = container.managedObjectModel.entities
        entities.compactMap({ $0.name }).forEach(clearTable)
    }

    private func clearTable(_ entity: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try container.viewContext.execute(deleteRequest)
            try container.viewContext.save()
        } catch {
            print("Failed to clear table \(entity): \(error)")
        }
    }
}
