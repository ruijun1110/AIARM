import Foundation
import OpenAI

/// Notification name for API key changes
extension Notification.Name {
    static let apiKeyDidChange = Notification.Name("apiKeyDidChange")
}

/// Manages configurations for accessing and interacting with the OpenAI API.
struct OpenAISettings {
    // MARK: - Shared Instance
    static var shared = OpenAISettings()
    
    // MARK: - User Settings
    /// The username for the current user.
    var username: String {
        get { UserDefaults.standard.string(forKey: "username") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "username") }
    }
     
    /// The OpenAI API key.
    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "openAIApiKey") ?? "" }
        set { 
            UserDefaults.standard.set(newValue, forKey: "openAIApiKey")
            NotificationCenter.default.post(name: .apiKeyDidChange, object: nil)
        }
        
    }
        
    /// Indicates whether the app should be aware of the user's context.
    var contentAwareMode: Bool {
        get { UserDefaults.standard.bool(forKey: "contentAwareMode") }
        set { UserDefaults.standard.set(newValue, forKey: "contentAwareMode") }
    }
    
    // MARK: - OpenAI Configuration
    /// The OpenAI model to use for text generation.
    static let model: Model = .gpt4_o_mini
    
    /// The temperature setting for text generation (controls randomness).
    static let temperature: Double = 0.7
    
    /// The maximum number of tokens to generate in a response.
    static let maxTokens: Int = 100
    
    /// The frequency penalty for text generation (discourages repetition).
    static let frequencyPenalty: Double = 0.5
    
    /// The default voice to use for audio generation.
    static let defaultVoice: AudioSpeechQuery.AudioSpeechVoice = .alloy
}
