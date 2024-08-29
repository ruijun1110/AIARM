//
//  EditPage.swift
//  AIarm
//
//  Created by Raymond Wang on 5/16/24.
//

import SwiftUI
import CoreData

/// A view for creating or editing an alarm.
struct AlarmEditView: View {
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    let isEditing: Bool
    let onSave: (Alarm) -> Void
    let onDelete: () -> Void
    
    // MARK: - State
    @State private var alarmEntity: AlarmEntity?
    
    @State private var id: String = UUID().uuidString
    @State private var time: Date = Date()
    @State private var isOn: Bool = true
    @State private var isGoalEmpty = false
    @State private var goal: String = ""
    @State private var interval: Int = 1
    @State private var repeatCount: Int = 1
    @State private var selectedAgent: AgentEntity?
    @State private var repeatAlarm: Bool = false
    
    @State private var shouldWiggleGoal = false
    @State private var isGoalValid = true
    
    @State private var goalCharacterLimit = 50
    @State private var isGoalOverLimit = false
    
    @State private var showingDefaultAgentConfirmation = false
    @State private var lastAddedAlarm: Alarm?

    
    @State private var showingSpeakingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case goal
    }
    
    // MARK: - Constant
    let characterNames = ["Tina", "Ricky", "Jimmy"]
    let availableIntervals = [1, 5, 10, 15]
    let availableCounts = [1, 2, 3, 4, 5]

    
    @FetchRequest(entity: AgentEntity.entity(), sortDescriptors: [])
    private var agents: FetchedResults<AgentEntity>
    
    init(alarm: Alarm?, isEditing: Bool, onSave: @escaping (Alarm) -> Void, onDelete: @escaping () -> Void) {
        self.isEditing = isEditing
        self.onSave = onSave
        self.onDelete = onDelete
        if let alarm = alarm {
            let fetchRequest: NSFetchRequest<AlarmEntity> = AlarmEntity.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", alarm.id as CVarArg)
            _alarmEntity = State(initialValue: (try? PersistenceController.shared.container.viewContext.fetch(fetchRequest).first) ?? nil) // TODO: Streamline this with the similar code in else section
            _time = State(initialValue: alarm.time)
            _isOn = State(initialValue: alarm.isOn)
            _goal = State(initialValue: alarm.goal)
            _selectedAgent = State(initialValue: alarm.agent?.toAgentEntity(context: PersistenceController.shared.container.viewContext))

        } else {
            _alarmEntity = State(initialValue: nil)
            _time = State(initialValue: Date())
            _isOn = State(initialValue: true)
            _goal = State(initialValue: "")
            _selectedAgent = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationView {
                List {
                    timeSection()
                    goalSection()
                    personaSection()
                    Section{Spacer()}.listRowBackground(Color("BG"))
                    deleteButton()
                }
                .onAppear {
                    if let agent = alarmEntity?.agent {
                        selectedAgent = agent
                    }
                }
                .listSectionSpacing(8)
                .background(Color("BG"))
                .scrollContentBackground(.hidden)
                .dismissKeyboardOnTap()
                .navigationTitle(isEditing ? "Edit Alarm" : "New Alarm")
                .navigationBarTitleDisplayMode(.inline)
                .foregroundStyle(.white)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing:
                        Group {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color("Theme")))
                                    .scaleEffect(0.8)
                            } else {
                                Button("Save") {
                                    saveAlarm()
                                }
                                .disabled(isSaving)
                            }
                        }
                )
                .toolbarBackground(Color("BG"), for: .navigationBar)
        }
        .overlay(
            Group {
                if isSaving {
                    Color.black.opacity(0.1)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        )
        .alert(isPresented: $showingSpeakingErrorAlert){
            Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    primaryButton: .default(Text("Retry")) {
                        if let alarm = lastAddedAlarm {
                            isSaving = true
                            retryAddAlarm(alarm)
                        }
                    },
                    secondaryButton: .cancel(){
                        lastAddedAlarm = nil
                        isSaving = false
                        presentationMode.wrappedValue.dismiss()
                    }
                )
        }
        .sheet(isPresented: $showingDefaultAgentConfirmation) {
            GeometryReader { geometry in
                ZStack {
                    Color("BG").edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Text("Confirm Save")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("Highlight"))
                        
                        Text("No persona selected. Proceed with default persona?")
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color("Highlight"))
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                showingDefaultAgentConfirmation = false
                            }
                            .foregroundColor(.red)
                            .frame(width: geometry.size.width * 0.4, height: 40)
                            .background(Color.white)
                            .cornerRadius(8)
                            
                            Button("Confirm") {
                                showingDefaultAgentConfirmation = false
                                saveAlarmAction()
                            }
                            .foregroundColor(.white)
                            .frame(width: geometry.size.width * 0.4, height: 40)
                            .background(Color("Theme"))
                            .cornerRadius(8)
                        }
                    }
                    .frame(width: geometry.size.width)
                }
            }
            .presentationDetents([.fraction(0.25)])
        }
        
    }
    
    private func timeSection() -> some View {
        Section{
            DatePicker("Select Time", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                .foregroundStyle(Color("Highlight"))
                .colorMultiply(Color("Theme"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("Theme"))
                        .frame(width: 315)
                )
        } header: {
            Text("Alarm Time")
                .foregroundStyle(Color("Highlight"))
                .font(.system(size: 16))
        }
        .listRowBackground(Color("BG"))
    }
    
    private func goalSection() -> some View {
        Section{
            HStack{
                Text("Alarm Goal")
                    .foregroundStyle(Color("Highlight"))
                    .font(.system(size: 16))
                    .padding(.leading)
                TextField("", text: $goal, prompt: Text("What is it for?")
                    .foregroundStyle(Color("Placeholder"))
                )
                .onChange(of: goal) { _, newValue in
                    isGoalValid = !newValue.isEmpty && newValue.containsOnlyAlphabets
                    isGoalOverLimit = newValue.count > goalCharacterLimit
                }
                .focused($focusedField, equals: .goal )
                .padding(10)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isGoalValid && !isGoalOverLimit ? Color("Theme") : Color("warning"))
            )
            .wiggle($shouldWiggleGoal)
        }
        .listRowBackground(Color("BG"))
    }
    
    private func personaSection() -> some View {
        Section{
            HStack {
                Text("Persona")
                    .foregroundStyle(Color("Highlight"))
                    .font(.system(size: 16))
                    .padding(.horizontal)
                
                Picker("", selection: $selectedAgent) {
                    Text("None").tag(nil as AgentEntity?)
                    ForEach(agents, id: \.id) { agent in
                        Text(agent.name ?? "").tag(agent as AgentEntity?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundStyle(Color("Highlight"))
                .tint(Color("Theme"))
                .padding(10)
                .tint(Color("BG"))
                .onChange(of: selectedAgent) { oldValue, newValue in
                    print("Selected Agent: \(newValue?.name ?? "None")")
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("Theme"))
            )
        }
        .listRowBackground(Color("BG"))
    }
    
    private func repeatAlarmSection() -> some View {
        Section{
            Toggle("Repeat Alarm?", isOn: $repeatAlarm)
                .foregroundStyle(Color("Highlight"))
                .tint(Color("Theme"))
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("Theme"))
                )
            if repeatAlarm {
                HStack {
                    Text("Repeat every")
                        .foregroundStyle(Color("Highlight"))
                        .padding()
                    Picker("", selection: $interval) {
                        ForEach(availableIntervals, id: \.self) { interval in
                            Text("\(interval) min")
                        }
                    }
                    .foregroundStyle(Color("Highlight"))
                    .tint(Color("Theme"))
                    .padding()
                    .pickerStyle(MenuPickerStyle())
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("Theme"))
                )
                HStack {
                    Text("Repeat")
                        .foregroundStyle(Color("Highlight"))
                        .padding()
                    Picker("", selection: $repeatCount) {
                        ForEach(availableCounts, id: \.self) { count in
                            Text("\(count) times")
                        }
                    }
                    .foregroundStyle(Color("Highlight"))
                    .tint(Color("Theme"))
                    .padding()
                    .pickerStyle(MenuPickerStyle())
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("Theme"))
                )
            }
        }
        .listRowBackground(Color("BG"))
    }
    
    private func deleteButton() -> some View {
        Section{
            if isEditing {
                HStack{
                        Button(action: {
                            onDelete()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Delete")
                                .padding(12)
                                .foregroundColor(Color("warning"))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color("Highlight"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .background(Color("BG"))
            }
        }
        .listRowBackground(Color("BG"))
    }
    
    private func getDefaultAgent() -> AgentEntity? {
        let fetchRequest: NSFetchRequest<AgentEntity> = AgentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", "default_agent_123")
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching default agent: \(error)")
            return nil
        }
    }
    
    private func saveAlarm() {
        isGoalEmpty = goal.trimmingCharacters(in:
                .whitespacesAndNewlines).isEmpty
    
        if isGoalEmpty || isGoalOverLimit{
            isGoalValid = false
            shouldWiggleGoal = true
        }
            
        // If any field is invalid or empty, don't proceed with saving
        if !isGoalValid || isGoalEmpty || isGoalOverLimit {
            focusedField = .goal
            return
        }
        
        // Check if the default agent is selected
        if (selectedAgent == nil) {
            showingDefaultAgentConfirmation = true
        } else {
            saveAlarmAction()
        }
    }
    
    private func retryAddAlarm(_ alarm: Alarm){
        FileLogger.shared.log("Edit view is retrying to process alarm \(alarm.id)")
        Task{
            do{
                try await AlarmManager.shared.saveAndScheduleAlarm(alarm)
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    showingSpeakingErrorAlert = true
                    errorMessage = "An error occurred while saving the alarm. Would you like to try again?"
                }
            }
        }
    }
    
    private func saveAlarmAction() {
        isSaving = true
        // Check if the alarm time is in the past
        let now = Date()
        var alarmTime = time
        print(alarmTime)
        if alarmTime <= now {
            // If the time has passed, set it for tomorrow
            alarmTime = Calendar.current.date(byAdding: .day, value: 1, to: alarmTime) ?? alarmTime
        }
        
        let alarm = Alarm(
            id: alarmEntity?.id ?? UUID().uuidString,
            time: alarmTime,
            isOn: true,
            goal: goal.capitalized,
            repeatCount: repeatCount,
            interval: interval,
            agent: selectedAgent.map { Agent(agentEntity: $0)} ?? Agent(agentEntity: getDefaultAgent()!)
        )
        lastAddedAlarm = alarm
        print("Edit view is processing alarm \(alarm.id)")
        FileLogger.shared.log("Edit view is processing alarm \(alarm.id)")
        Task{
            do{
                try await AlarmManager.shared.saveAndScheduleAlarm(alarm)
                await MainActor.run {
                    isSaving = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    showingSpeakingErrorAlert = true
                    errorMessage = "An error occurred while saving the alarm. Would you like to try again?"
                }
            }
        }
    }
}

struct AlarmEditView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        
        let alarm = Alarm(time: Date(), isOn: true, goal: "", repeatCount: 1, interval: 5)
        
        return AlarmEditView(alarm: alarm, isEditing: true, onSave: { _ in }, onDelete: {})
            .environment(\.managedObjectContext, context)
    }
}
