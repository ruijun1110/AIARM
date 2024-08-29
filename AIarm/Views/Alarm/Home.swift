//
//  Home.swift
//  AIarm
//
//  Created by Raymond Wang on 5/16/24.
//

import SwiftUI
import CoreData
import AVFoundation

struct Home: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: AgentEntity.entity(), sortDescriptors: [])
    private var agentEntities: FetchedResults<AgentEntity>
    
    
    @FetchRequest(entity: AlarmEntity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \AlarmEntity.time, ascending: true)])
    private var alarmEntities: FetchedResults<AlarmEntity>
    
    @State var selectedAlarm: Alarm? = nil
    @Binding var showingAddAlarmView: Bool
    @State private var newAlarm = Alarm(time: Date(), isOn: true, goal: "", repeatCount: 1, interval: 5)
        
    // Sort alarms by time only
    var sortedAlarms: [Alarm] {
        alarmEntities.map { Alarm(alarmEntity: $0) }
            .sorted { alarm1, alarm2 in
                let calendar = Calendar.current
                let components1 = calendar.dateComponents([.hour, .minute], from: alarm1.time)
                let components2 = calendar.dateComponents([.hour, .minute], from: alarm2.time)
                
                if let hour1 = components1.hour, let hour2 = components2.hour,
                   let minute1 = components1.minute, let minute2 = components2.minute {
                    if hour1 != hour2 {
                        return hour1 < hour2
                    } else {
                        return minute1 < minute2
                    }
                }
                
                return false
            }
        }
    
    var body: some View {
        VStack {
            ScrollView {
                
                VStack (alignment:.leading) {
                    HStack {
                        Text("Alarm")
                            .font(.system(size: 38))
                            .foregroundStyle(Color("Highlight"))
                            .fontWeight(.semibold)
                    }
                    .padding(.top, 50)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    AlarmListView()
                        .frame(maxWidth: .infinity)
                    Text("Turn Off Silent Mode To Receive Alarm Notification")
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(Color("Placeholder"))
                        .padding(.top)
                }
                Spacer()
            }
        }
        .sheet(item: $selectedAlarm, onDismiss: {selectedAlarm = nil}) { alarm in
                    AlarmEditView(alarm: alarm, isEditing: true, onSave: updateAlarm, onDelete: {deleteAlarm(alarm)})}
        .sheet(isPresented: $showingAddAlarmView, onDismiss: {showingAddAlarmView = false}) {
                    AlarmEditView(alarm: nil, isEditing: false, onSave: addAlarm, onDelete: {})
                }
        .padding(.horizontal)
        .background(Color("BG"))
        .frame(maxWidth: .infinity)
        
    }
    
    private func scheduleAlarm() {
        for alarmEntity in alarmEntities {
            let alarm = Alarm(alarmEntity: alarmEntity)
            if alarm.isOn {
                Task{
                    do{
                        try await AlarmManager.shared.saveAndScheduleAlarm(alarm)
                    } catch {
                        print("Error in scheduling alarm")
                    }
                }
            }
        }
    }
    
    private func alarm(from alarm: Alarm) -> Binding<Alarm> {
            Binding(
                get: { alarm },
                set: { updatedAlarm in
                    updateAlarm(updatedAlarm)
                }
            )
    }
    
    private func addAlarm(_ alarm: Alarm) {
        updateAlarm(alarm)
    }
    
    private func updateAlarm(_ alarm: Alarm) {
        print("Home view is processing alarm \(alarm.id)")
        FileLogger.shared.log("Home view is processing alarm \(alarm.id)")
        Task{
            do{
                try await AlarmManager.shared.saveAndScheduleAlarm(alarm)
            } catch {
                print("Error updating alarm")
            }
        }
    }
    
    private func deleteAlarm(_ alarm: Alarm) {
        AlarmManager.shared.cancelAlarm(for: alarm)
        if let alarmEntity = alarmEntities.first(where: { $0.id == alarm.id }) {
            viewContext.delete(alarmEntity)
            try? viewContext.save()
        }
    }
    
    private func selectAlarm(_ index: Int) {
        if let alarmEntity = alarmEntities.first(where: { $0.id == sortedAlarms[index].id }) {
            selectedAlarm = Alarm(alarmEntity: alarmEntity)
        }
    }
    
    private func AlarmListView() -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(sortedAlarms.indices, id: \.self) { index in
                    AlarmCard(alarm: alarm(from: sortedAlarms[index])) {
                        selectAlarm(index)
                    }
                }
            }
        }
    }
    
    private func AddAlarmButton() -> some View {
        Button(action: {
            newAlarm = Alarm(time: Date(), isOn: true, goal: "", repeatCount: 1, interval: 5)
            showingAddAlarmView = true
        }) {
            Image(systemName: "plus")
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
            }
            .padding(.vertical, 40)
    }
}

#Preview {
    Home(showingAddAlarmView: .constant(false))
}
