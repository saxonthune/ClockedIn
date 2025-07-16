import SwiftUI
import CoreData

struct TimeEntryReviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let completedSession: TimerSession
    
    @State private var friction: Int32 = 0
    @State private var hasDistractions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Session Summary
                VStack(spacing: 16) {
                    Text("Timer Completed!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color(hex: completedSession.tag.color ?? "#007AFF"))
                                .frame(width: 20, height: 20)
                            Text(completedSession.tag.name ?? "Unknown")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        if let note = completedSession.tag.note, !note.isEmpty {
                            Text(note)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Time Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session Details")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Started:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(timeFormatter.string(from: completedSession.startTime))
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Ended:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(timeFormatter.string(from: Date()))
                                .fontWeight(.medium)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total Duration:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(actualDurationText)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Distraction Time Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Distraction Time")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        Toggle("Include distraction time", isOn: $hasDistractions)
                            .padding(.horizontal)
                        
                        if hasDistractions {
                            VStack(spacing: 8) {
                                
                                Picker("Time Distracted", selection: $friction) {
                                    ForEach(0...max(0, actualDurationMinutes), id: \.self) { minutes in
                                        Text("\(minutes) \(minutes == 1 ? "minute" : "minutes")").tag(Int32(minutes))
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 120)
                                
                                Text("Time spent on distractions like checking phone, social media, etc.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Review Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Discard") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTimeEntry()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var actualDurationMinutes: Int {
        Int(ceil(Date().timeIntervalSince(completedSession.startTime) / 60))
    }
    
    private var actualDurationText: String {
        let totalMinutes = actualDurationMinutes
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours) hours \(minutes) minutes"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    // MARK: - Actions
    
    private func saveTimeEntry() {
        withAnimation {
            let newTimeEntry = TimeEntry(context: viewContext)
            newTimeEntry.id = UUID()
            newTimeEntry.start = completedSession.startTime
            newTimeEntry.stop = Date()
            newTimeEntry.distractedTime = hasDistractions ? friction : 0
            newTimeEntry.tag = completedSession.tag
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                print("Error saving time entry: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    let mockTag = Tag(context: PersistenceController.preview.container.viewContext)
    mockTag.name = "Work"
    mockTag.color = "#007AFF"
    mockTag.note = "Focus session"
    
    let mockSession = TimerSession(
        id: UUID(),
        duration: 25 * 60, // 25 minutes
        tag: mockTag,
        startTime: Calendar.current.date(byAdding: .minute, value: -20, to: Date()) ?? Date(),
        context: PersistenceController.preview.container.viewContext
    )
    
    return TimeEntryReviewView(completedSession: mockSession)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
