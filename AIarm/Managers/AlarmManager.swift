import Foundation
import UIKit
import CoreData
import UserNotifications
import BackgroundTasks
import AudioToolbox
import AVFoundation


/// Manages the scheduling and handling of alarms within the application.
class AlarmManager: NSObject, UNUserNotificationCenterDelegate {
    /// Shared instance of the AlarmManager.
    static let shared = AlarmManager()
    
    /// Manages interactions with the OpenAI API for generating alarm responses.
    private let openAIManager = OpenAIManager()
    
    /// Handles scheduling and management of local notifications.
    private let notificationCenter: NotificationCenterProtocol
    
    /// Audio player for alarm sounds.
    private var player: AVAudioPlayer?
    
    /// Cache of alarms indexed by their IDs.
    private var alarmCache: [String: Alarm] = [:]
    
    /// Published property to track speaking errors.
    @Published var speakingError: Error?

    
    private var shouldUseUnmutableSound: Bool = false
    
    private override init() {
        self.notificationCenter = UNUserNotificationCenter.current()
        super.init()
        (self.notificationCenter as? UNUserNotificationCenter)?.delegate = self
        initializeCache()
        setupNotificationObservers()
    }
    
    /// Sets up observers for application lifecycle events.
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
            
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
            
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMemoryWarning),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }
    
    @objc private func handleEnterBackground() {
        // Optionally clear the cache when entering background
        // clearCache()
    }
        
    @objc private func handleEnterForeground() {
        // Refresh the cache when entering foreground
        initializeCache()
    }
        
    @objc private func handleMemoryWarning() {
        // Clear the cache on memory warning
        clearCache()
    }
        
    func clearCache() {
        alarmCache.removeAll()
    }
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
        
    private func initializeCache() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
            
        do {
            let alarmEntities = try context.fetch(fetchRequest)
            for alarmEntity in alarmEntities {
                let alarm = Alarm(alarmEntity: alarmEntity)
                alarmCache[alarm.id] = alarm
            }
        } catch {
            print("Error initializing alarm cache: \(error)")
            FileLogger.shared.log("Error initializing alarm cache: \(error)")
        }
    }
    
    /// Saves and schedules an alarm.
    /// - Parameter alarm: The alarm to be saved and scheduled.
    /// - Throws: An error if the saving or scheduling process fails.
    func saveAndScheduleAlarm(_ alarm: Alarm) async throws {
        print("Save and scheduling alarm \(alarm.id)")
        FileLogger.shared.log("Save and scheduling alarm \(alarm.id)")
        let context = PersistenceController.shared.container.viewContext
            
        let alarmEntity: AlarmEntity
        if let existingEntity = getAlarmEntity(for: alarm.id) {
            alarmEntity = existingEntity
        } else {
            alarmEntity = AlarmEntity(context: context)
            alarmEntity.id = alarm.id
        }
            
        updateAlarmEntity(alarmEntity, with: alarm)
        
        do {
            try context.save()
                
            alarmCache[alarm.id] = alarm
            
            cancelAlarm(for: alarm)
            
            if alarm.isOn {
                try await scheduleAlarm(for: alarm)
            }
        } catch {
            print("Failed to save alarm: \(error)")
            FileLogger.shared.log("Failed to save alarm: \(error)")
            throw error
        }
    }

    private func getAlarmEntity(for id: String) -> AlarmEntity? {
        print("Retrieving alarm entity for alarm \(id)")
        FileLogger.shared.log("Retrieving alarm entity for alarm \(id)")
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(fetchRequest).first
    }
        
    private func updateAlarmEntity(_ entity: AlarmEntity, with alarm: Alarm) {
        print("Updating alarm entity for alarm \(alarm.id)")
        FileLogger.shared.log("Updating alarm entity for alarm \(alarm.id)")
        entity.time = alarm.time
        entity.isOn = alarm.isOn
        entity.goal = alarm.goal
        entity.repeatCount = Int64(alarm.repeatCount)
        entity.interval = Int64(alarm.interval)
        entity.agent = alarm.agent?.toAgentEntity(context: PersistenceController.shared.container.viewContext)
    }
    
    /// Schedules a new alarm using the User Notifications framework.
    /// - Parameter alarm: The `Alarm` to schedule.
    func scheduleAlarm(for alarm: Alarm) async throws {
        FileLogger.shared.log("Starting to schedule alarm: \(alarm.id)")
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = alarm.goal
        
        if let defaultSoundURL = Bundle.main.url(forResource: "default", withExtension: "mp3") {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(defaultSoundURL.lastPathComponent))
        } else {
            content.sound = UNNotificationSound.defaultRingtone
        }
        
        // Schedule the notification immediately with default sound
        self.scheduleNotifications(for: alarm, with: content)
        
        // Generate and save audio data
        if let agentId = alarm.agent?.id,
           let agent = getAgent(for: agentId) {
            FileLogger.shared.log("Custom agent found for alarm: \(alarm.id), Agent: \(agent.name)")
            FileLogger.shared.log("Initializing alarm agent")
            self.openAIManager.initializeAlarmAgent(agent: agent, alarmGoal: alarm.goal)
            print("Generating speech audios")
            FileLogger.shared.log("Generating speech audios")
            let audioData = try await self.openAIManager.generateAudios(count: alarm.repeatCount)
            print("Saving speech audio")
            FileLogger.shared.log("Saving speech audio")
            self.saveAudioData(audioData, for: alarm.id)
            print("Updating notification sound with custom audio")
            FileLogger.shared.log("Updating notification sound with custom audio")
            // Update notifications with custom audio if generated successfully
            await MainActor.run {
                self.updateNotificationsWithCustomAudio(for: alarm)
            }
        } else {
            print("Agent not found, scheduling default notification")
            FileLogger.shared.log("Agent not found, scheduled default notification")
            // TODO: Set default ring tone
//            self.scheduleNotifications(for: alarm, with: content)
        }
    }
    
    private func updateNotificationsWithCustomAudio(for alarm: Alarm) {
        FileLogger.shared.log("Updating notifications with custom audio for alarm: \(alarm.id)")
        notificationCenter.getPendingNotificationRequests { requests in
            let alarmRequests = requests.filter { $0.identifier.starts(with: "\(alarm.id)_") }
            for (index, request) in alarmRequests.enumerated() {
                let content = request.content.mutableCopy() as! UNMutableNotificationContent
                let audioFileName = "\(alarm.id)_audio_\(index).wav"
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: audioFileName))
                
                let newRequest = UNNotificationRequest(identifier: request.identifier, content: content, trigger: request.trigger)
                self.notificationCenter.add(newRequest) { error in
                    if let error = error {
                        FileLogger.shared.log("Error updating notification with custom audio: \(error)")
                    } else {
                        FileLogger.shared.log("Successfully updated notification with custom audio")
                    }
                }
            }
        }
    }
    
    /// Schedules notification alerts at 1-minute intervals.
    /// - Parameters:
    ///   - alarm: The `Alarm` associated with the notifications.
    ///   - content: The `UNMutableNotificationContent` containing the notification details.
    private func scheduleNotifications(for alarm: Alarm, with content: UNMutableNotificationContent) {
        let repeatCount = alarm.repeatCount
        print("There are \(repeatCount) noification to schedule")
        FileLogger.shared.log("There are \(repeatCount) noification to schedule")
        let interval = alarm.interval
        for i in 0..<repeatCount {
            print("Scheduling notification #\(i)")
            FileLogger.shared.log("Scheduling notification #\(i)")
            let audioFileName = "\(alarm.id)_audio_\(i).wav"
            
            /// TODO: figure out how to do the unmutable notificarion sound
            if !shouldUseUnmutableSound {
                if alarm.agent != nil {
                    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: audioFileName))
                } else {
                    if let defaultSoundURL = Bundle.main.url(forResource: "default", withExtension: "mp3") {
                        content.sound = UNNotificationSound(named: UNNotificationSoundName(defaultSoundURL.lastPathComponent))
                    } else {
                        content.sound = UNNotificationSound.defaultRingtone
                    }
                }
            } else {
                content.sound = nil  // No sound for the notification itself
            }
            
            
            let triggerDate = Calendar.current.date(byAdding: .minute, value: i*interval, to: alarm.time)!
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute], from: triggerDate), repeats: false)
            
            let request = UNNotificationRequest(identifier: "\(alarm.id)_\(i)", content: content, trigger: trigger)
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling alarm: \(error)")
                    FileLogger.shared.log("Error scheduling alarm: \(error)")
                } else {
                    print("Notification #\(i) is set")
                    FileLogger.shared.log("Notification #\(i) is set")
                }
            }
        }
    }
        
    /// Saves the generated audio data to the device.
    /// - Parameter audioData: An array of `Data` objects representing the audio data.
    private func saveAudioData(_ audioData: [Data], for alarmId: String) {
        let fileManager = FileManager.default
        let librarySoundsDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Sounds")

        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: librarySoundsDir.path) {
            try? fileManager.createDirectory(at: librarySoundsDir, withIntermediateDirectories: true, attributes: nil)
        }

        for (index, data) in audioData.enumerated() {
            let fileURL = librarySoundsDir.appendingPathComponent("\(alarmId)_audio_\(index).wav")
            do {
                try data.write(to: fileURL, options: .atomic)
                UserDefaults.standard.set(fileURL.absoluteString, forKey: "\(alarmId)_audioURL_\(index)")
            } catch {
                print("Error saving audio data: \(error)")
                FileLogger.shared.log("Error saving audio data: \(error)")
            }
        }
    }

    
    /// Cancels an existing alarm.
    /// - Parameter alarm: The `Alarm` to cancel.
    func cancelAlarm(for alarm: Alarm) {
        print("Canceling alarm \(alarm.id)")
        FileLogger.shared.log("Canceling alarm \(alarm.id)")
        for i in 0..<alarm.repeatCount {
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: ["\(alarm.id)_\(i)"])
            print("alarm notification: \(alarm.id)_\(i) is removed.")
            FileLogger.shared.log("alarm notification: \(alarm.id)_\(i) is removed.")
        }
    }
    
    /// Handles actions taken from the notification center.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        FileLogger.shared.log("Notification received: \(response.notification.request.identifier)")
        handleTriggeredNotification(request: response.notification.request)
        completionHandler()
    }
    
    /// Handles notifications when the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handleTriggeredNotification(request: notification.request)
        completionHandler([.banner, .sound])
    }
    
    /// Handles a triggered notification by turning off the corresponding alarm.
    /// - Parameter request: The notification request that was triggered.
    func handleTriggeredNotification(request: UNNotificationRequest) {
        print("Handling triggered notification")
        FileLogger.shared.log("Handling triggered notification")
        let alarmId = request.identifier.components(separatedBy: "_").first
        print("Turning off alarm id: \(alarmId ?? "nil")")
        FileLogger.shared.log("Turning off alarm id: \(alarmId ?? "nil")")
        if let alarmId = alarmId{
            print("Setting isOn to off")
            FileLogger.shared.log("Setting isOn to off")
            updateAlarmIsOn(for: alarmId, isOn: false)
        }
    }
    
    func checkAndUpdateAlarmStatus() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isOn == true")

        do {
            let alarms = try context.fetch(fetchRequest)
            let currentDate = Date()

            for alarmEntity in alarms {
                guard let alarmTime = alarmEntity.time, let alarmId = alarmEntity.id else { continue }
                FileLogger.shared.log("Alarm Time = \(alarmTime)")
                let timeDifference = currentDate.timeIntervalSince(alarmTime)
                FileLogger.shared.log("Current Time = \(currentDate)")
                FileLogger.shared.log("Alarm \(alarmId) time difference: \(timeDifference) seconds")

                if timeDifference >= -60 {
                    FileLogger.shared.log("Turning off alarm \(alarmId)")
                    updateAlarmIsOn(for: alarmId, isOn: false)
                }
            }
        } catch {
            print("Error fetching alarms: \(error)")
            FileLogger.shared.log("Error fetching alarms: \(error)")
        }
    }
    
    private func updateAlarmIsOn(for alarmId: String, isOn: Bool) {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", alarmId as CVarArg)
        
        do {
            let alarmEntities = try context.fetch(fetchRequest)
            print("Fetched alarm entity")
            FileLogger.shared.log("Fetched alarm entity")
            if let alarmEntity = alarmEntities.first, alarmEntity.isOn {
                alarmEntity.isOn = isOn
                print("Saving alarm entity")
                FileLogger.shared.log("Saving alarm entity")
                try context.save()
                if var cachedAlarm = alarmCache[alarmId] {
                    cachedAlarm.isOn = isOn
                    alarmCache[alarmId] = cachedAlarm
                }
                        
                if !isOn {
                    if let alarm = getAlarm(for: alarmId) {
                        cancelAlarm(for: alarm)
                    }
                }
            } else {
                FileLogger.shared.log("No alarm found with id: \(alarmId)")
            }
        } catch {
            print("Error updating alarm isOn: \(error)")
            FileLogger.shared.log("Error updating alarm isOn: \(error)")
        }
    }

    /// Fetches an `Alarm` instance corresponding to a notification identifier.
    func getAlarm(for identifier: String) -> Alarm? {
        if let cachedAlarm = alarmCache[identifier] {
            return cachedAlarm
        }
        
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", identifier)
            
        do {
            let alarmEntities = try context.fetch(fetchRequest)
            if let alarmEntity = alarmEntities.first {
                let alarm = Alarm(alarmEntity: alarmEntity)
                alarmCache[identifier] = alarm
                return alarm
            }
        } catch {
            print("Error fetching alarm: \(error)")
            FileLogger.shared.log("Error fetching alarms: \(error)")
        }
            
        return nil
    }
    
    // TODO: modify the function so that it is not creating new agent every time
    private func getAgent(for identifier: String) -> Agent? {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<AgentEntity> = AgentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", identifier)
            
        do {
            let agentEntities = try context.fetch(fetchRequest)
            if let agentEntity = agentEntities.first {
                return Agent(agentEntity: agentEntity)
            }
        } catch {
            print("Error fetching agent: \(error)")
            FileLogger.shared.log("Error fetching agent: \(error)")
        }
        
        return nil
    }
}
