import SwiftUI
import CoreData
import AVFoundation

/// A view for editing an agent's details or creating a new agent.
struct AgentEditView: View {
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Properties
    let isEditing: Bool
    let onSave: (Agent) -> Void
    let onDelete: () -> Void
    
    // MARK: - State
    @State private var agentEntity: AgentEntity?
    @State private var id: String = UUID().uuidString
    @State private var name: String = ""
    @State private var character: String = ""
    @State private var mood: String = "Chill"
    @State private var voice: String = "Alloy"
    @State private var motivations: [String] = []
    @State private var isDefaultAgent: Bool = false
    @State private var audioSession: AVAudioSession?
    @State private var showingDeleteConfirmation = false
    
    @FocusState private var focusedField: Field?

    @State private var shouldWiggleName = false
    @State private var shouldWiggleCharacter = false
    @State private var isNameEmpty = false
    @State private var isCharacterEmpty = false
    @State private var isNameValid = true
    @State private var isCharacterValid = true
    
    @State private var nameCharacterLimit = 6
    @State private var nameCount: Int = 0
    @State private var descriptionCharacterLimit = 15
    @State private var characterCount: Int = 0
    @State private var isNameOverLimit = false
    @State private var isDescriptionOverLimit = false
    
    // MARK: - Constants
    let availableMoods = ["Joyful", "Angry", "Panic", "Chill", "Loving"]
    let availableVoices = ["Alloy", "Echo", "Fable", "Onyx", "Nova", "Shimmer"]
    enum Field: Hashable {
        case name
        case character
    }

    
    init(agent: Agent?, isEditing: Bool, onSave: @escaping (Agent) -> Void, onDelete: @escaping () -> Void) {
        self.isEditing = isEditing
        self.onSave = onSave
        self.onDelete = onDelete
        UIToolbar.appearance().tintColor = UIColor(Color("Highlight"))
        if let agent = agent {
            let fetchRequest: NSFetchRequest<AgentEntity> = AgentEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", agent.id as CVarArg)
            _agentEntity = State(initialValue: (try? PersistenceController.shared.container.viewContext.fetch(fetchRequest).first) ?? nil)
            _isDefaultAgent = State(initialValue: agent.id == "default_agent_123")
            _name = State(initialValue: agent.name)
            _nameCount = State(initialValue: agent.name.count)
            _character = State(initialValue: agent.character)
            _mood = State(initialValue: agent.mood)
            _motivations = State(initialValue: agent.motivations)
            _voice = State(initialValue: agent.voice)
            _characterCount = State(initialValue: agent.character.count )
        }
        else {
            _agentEntity = State(initialValue: nil)
            _name = State(initialValue: "")
            _character = State(initialValue: "")
            _mood = State(initialValue: "Chill")
            _motivations = State(initialValue: [])
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section{
                    ValidatedTextField(
                        text: $name,
                        placeholder: "Enter a nickname",
                        isValid: $isNameValid,
                        shouldWiggle: $shouldWiggleName
                    )
                    .onChange(of: name) { _, newValue in
                        isNameValid = !newValue.isEmpty && newValue.containsOnlyAlphabets
                        isNameOverLimit = newValue.count > nameCharacterLimit
                        nameCount = newValue.count
                    }
                    .focused($focusedField, equals: .name)
                } header: {
                    HStack{
                        Text("Name")
                            .foregroundStyle(Color("Highlight"))
                            .font(.system(size: 16))
                        Spacer()
                        Text("\(nameCount)/\(nameCharacterLimit)")
                            .foregroundStyle(shouldWiggleName || isNameOverLimit ? Color("warning") : Color("Placeholder"))
                            .font(.system(size: 14))
                    }
                }
                .listRowBackground(Color("BG"))
                
                
                Section{
                    ValidatedTextField(
                        text: $character,
                        placeholder: "e.g. partner, gym buddy, teacher",
                        isValid: $isCharacterValid,
                        shouldWiggle: $shouldWiggleCharacter
                    )
                    .disabled(isDefaultAgent)
                    .focused($focusedField, equals: .character)
                    .onChange(of: character) { _, newValue in
                        isCharacterValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        isDescriptionOverLimit = newValue.count > descriptionCharacterLimit
                        characterCount = newValue.count
                    }
                } header: {
                    HStack {
                            Text("Personality")
                                .foregroundStyle(Color("Highlight"))
                                .font(.system(size: 16))
                            Spacer()
                            Text("\(characterCount)/\(descriptionCharacterLimit)")
                                .foregroundStyle(shouldWiggleCharacter || isDescriptionOverLimit ? Color("warning") : Color("Placeholder"))
                                .font(.system(size: 14))
                        }
                }
                .listRowBackground(Color("BG"))
                
                Section {
                    CustomMoodPicker(selection: $mood, options: availableMoods)
                        .disabled(isDefaultAgent)
                } header: {
                    Text("Mood")
                        .foregroundStyle(Color("Highlight"))
                        .font(.system(size: 16))
                }
                .listRowBackground(Color("BG"))
                
                voiceSelectionSection()
                
                Section{
                    MotivationsView(motivations: $motivations, isEditable: !isDefaultAgent)
                    .background(Color("BG"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("Theme"))
                    )
                } header: {
                    HStack {
                        Text("Motivations")
                            .foregroundStyle(Color("Highlight"))
                            .font(.system(size: 16))
                        Spacer()
                        
                        Button(action: {
                            addMotivation()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                            }
                            .foregroundColor(Color("Theme"))
                        }
                        .disabled(isDefaultAgent)
                    }
                }
                .listRowBackground(Color("BG"))
                
                Section{Spacer()}.listRowBackground(Color("BG"))
                
                Section{
                    if isEditing && !isDefaultAgent {
                            HStack {
                                Button(action: {
                                    prepareAgentDeletion()
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
            .listStyle(InsetGroupedListStyle())
            .background(Color("BG"))
            .scrollContentBackground(.hidden)
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Persona" : "New Persona")
            .navigationBarTitleDisplayMode(.inline)
            .listSectionSpacing(-10)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveAgent()
                }
                .disabled(isDefaultAgent)
            )
            .toolbarBackground(Color("BG"), for: .navigationBar)
            .onAppear {
                setupAudioSession()
            }
            
        }
        .sheet(isPresented: $showingDeleteConfirmation) {
            GeometryReader { geometry in
                ZStack {
                    Color("BG").edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Text("Confirm Deletion")
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("Highlight"))
                        
                        Text("Deleting this agent will set all associated alarms to use the default agent. Are you sure you want to proceed?")
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color("Highlight"))
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                showingDeleteConfirmation = false
                            }
                            .foregroundColor(.red)
                            .frame(width: geometry.size.width * 0.4, height: 44)
                            .background(Color.white)
                            .cornerRadius(8)
                            
                            Button("Confirm") {
                                showingDeleteConfirmation = false
                                deleteAgent()
                            }
                            .foregroundColor(.white)
                            .frame(width: geometry.size.width * 0.4, height: 44)
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
    
    // MARK: - Private Methods
    private func addMotivation() {
        motivations.append("")
    }
    
    private func deleteMotivation(at offsets: IndexSet) {
        motivations.remove(atOffsets: offsets)
    }
    
    private func saveAgent() {
        isNameEmpty = name.trimmingCharacters(in:
                .whitespacesAndNewlines).isEmpty
        isCharacterEmpty = character.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
        // If any field is invalid or empty, don't proceed with saving
        if !isNameValid || isNameEmpty || isCharacterEmpty || isNameOverLimit || isDescriptionOverLimit {
            // Optionally, you can set focus to the first invalid field
            if isNameEmpty || !isNameValid || isNameOverLimit {
                isNameValid = false
                focusedField = .name
                shouldWiggleName = true
            } else if isCharacterEmpty || isDescriptionOverLimit {
                isCharacterValid = false
                focusedField = .character
                shouldWiggleCharacter = true
            }
            return
        }
        
        
        let agentEntity: AgentEntity
        if let existingAgent = self.agentEntity {
            agentEntity = existingAgent
        } else {
            agentEntity = AgentEntity(context: viewContext)
            agentEntity.id = UUID().uuidString
        }
        agentEntity.name = name
        agentEntity.character = character
        agentEntity.mood = mood
        agentEntity.voice = voice
        agentEntity.motivations = motivations.joined(separator: ",")
        
        do {
            try viewContext.save()
            onSave(Agent(agentEntity: agentEntity))
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save agent: \(error)")
            FileLogger.shared.log("Failed to save agent: \(error)")
        }
    }
    
    private func prepareAgentDeletion() {
       showingDeleteConfirmation = true
    }
    
    private func deleteAgent() {
        onDelete()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playback, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            FileLogger.shared.log("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func voiceSelectionSection() -> some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<(availableVoices.count + 1) / 2, id: \.self) { rowIndex in
                    HStack(spacing: 16) {
                        ForEach(0..<2) { columnIndex in
                            let index = rowIndex * 2 + columnIndex
                            if index < availableVoices.count {
                                VoiceOptionView(
                                    voiceOption: availableVoices[index],
                                    isSelected: voice == availableVoices[index],
                                    action: { voice = availableVoices[index] }
                                )
                                .disabled(isDefaultAgent)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Voice")
                .foregroundStyle(Color("Highlight"))
                .font(.system(size: 16))
        }
        .listRowBackground(Color("BG"))
    }
}

struct MotivationsView: View {
    @Binding var motivations: [String]
    var isEditable: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(motivations.indices, id: \.self) { index in
                MotivationItemView(
                    motivation: $motivations[index],
                    onDelete: {
                        if isEditable {
                            motivations.remove(at: index)
                        }
                    },
                    isEditable: isEditable
                )
                
                if index < motivations.count - 1 {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .background(Color("BG"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("Theme"))
        )
    }
}

struct MotivationItemView: View {
    @Binding var motivation: String
    let onDelete: () -> Void
    var isEditable: Bool
    
    var body: some View {
        HStack{
            TextField("What should the persona mention?", text: $motivation)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .disabled(!isEditable)
            if isEditable {
                Button(action: onDelete) {
                    Image(systemName: "x.circle")
                        .foregroundColor(.red)
                }
                .padding(.trailing, 8)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color("BG"))
    }
}

struct VoiceOptionView: View {
    let voiceOption: String
    let isSelected: Bool
    let action: () -> Void
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        HStack {
                    Button(action: playAudio) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(isSelected ? Color("Theme") : .gray)
                            .frame(width: 30, height: 44)  // Increase tap area
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: action) {
                        HStack {
                            Text(voiceOption)
                                .foregroundColor(isSelected ? .white : .gray)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("Theme"))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color("Theme").opacity(0.3) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color("Theme") : Color.gray, lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func playAudio() {
        let soundName = "\(voiceOption.lowercased())"
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("Sound file not found")
            FileLogger.shared.log("Sound file not found")
            return
        }
            
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
            FileLogger.shared.log("Error playing audio: \(error.localizedDescription)")
        }
    }
}

struct CustomMoodPicker: View {
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Selection indicator
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color("Theme").opacity(0.3))
                    .stroke(Color("Theme"), lineWidth: 1)
                    .frame(width: geometry.size.width / CGFloat(options.count) - 4)
                    .padding(2)
                    .offset(x: CGFloat(options.firstIndex(of: selection) ?? 0) * (geometry.size.width / CGFloat(options.count)))
                    .animation(.easeInOut(duration: 0.3), value: selection)
                
                // Buttons
                HStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            withAnimation {
                                selection = option
                            }
                        }) {
                            Text(option)
                                .padding(.vertical, 8)
                                .frame(width: geometry.size.width / CGFloat(options.count), height: geometry.size.height)
                                .foregroundColor(selection == option ? Color("Highlight") : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .frame(height: 40)
        .background(Color("BG"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("Theme"))
        )
    }
}


struct AgentEditView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let agent = Agent(name: "", character: "", mood: "Chill", motivations: [], voice: "Alloy")
        return AgentEditView(agent: agent, isEditing: true, onSave: { _ in }, onDelete: {})
            .environment(\.managedObjectContext, context)
    }
}
