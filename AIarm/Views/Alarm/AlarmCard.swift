import SwiftUI

/// A view that represents a single alarm in a card format.
struct AlarmCard: View {
    /// The alarm to be displayed.
    @Binding var alarm: Alarm
    
    /// Action to be performed when the card is tapped.
    var onCardTap: () -> Void

    
    var body: some View {
        HStack {
            HStack {
                AlarmBellButton()
                    .frame(width: 40)
                
                
                AlarmTimeView(alarm: alarm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let agent = alarm.agent {
                    AgentLabel(agentName: agent.name)
                        .layoutPriority(1)
                }
                else {
                    AgentLabel(agentName: "Default")
                        .layoutPriority(1)
                }
            }
            .onTapGesture {
                onCardTap()
            }
            
            Spacer()
            
        }
        .padding(10)
        .background(Color("Theme"))
        .cornerRadius(10)
    }
    
    /// Creates a button with a bell icon that toggles the alarm on/off.
    private func AlarmBellButton() -> some View {
        return Button(action: {
            alarm.isOn.toggle()
            }) {
                Image(systemName: alarm.isOn ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(alarm.isOn ? .white : .red)
            }
            .padding(.leading, 8)
    }
    
    /// Displays the time component of the alarm.
    private func AlarmTimeView(alarm: Alarm) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
            
        let timeString = dateFormatter.string(from: alarm.time)
        
        let hour = Calendar.current.component(.hour, from: alarm.time)
        
        let isPM = hour >= 12
        
        return HStack(alignment: .bottom, spacing: 2) {
            HStack(spacing: 0) {
                        ForEach(0..<5) { index in
                            if index == 2 {
                                Text(":")
                                    .font(.custom("DS-Digital-Bold", size: 60))
                                    .foregroundColor(.white)
                            } else {
                                DigitView(digit: String(timeString[timeString.index(timeString.startIndex, offsetBy: index )]))
                            }
                        }
                    }
            
            VStack(spacing: 4) {
                Text("AM")
                    .font(.custom("DS-Digital-Bold", size: 20))
                    .foregroundColor(isPM ? Color.black.opacity(0.2) : .white)
                
                Text("PM")
                    .font(.custom("DS-Digital-Bold", size: 20))
                    .foregroundColor(isPM ? .white : Color.black.opacity(0.1))
            }
            .padding(.bottom, 8)
        }
    }
    
    /// Displays the agent's name in a styled label.
    private func AgentLabel(agentName: String) -> some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(.white)
                .font(.subheadline)
            Text(agentName)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color("SecondTheme"))
        .cornerRadius(10)
    }
    
    /// A custom view for displaying individual digits in the alarm time.
    private struct DigitView: View {
        let digit: String
        
        var body: some View {
            ZStack(alignment: .trailing) {
                Text("8")
                    .font(.custom("DS-Digital-Bold", size: 60))
                    .foregroundColor(.black.opacity(0.05))
                Text(digit)
                    .font(.custom("DS-Digital-Bold", size: 60))
                    .foregroundColor(.white)
            }
        }
    }
    
    
}

struct AlarmCardPreview: PreviewProvider {
    static var previews: some View {
        let agent = Agent(name: "John", character: "Wake up agent", mood: "Happy", motivations: ["Get up early", "Exercise"], voice: "Alloy")
        let alarm = Alarm(time: Date(), isOn: true, goal: "Morning Alarm", repeatCount: 1, interval: 5, agent: agent)
        
        AlarmCard(alarm: .constant(alarm), onCardTap: {})
            .previewLayout(.sizeThatFits)
    }
}
