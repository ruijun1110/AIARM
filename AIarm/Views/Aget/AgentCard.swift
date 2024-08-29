import SwiftUI

/// A view component that displays an agent's information in a card format.
struct AgentCard: View {
    @Binding var agent: Agent
    
    // MARK: - Mood Enum
    private enum Mood: String, CaseIterable {
        case Joyful
        case Angry
        case Panic
        case Chill
        case Loving
        static func from(string: String) -> Mood? {
            return Self.allCases.first { $0.rawValue == string }
        }
    }
    var body: some View {
        HStack {
            
            moodSymbol(mood: agent.mood)
                .frame(width: 40)
                        
            AgentNameView(name: agent.name)
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)


            AgentCharacterLabelView(character: agent.character)
                .layoutPriority(1)
        }
        .foregroundStyle(Color("Highlight"))
        .background(Color("Theme"))
        .cornerRadius(10)
    }
    
    // MARK: - Private Views
    private func moodSymbol(mood:String) -> some View {
        var baseImage: Image
        switch Mood.from(string: mood) {
        case .Joyful:
            baseImage = Image(systemName: "face.smiling")
        case .Angry:
            baseImage = Image(systemName: "flame")
        case.Panic:
            baseImage = Image(systemName: "exclamationmark.triangle.fill")
        case.Chill:
            baseImage = Image(systemName: "snowflake")
        case.Loving:
            baseImage = Image(systemName: "heart.fill")
        default:
            baseImage = Image(systemName: "face.smiling")
        }
        
        let styledImage = baseImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 25, height: 25)
            .padding(.leading)
        
        return styledImage
    }
    
    private func AgentNameView(name: String) -> some View {
        Text(name)
            .font(.title2)
            .fontWeight(.semibold)
            .padding()
            .lineLimit(1)
    }
    
    private func AgentCharacterLabelView(character: String) -> some View {
        Text(character)
            .font(.footnote)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color("SecondTheme"))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .padding(.trailing)
    }
}

struct AgentCardView_Previews: PreviewProvider {
    static var previews: some View {
        let previewAgent = Agent(name: "Tina", character: "Annoying Mom", mood: "Angry", motivations: [], voice: "Alloy")
        AgentCard(agent: .constant(previewAgent))
            .padding()
    }
}
