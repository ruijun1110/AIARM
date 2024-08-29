//
//  TabBarView.swift
//  AIarm
//
//  Created by Raymond Wang on 5/29/24.
//

import SwiftUI

struct TabBarView: View {
    @State var index = 0
    @State private var selectedTab = 0
    @Binding var showingAddAlarmView: Bool
    @Binding var showingAddAgentView: Bool
        
        var body: some View {
            VStack {
                Spacer()
                
                CustomTabs(index: self.$index, showingAddAlarmView: $showingAddAlarmView, showingAddAgentView: $showingAddAgentView)
            }
            .background(Color("BG")).ignoresSafeArea(.all)
        }
    
}

struct CustomTabs : View {
    let tabImageSize: CGFloat = 23
    let tabItemTextSize: CGFloat = 10
    let unselectedTabColorOpacity = 0.7
    @Binding var index : Int
    @Binding var showingAddAlarmView: Bool
    @Binding var showingAddAgentView: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background shape
                CShape()
                    .fill(Color("DarkBG"))
                    .frame(height: 90)

                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                
                    Button(action: { self.index = 0 }) {
                        TabButtonView(imageName: "alarm.fill", text: "Alarm", isSelected: self.index == 0)
                    }
                                    
                    Spacer(minLength: geometry.size.width * 0.1)
                                
                    Button(action: { self.index = 1 }) {
                        TabButtonView(imageName: "person.2.fill", text: "Persona", isSelected: self.index == 1)
                    }
                                        
                    Spacer(minLength: geometry.size.width * 0.2)
                                    
                    Button(action: { self.index = 2 }) {
                        TabButtonView(imageName: "mic.fill", text: "Rehearsal", isSelected: self.index == 2)
                    }
                                            
                    Spacer(minLength: geometry.size.width * 0.1)
                                        
                    Button(action: { self.index = 3 }) {
                        TabButtonView(imageName: "gear", text: "Setting", isSelected: self.index == 3)
                    }
                                        
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 35)
                    
            // Add button
                Button(action: {
                    if index == 0 {
                        showingAddAlarmView = true
                    } else if index == 1 {
                        showingAddAgentView = true
                    } else {
                        self.index = 0
                        showingAddAlarmView = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 25))
                        .foregroundStyle(Color("Highlight"))
                        .frame(width: 60, height: 60)
                        .background(Color("Theme"))
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .offset(y: -60)
            }
        }
        .frame(height: 90)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct CShape : Shape {
    func path(in rect: CGRect) -> Path {
        return Path{ path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            
            path.addArc(center: CGPoint(x: (rect.width / 2), y: 0), radius: 35, startAngle: .zero, endAngle: .init(degrees: 180), clockwise: true)
        }
    }
}

struct TabButtonView: View {
    let imageName: String
    let text: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: imageName)
                .font(.system(size: 23))
            Text(text)
                .font(.system(size: 10))
        }
        .foregroundStyle(isSelected ? Color("Theme") : Color("Highlight").opacity(0.7))
        .animation(.none, value: isSelected)
    }
}

#Preview {
    TabBarView(showingAddAlarmView: .constant(false), showingAddAgentView: .constant(false))
}
