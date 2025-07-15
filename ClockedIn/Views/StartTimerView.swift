import SwiftUI
import CoreData

struct StartTimerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<Tag>
    
    @State private var selectedTag: Tag?
    @State private var durationMinutes: Int = 25
    @State private var showingNewTagSheet = false
    
    // Timer states
    @State private var isTimerRunning = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var startTime: Date?
    
    // For creating new tag
    @State private var newTagName = ""
    @State private var newTagNote = ""
    @State private var newTagColor = "#007AFF"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Timer Display
                VStack(spacing: 16) {
                    Text("Timer")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(timeString)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(isTimerRunning ? .primary : .secondary)
                    
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 8)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                isTimerRunning ? Color.blue : Color.secondary.opacity(0.5),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: progress)
                    }
                }
                
                // Duration Input (only shown when timer is not running)
                if !isTimerRunning {
                    VStack(spacing: 16) {
                        Text("Duration")
                            .font(.headline)
                        
                        HStack {
                            Button(action: {
                                if durationMinutes > 1 {
                                    durationMinutes -= 1
                                    updateTimeRemaining()
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
                                    updateTimeRemaining()
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
                                    updateTimeRemaining()
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
                }
                
                // Tag Selection
                VStack(spacing: 12) {
                    Text("Tag")
                        .font(.headline)
                    
                    HStack {
                        Menu {
                            Button("Select a tag") {
                                selectedTag = nil
                            }
                            ForEach(tags, id: \.self) { tag in
                                Button(action: {
                                    selectedTag = tag
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: tag.color ?? "#999999"))
                                            .frame(width: 12, height: 12)
                                        Text(tag.name ?? "")
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if let selectedTag = selectedTag {
                                    Circle()
                                        .fill(Color(hex: selectedTag.color ?? "#999999"))
                                        .frame(width: 16, height: 16)
                                    Text(selectedTag.name ?? "")
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select a tag")
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        Button("New Tag") {
                            showingNewTagSheet = true
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                Spacer()
                
                // Start/Stop Button
                Button(action: {
                    if isTimerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    HStack {
                        Image(systemName: isTimerRunning ? "stop.fill" : "play.fill")
                        Text(isTimerRunning ? "Stop Timer" : "Start Timer")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTimerRunning ? Color.red : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid && !isTimerRunning)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Start Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if isTimerRunning {
                            stopTimer()
                        }
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewTagSheet) {
            NewTagView(
                newTagName: $newTagName,
                newTagNote: $newTagNote,
                newTagColor: $newTagColor,
                onSave: createNewTag
            )
        }
        .onAppear {
            updateTimeRemaining()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var isFormValid: Bool {
        selectedTag != nil && durationMinutes > 0
    }
    
    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progress: Double {
        let totalTime = Double(durationMinutes * 60)
        guard totalTime > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalTime)
    }
    
    private func updateTimeRemaining() {
        timeRemaining = TimeInterval(durationMinutes * 60)
    }
    
    private func startTimer() {
        guard selectedTag != nil else { return }
        
        isTimerRunning = true
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Timer finished
                completeTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        
        // Save the partial time entry if some time was tracked
        if let startTime = startTime, let selectedTag = selectedTag {
            let actualDuration = Date().timeIntervalSince(startTime)
            if actualDuration > 30 { // Only save if more than 30 seconds
                saveTimeEntry(start: startTime, stop: Date(), tag: selectedTag)
            }
        }
        
        startTime = nil
        updateTimeRemaining()
    }
    
    private func completeTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        
        // Save the completed time entry
        if let startTime = startTime, let selectedTag = selectedTag {
            let stopTime = Date()
            saveTimeEntry(start: startTime, stop: stopTime, tag: selectedTag)
        }
        
        startTime = nil
        updateTimeRemaining()
        
        // Show completion feedback
        // You could add haptic feedback or notification here
        
        dismiss()
    }
    
    private func saveTimeEntry(start: Date, stop: Date, tag: Tag) {
        withAnimation {
            let newTimeEntry = TimeEntry(context: viewContext)
            newTimeEntry.id = UUID()
            newTimeEntry.start = start
            newTimeEntry.stop = stop
            newTimeEntry.distractedTime = 0 // No distraction tracking for timer mode
            newTimeEntry.tag = tag
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error saving time entry: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func createNewTag() {
        withAnimation {
            let newTag = Tag(context: viewContext)
            newTag.id = UUID()
            newTag.name = newTagName
            newTag.note = newTagNote
            newTag.color = newTagColor
            
            do {
                try viewContext.save()
                selectedTag = newTag
                newTagName = ""
                newTagNote = ""
                newTagColor = "#007AFF"
                showingNewTagSheet = false
            } catch {
                let nsError = error as NSError
                print("Error creating new tag: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    StartTimerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
