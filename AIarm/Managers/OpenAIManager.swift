import Foundation
import AVFoundation
import OpenAI


/// Manages interactions with the OpenAI API, including generating text completions, synthesizing speech, and handling audio playback.
class OpenAIManager: NSObject {
    // MARK: - Properties
    private let username: String
    private var openAIClient: OpenAI
    private var agentVoice: AudioSpeechQuery.AudioSpeechVoice = .alloy
    private var alarmGoal: String = "alert"
    
    private var audioSession = AVAudioSession.sharedInstance()
    private var audioPlayer: AVAudioPlayer!
    public var continuation: CheckedContinuation<Void, Error>?  // Continuation to manage async playback
    private var speakingLoop = false
    
    private var messageHistory: [ChatQuery.ChatCompletionMessageParam] = []
    private let voiceDict: [String: AudioSpeechQuery.AudioSpeechVoice] = ["Alloy" : .alloy , "Echo": .echo, "Fable": .fable ,"Onyx": .onyx, "Nova": .nova, "Shimmer": .shimmer]
    
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    override init() {
        self.openAIClient = OpenAI(apiToken: OpenAISettings.shared.apiKey)
        self.username = OpenAISettings.shared.username
        super.init()
        configureAudioSession()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAPIKey), name: .apiKeyDidChange, object: nil)
    }
    
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    /// Initializes the alarm agent with the given parameters.
    /// - Parameters:
    ///   - agent: The Agent to use for the alarm.
    ///   - alarmGoal: The goal or purpose of the alarm.
    func initializeAlarmAgent(agent: Agent, alarmGoal: String) {
        messageHistory.removeAll()
        self.alarmGoal = alarmGoal.isEmpty ? "alert" : alarmGoal
        let prompt = generatePrompt(agent: agent)
        agentVoice = voiceDict[agent.voice] ?? OpenAISettings.defaultVoice
        let systemMessage = ChatQuery.ChatCompletionMessageParam(role: .system, content: prompt)
        if let systemMessage {
            messageHistory.append(systemMessage)
        }
    }
    
    
    /// Generates speech for the alarm.
    /// - Returns: Audio data for the generated speech.
    /// - Throws: An error if speech generation fails.
    func speak() async throws -> Data?{
        do {
            let text = try await generateChatCompletion()
            print("Chat response: \(text)")
            FileLogger.shared.log("Chat response: \(text)")
            let audioData = try await generateSpeech(input: text)
            addNoUserResponseMessage()
            return audioData
        } catch {
            print("Error occurred during speaking loop: \(error)")
            FileLogger.shared.log("Error occurred during speaking loop: \(error)")
            throw error
        }
    }
    
    /// Generates multiple audio responses for an alarm.
    /// - Parameter count: The number of audio responses to generate.
    /// - Returns: An array of audio data.
    /// - Throws: An error if audio generation fails.
    func generateAudios(count: Int) async throws -> [Data] {
        var audioData: [Data] = []
        
        for _ in 0..<count {
            do {
                if let data = try await retryWithExponentialBackoff(maxRetries: maxRetries) {
                    audioData.append(data)
                }
            } catch {
                FileLogger.shared.log("Error generating audio: \(error)")
                throw (error)
            }
        }
        
        return audioData
    }

    
    func stopSpeaking() {
        speakingLoop = false
        audioPlayer?.stop()
    }
    
    func generateSpeech(input: String) async throws -> Data?{
        let query = AudioSpeechQuery(
            model: .tts_1,
            input: input,
            voice: agentVoice,
            responseFormat: .mp3,
            speed: 1.1
        )
        let input = query.input
        guard !input.isEmpty else { return nil }
        do {
            let response = try await openAIClient.audioCreateSpeech(query: query)
            print("Audio created")
            FileLogger.shared.log("Audio created")
            let data = response.audio
            print("isEmpty \(data.isEmpty)")
            FileLogger.shared.log("isEmpty \(data.isEmpty)")
            print("duration: \(audioPlayer?.duration ?? 0)")
            FileLogger.shared.log("duration: \(audioPlayer?.duration ?? 0)")
            return data
        } catch {
            print(error.localizedDescription)
            FileLogger.shared.log(error.localizedDescription)
            throw OpenAIError.noResponseReceived
        }
    }
    
    /// Plays the generated speech.
    /// - Parameter data: The audio data to play.
    /// - Throws: An error if audio playback fails.
    func playSpeech(data: Data) async throws {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.delegate = self
            audioPlayer.rate = 1.8
            audioPlayer.play()
            
            // Wait for playback to finish or be interrupted
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        } catch {
            print("Audio playback error: \(error)")
            FileLogger.shared.log("Audio playback error: \(error)")
            throw OpenAIError.audioPlaybackFailed
        }
    }
    
    // MARK: - Private Methods
    
    @objc private func updateAPIKey() {
        self.openAIClient = OpenAI(apiToken: OpenAISettings.shared.apiKey)
    }
    
    private func configureAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
            FileLogger.shared.log("Failed to configure audio session: \(error)")

        }
    }
    /// Retry loop for voice generation failure handling
    private func retryWithExponentialBackoff(maxRetries: Int) async throws -> Data? {
        var retries = 0
        while retries < maxRetries {
            do {
                return try await speak()
            } catch {
                FileLogger.shared.log("Attempt \(retries + 1) failed: \(error)")
                print("Attempt \(retries + 1) failed: \(error)")
                retries += 1
                if retries < maxRetries {
                    let delay = retryDelay * pow(2, Double(retries - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                throw (error)
            }
        }
        return nil
    }
    
    /// Generates a text prompt for the agent.
    private func generatePrompt(agent: Agent) -> String {
        let basePrompt = """
              You are \(agent.name), a \(agent.character) with a \(agent.mood) demeanor. Your task is to alert \(username) that it's time for \(alarmGoal). To make your alert more effective and personal, mention one of these user motivations: \(agent.motivations.joined(separator: ", ")). Use the motivation to encourage or persuade the user to act. Respond in character, maintaining your mood, using 1-4 complete sentences. Do not break character or explain your role.
    """
        if OpenAISettings.shared.contentAwareMode {
            return basePrompt + " Additionally, be aware of the user's context and surroundings. Adjust your language and approach based on the time of day, potential activities the user might be engaged in, and general situational awareness. Be mindful of privacy and appropriateness in your responses."
        } else {
            return basePrompt
        }
    }
    
    private func addMessage(role: ChatQuery.ChatCompletionMessageParam.Role, content: String) {
        let message = ChatQuery.ChatCompletionMessageParam(role: role, content: content)
        if let message {
            messageHistory.append(message)
        }
    }
    
    private func clearMessageHistory() {
        messageHistory.removeAll()
    }
    
    private func generateChatCompletion() async throws -> String {
        let query = ChatQuery(
            messages: messageHistory,
            model: OpenAISettings.model,
            frequencyPenalty: OpenAISettings.frequencyPenalty,
            maxTokens: OpenAISettings.maxTokens,
            temperature: OpenAISettings.temperature
        )
        let result = try await openAIClient.chats(query: query)
        guard let text = result.choices.first?.message.content?.string else {
            throw OpenAIError.noResponseReceived
        }
        addMessage(role: .assistant, content: text)
        return text
    }
    
    
    private func addNoUserResponseMessage() {
        addMessage(role: .system, content: "no response")
    }
}

// MARK: - AVAudioPlayerDelegate
extension OpenAIManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            continuation?.resume()
        } else {
            continuation?.resume(throwing: OpenAIError.audioPlaybackFailed)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        continuation?.resume(throwing: error ?? OpenAIError.audioPlaybackFailed)
    }
}

// MARK: - OpenAIError
enum OpenAIError: Error {
    case noResponseReceived
    case audioPlaybackFailed
}


