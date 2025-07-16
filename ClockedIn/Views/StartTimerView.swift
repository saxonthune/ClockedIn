import SwiftUI
import CoreData

struct StartTimerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timerManager) private var timerManager
    
    @State private var selectedTag: Tag?
    @State private var durationMinutes: Int = 25
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                
                // Tag Selection
                VStack(spacing: 12) {
                    Text("Select Tag")
                        .font(.headline)
                    
                    TagSelector(selectedTag: $selectedTag)
                }
                
                // Duration Input
                VStack(spacing: 16) {
                    Text("Set Duration")
                        .font(.headline)
                    
                    HStack {
                        Button(action: {
                            if durationMinutes > 1 {
                                durationMinutes -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(durationMinutes <= 1)
                        
                        Text("\(durationMinutes)")
                            .font(.title)
                            .fontWeight(.semibold)
                            .frame(minWidth: 60)
                        
                        Text("minutes")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            if durationMinutes < 180 {
                                durationMinutes += 1
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(durationMinutes >= 180)
                    }
                    
                    // Quick duration buttons
                    HStack(spacing: 12) {
                        ForEach([5, 15, 25, 45, 60], id: \.self) { minutes in
                            Button(action: {
                                durationMinutes = minutes
                            }) {
                                Text("\(minutes)m")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        durationMinutes == minutes ? Color.blue : Color.secondary.opacity(0.2)
                                    )
                                    .foregroundColor(
                                        durationMinutes == minutes ? .white : .primary
                                    )
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
                
                // Start Timer Button
                VStack(spacing: 12) {
                    Button(action: {
                        startNewTimer()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Timer")
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(isFormValid ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal)
                    
                    // Helper text when disabled
                    if !isFormValid {
                        Text(getDisabledMessage())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        Text("")
                    }
                }
            }
            .padding()
            .navigationTitle("Setup Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        selectedTag != nil && durationMinutes > 0 && !timerManager.isTimerRunning
    }
    
    private func getDisabledMessage() -> String {
        if timerManager.isTimerRunning {
            return "A timer is already running"
        } else if selectedTag == nil {
            return "Select a tag to start the timer"
        } else {
            return "Please set a duration greater than 0"
        }
    }
    
    private func startNewTimer() {
        guard let selectedTag = selectedTag else { return }
        guard !timerManager.isTimerRunning else { return }
        
        let duration = TimeInterval(durationMinutes * 60)
        timerManager.startTimer(duration: duration, tag: selectedTag, context: viewContext)
        
        dismiss()
    }
}

#Preview {
    StartTimerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
