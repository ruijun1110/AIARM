import SwiftUI
import CoreData

/// A view for testing agent interactions.
struct AgentTestingView: View {
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State
    @StateObject private var viewModel = AgentTestingViewModel()
    @FetchRequest(entity: AgentEntity.entity(), sortDescriptors: [])
    private var agents: FetchedResults<AgentEntity>
    @State private var selectedAgent: AgentEntity? = nil

    
    var body: some View {
        VStack {
            titleView
            Spacer()
            speakButton
            Spacer()
            agentSelectionView
            instructionText
            Spacer()
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(Color("BG"))
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Subviews
    private var titleView: some View {
        Text("Rehearsal")
            .font(.system(size: 38))
            .padding(.top, 50)
            .foregroundStyle(Color("Highlight"))
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var speakButton: some View {
        Button(action: {
            viewModel.toggleSpeaking()
        }) {
            ZStack {
                Circle()
                    .fill(Color("Theme"))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bell.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                if viewModel.isSpeaking {
                    SoundWaveView()
                }
            }
        }
        .disabled(viewModel.selectedAgent == nil)
    }
    
    private var agentSelectionView: some View {
        VStack {
            Text("Select A Persona")
                .font(.title3)
                .fontWeight(.semibold)
            .foregroundStyle(Color("Highlight"))
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("Theme").opacity(0.3))
                    .stroke(Color("Theme"))
                Picker("Select Agent", selection: $viewModel.selectedAgent) {
                    Text("None").tag(nil as AgentEntity?)
                    ForEach(agents, id: \.id) { agent in
                        Text(agent.name ?? "").tag(agent as AgentEntity?)
                    }
                }
            }
            .frame(maxWidth: 200,maxHeight: 40)
        }
    }
    
    private var instructionText: some View {
        Text("Might take 2-3 second to speak")
            .font(.footnote)
            .foregroundStyle(Color("Placeholder"))
            .padding(.top)
    }
}

/// A view that displays an animated sound wave.
struct SoundWaveView: View {
    @State var animationAmount: CGFloat = 1
    
    var body: some View {
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color("Theme").opacity(0.5), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animationAmount)
                        .opacity(Double(3 - i) / 3)
                        .animation(
                            Animation.easeOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.5),
                            value: animationAmount
                        )
                }
            }
            .onAppear {
                animationAmount = 3
            }
        }
}

/// ViewModel for the AgentTestingView.
class AgentTestingViewModel: ObservableObject {
    @Published var selectedAgent: AgentEntity?
    @Published var isSpeaking = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    private let openAIManager = OpenAIManager()
    private var speakingTask: Task<Void, Error>?
    
    func toggleSpeaking() {
        if isSpeaking {
            stopSpeaking()
        } else {
            speak()
        }
    }
    
    func speak() {
        guard let selectedAgent = selectedAgent else { return }
        
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
        
        speakingTask = Task {
            do {
                openAIManager.initializeAlarmAgent(agent: Agent(agentEntity: selectedAgent), alarmGoal: "wake up")
                if let audioData = try await openAIManager.speak() {
                    try await openAIManager.playSpeech(data: audioData)
                }
            } catch {
                print("Error occurred while speaking: \(error)")
                FileLogger.shared.log("Error occurred while speaking: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Something unexpected has occured. Please try again."
                    self.showErrorAlert = true
                }
            }
            
            DispatchQueue.main.async {
                self.isSpeaking = false
            }
        }
    }
    
    private func speakingLoop() async throws {
        while !Task.isCancelled {
            do {
                if let audioData = try await openAIManager.speak() {
                    try await openAIManager.playSpeech(data: audioData)
                }
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                print("Error occurred during speaking loop: \(error)")
                FileLogger.shared.log("Error occurred during speaking loop: \(error)")
            }
        }
    }
    
    func stopSpeaking() {
        speakingTask?.cancel()
        openAIManager.stopSpeaking()
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}

struct AgentTestingView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        AgentTestingView()
            .environment(\.managedObjectContext, context)
    }
}
