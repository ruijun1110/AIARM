// In SettingView.swift

import SwiftUI
import OpenAI

struct SettingView: View {
    @State private var username: String = OpenAISettings.shared.username
    @State private var apiKey: String = OpenAISettings.shared.apiKey
    @State private var contentAwareMode: Bool = OpenAISettings.shared.contentAwareMode
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: UsernameEditView(username: $username)) {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(username).foregroundColor(Color("Theme"))
                    }
                }
                .listRowBackground(Color("BG"))
                
                NavigationLink(destination: APIKeyEditView(apiKey: $apiKey)) {
                    HStack {
                        Text("OpenAI API Key")
                        Spacer()
                        Text(apiKey.isEmpty ? "Not Set" : "••••••••").foregroundColor(Color("Theme"))
                    }
                }
                .listRowBackground(Color("BG"))
                
                Toggle("Content Aware Mode", isOn: $contentAwareMode)
                    .tint(Color("Theme"))
                    .listRowBackground(Color("BG"))
                    .onChange(of: contentAwareMode) { _, newValue in
                        OpenAISettings.shared.contentAwareMode = newValue
                    }
                
                
                NavigationLink(destination: FAQView()) {
                    Text("FAQ")
                }
                .listRowBackground(Color("BG"))
                
                NavigationLink(destination: TermsAndPolicyView()) {
                    Text("Terms & Policy")
                }
                .listRowBackground(Color("BG"))
                
//                NavigationLink(destination: LogViewerView()) {
//                    Text("View Logs")
//                }
//                .listRowBackground(Color("BG"))
            }
            .listStyle(.plain)
            .navigationTitle("Settings")
            .background(Color("BG"))
            .scrollContentBackground(.hidden)
        }
        .background(Color("BG"))
    }
}

struct UsernameEditView: View {
    @Binding var username: String
    @Environment(\.presentationMode) var presentationMode
    @State private var tempUsername: String = ""
    @State private var isUsernameValid = true
    @State private var shouldWiggleUsername = false
    
    var body: some View {
        Form {
            ValidatedTextField(
                text: $tempUsername,
                placeholder: "Enter username",
                isValid: $isUsernameValid,
                shouldWiggle: $shouldWiggleUsername
            )
            .listRowBackground(Color("BG"))
        }
        .navigationTitle("Edit Username")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Save") {
            if isUsernameValid && !tempUsername.isEmpty {
                username = tempUsername
                OpenAISettings.shared.username = username
                presentationMode.wrappedValue.dismiss()
            } else {
                shouldWiggleUsername = true
            }
        })
        .background(Color("BG"))
        .scrollContentBackground(.hidden)
        .onAppear {
            tempUsername = username
        }
        .dismissKeyboardOnTap()
    }
}

struct APIKeyEditView: View {
    @Binding var apiKey: String
    @Environment(\.presentationMode) var presentationMode
    @State private var tempAPIKey: String = ""
    @State private var isAPIEmpty: Bool = true
    @State private var isTestingAPI = false
    @State private var showTestResult = false
    @State private var testResultMessage = ""
    @State private var isTestSuccessful = false
    
