import Foundation
import CoreData

class AgentManager {
    static let shared = AgentManager()
    
    private init() {}
    
    func deleteAgent(_ agentEntity: AgentEntity) {
        let context = PersistenceController.shared.container.viewContext
        let alarmFetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        alarmFetchRequest.predicate = NSPredicate(format: "agent == %@", agentEntity)

        
        do {
            let alarmsToUpdate = try context.fetch(alarmFetchRequest)
            
            for alarmEntity in alarmsToUpdate {
                // Set agent to nil
                alarmEntity.agent = nil
                
                // If the alarm is turned on, cancel and reschedule notifications
                if alarmEntity.isOn {
                    let alarm = Alarm(alarmEntity: alarmEntity)
                    AlarmManager.shared.cancelAlarm(for: alarm)
                    Task{
                        do{
                            try await AlarmManager.shared.saveAndScheduleAlarm(alarm)
                        } catch {
                            print("Error rescheduling agent")
                        }
                    }
                }
            }
            
            context.delete(agentEntity)
            try context.save()
        } catch {
            print("Error deleting agent and updating alarms: \(error)")
            FileLogger.shared.log("Error deleting agent and updating alarms: \(error)")
        }
    }
}
