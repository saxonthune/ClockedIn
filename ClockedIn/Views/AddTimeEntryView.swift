import SwiftUI
import CoreData

struct AddTimeEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTag: Tag?
    @State private var startTime = Date()
    @State private var stopTime = Date()
    @State private var friction: Int32 = 1
    @State private var hasDistractions = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time Period") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Stop Time", selection: $stopTime, displayedComponents: [.date, .hourAndMinute])
                    Text("Duration: \(durationText)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("Tag") {
                    TagSelector(selectedTag: $selectedTag)
                }
                
                Section("Distractions") {
                    Toggle("Include Distraction Time", isOn: $hasDistractions)
                    
                    if hasDistractions {
                        Picker("Time Distracted", selection: $friction) {
                            ForEach(0...max(0, intervalMinutes), id: \.self) { minutes in
                                Text("\(minutes) \(minutes == 1 ? "minute" : "minutes")").tag(Int32(minutes))
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        
                        Text("The number of minutes spent distracted.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            .navigationTitle("Add Time Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTimeEntry()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            // Set default stop time to current time
            stopTime = Date()
            // Set default start time to 1 hour ago
            startTime = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        }
    }
    
    private var isFormValid: Bool {
        selectedTag != nil && stopTime > startTime
    }
    
    private var intervalMinutes: Int {
        Int(ceil(stopTime.timeIntervalSince(startTime) / 60))
    }
    
    private var durationText: String {
        let totalMinutes = intervalMinutes
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours) hours \(minutes) minutes"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    private func saveTimeEntry() {
        guard let selectedTag = selectedTag else { return }
        
        withAnimation {
            let newTimeEntry = TimeEntry(context: viewContext)
            newTimeEntry.id = UUID()
            newTimeEntry.start = startTime
            newTimeEntry.stop = stopTime
            newTimeEntry.distractedTime = hasDistractions ? friction : 0
            newTimeEntry.tag = selectedTag
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    AddTimeEntryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