    var body: some View {
        Form {
            SecureField("OpenAI API Key", text: $tempAPIKey)
                .frame(maxWidth: .infinity)
                .padding()
                .listRowBackground(Color("BG"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isAPIEmpty ? Color("Theme") : Color("warning"))
                )
                .onChange(of: tempAPIKey) { _, newValue in
                    isAPIEmpty = !newValue.isEmpty
                }
            VStack {
                Button(action: {
                    if let pastedString = UIPasteboard.general.string {
                        tempAPIKey = pastedString
                    }
                }) {
                    Text("Paste")
                        .foregroundColor(Color("Highlight"))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color("Theme"))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    tempAPIKey = ""
                }) {
                    Text("Clear")
                        .foregroundColor(Color("warning"))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color("Highlight"))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical)
            .listRowBackground(Color("BG"))
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Edit API Key")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Save") {
            testAPIKey()
        })
        .background(Color("BG"))
        .onAppear {
            tempAPIKey = apiKey
        }
        .alert(isPresented: $showTestResult) {
            Alert(
                title: Text(isTestSuccessful ? "Success" : "Error"),
                message: Text(testResultMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .dismissKeyboardOnTap()
    }
    
    private func testAPIKey() {
        
        DispatchQueue.main.async {
            isTestingAPI = true
            let openAI = OpenAI(apiToken: tempAPIKey)
                
            Task {
                do {
                    let _ = try await openAI.models()
                    isTestSuccessful = true
                    testResultMessage = "This API key is valid and working."
                    apiKey = tempAPIKey
                    OpenAISettings.shared.apiKey = apiKey
                    print(OpenAISettings.shared.apiKey)
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    isTestSuccessful = false
                    testResultMessage = "This API key is invalid, please try another one or try again later."
                    FileLogger.shared.log("Error occurred during API Key testing: \(error.localizedDescription)")
                }
                
                isTestingAPI = false
                showTestResult = true
            }
        }
    }
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQView: View {
    @State private var expandedItems: Set<UUID> = []
    
    let faqItems: [FAQItem] = [
        FAQItem(question: "How do I create a new alarm?", answer: "To create a new alarm, tap the '+' button at the bottom of the main screen"),
        FAQItem(question: "What is a persona in AIarm?", answer: "A persona in AIarm is an personalized character that will speak to you when the alarm is triggered"),
        FAQItem(question: "How do I customize a persona?", answer: "To customize a persona, go to the 'Persona' tab and tap on the persona you want to edit"),
        FAQItem(question: "Do I need my own OpenAI API key?", answer: "Yes, you should create your own API key on platform.openai.com. Go to Settings and enter your API key."),
        FAQItem(question: "How do I change the alarm sound?", answer: "AIarm uses AI-generated speech for alarms. To change the voice, edit the persona."),
        FAQItem(question: "Is my data safe?", answer: "Yes, your data is stored locally on your device. We do not collect or store any personal information."),
        FAQItem(question: "How do I delete an alarm?", answer: "To delete an alarm, tap on the alarm and there will be a delete button at the bottom."),
        FAQItem(question: "Can I use AIarm offline?", answer: "AIarm requires an internet connection to generate AI responses."),
        FAQItem(question: "Why there is error when I save an alarm?", answer: "Most of the time it could be network issue or there are restrictions imposed by the Wifi you connect to. Try using celluar data or retry after a momement.")
    ]
    
    var body: some View {
        ZStack {
            Color("BG").edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(faqItems) { item in
                        FAQItemView(item: item, isExpanded: expandedItems.contains(item.id)) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                toggleExpansion(for: item.id)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("FAQ")
    }
    
    private func toggleExpansion(for id: UUID) {
        if expandedItems.contains(id) {
            expandedItems.remove(id)
        } else {
            expandedItems.insert(id)
        }
    }
}

struct FAQItemView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onTap) {
                HStack {
                    Text(item.question)
                        .font(.headline)
                        .foregroundColor(Color("Highlight"))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color("Theme"))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Rectangle()
                    .fill(Color("Theme"))
                    .frame(height: 1)
                Text(item.answer)
                    .font(.body)
                    .foregroundColor(Color("Highlight").opacity(0.5))
                    .padding(.top, 5)
                    .background(Color("BG"))
            }
        }
        .padding(.vertical, 15)
        .background(Color("BG"))
    }
}

struct TermsAndPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                Group {
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                    Text("By using AIarm, you agree to these terms. If you disagree, please don't use the app.")
                
                    Text("2. Description of Service")
                        .font(.headline)
                    Text("AIarm is an AI-powered alarm app that uses personalized agents to wake you up.")
                
                    Text("3. Privacy and Data Usage")
                        .font(.headline)
                    Text("We collect minimal data necessary for app functionality. Your alarm settings and agent preferences are stored locally on your device. We do not sell your personal information.")
                    Text("API Key Confidentiality: The OpenAI API key you provide is stored securely on your device and is used solely for interactions with the OpenAI service. We do not have access to or store your API key on our servers.")
                
                    Text("4. User Responsibilities")
                        .font(.headline)
                    Text("You are responsible for maintaining the confidentiality of your account and API key, and for all activities under your account.")
                
                    Text("5. Content and Conduct")
                        .font(.headline)
                    Text("You agree not to use AIarm for any unlawful or prohibited purpose.")
                    Text("Content Liability: AIarm uses the GPT-4-mini model to generate content. We do not have control over or responsibility for the content generated by this model. The generated content may sometimes be inappropriate, misleading, or offensive. Use of this content is at your own risk.")
                }
                
                Group {
                    Text("6. Intellectual Property")
                        .font(.headline)
                    Text("All content in AIarm is owned by us and protected by intellectual property laws. Content generated by the AI model is subject to OpenAI's terms and conditions.")
                
                    Text("7. Disclaimer of Warranties")
                        .font(.headline)
                    Text("AIarm is provided 'as is' without warranties of any kind, either express or implied. This includes no warranty regarding the accuracy, reliability, or appropriateness of AI-generated content.")
                
                    Text("8. Limitation of Liability")
                        .font(.headline)
                    Text("We are not liable for any indirect, incidental, special, or consequential damages, including but not limited to any damages resulting from AI-generated content.")
                
                    Text("9. Changes to Terms")
                        .font(.headline)
                    Text("We may modify these terms at any time. Continued use of AIarm constitutes acceptance of the modified terms.")
                
                    Text("10. Contact")
                        .font(.headline)
                    Text("For any questions about these terms, please contact us at support@aiarm.com.")
                }
            }
            .padding()
        }
        .background(Color("BG"))
        .navigationTitle("Terms & Policy")
    }
}

struct LogViewerView: View {
    @State private var logContents: String = ""

    var body: some View {
        ScrollView {
            Text(logContents)
                .padding()
                .textSelection(.enabled)
        }
        .navigationTitle("Logs")
        .navigationBarItems(
            trailing: Button("Clear") {
                clearLogs()
            }
        )
        .onAppear {
           loadLogs()
        }
    }
    
    private func loadLogs() {
        logContents = FileLogger.shared.getLogContents()
    }

    private func clearLogs() {
        FileLogger.shared.clearLogs()
        loadLogs()
    }
}




struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}

