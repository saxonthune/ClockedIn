import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var timerManager = TimerManager.shared
    @EnvironmentObject private var notificationDelegate: NotificationDelegate
    @State private var showingAddTimeEntry = false
    @State private var showingStartTimer = false
    @State private var showingTimerDisplay = false
    @State private var showingReviewView = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TimeEntry.start, ascending: false)],
        animation: .default)
    private var timeEntries: FetchedResults<TimeEntry>

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section("Active Timer") {
                        if let session = timerManager.currentTimerSession {
                            Button(action: {
                                showingTimerDisplay = true
                            }) {
                                ActiveTimerRowView(session: session, timerManager: timerManager)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: {
                                showingStartTimer = true
                            }) {
                                StartTimerRowView()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Section("Recent") {
                        if timeEntries.isEmpty {
                            Button(action: {
                                showingAddTimeEntry = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Add your first time entry")
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(Array(timeEntries.prefix(3))) { timeEntry in
                                NavigationLink {
                                    TimeEntryDetailView(timeEntry: timeEntry)
                            } label: {
                                TimeEntryRowView(timeEntry: timeEntry)
                            }
                            }
                            
                            Button(action: {
                                showingAddTimeEntry = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                    Text("Add time entry")
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                }
                .toolbar {
#if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
#endif
                    ToolbarItem {
                        Button(action: {
                            showingAddTimeEntry = true
                        }) {
                            Label("Add Time Entry", systemImage: "plus.circle")
                        }
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddTimeEntry) {
                    AddTimeEntryView()
                }
                .sheet(isPresented: $showingStartTimer) {
                    StartTimerView()
                }
                .sheet(isPresented: $showingReviewView) {
                    if let session = timerManager.pendingReviewSession {
                        TimeEntryReviewView(completedSession: session)
                            .onDisappear {
                                timerManager.clearPendingReview()
                                notificationDelegate.shouldShowReviewView = false
                                notificationDelegate.reviewSession = nil
                            }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingTimerDisplay) {
            TimerDisplayView()
        }
        .onReceive(notificationDelegate.$shouldShowReviewView) { shouldShow in
            if shouldShow {
                showingReviewView = true
            }
        }
        .onReceive(timerManager.timerDidCompletePublisher) { completedSession in
            // Show review view when timer completes (not from notification)
            if completedSession != nil && !notificationDelegate.shouldShowReviewView {
                showingReviewView = true
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Active Timer Views

struct StartTimerRowView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Play icon
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Start Timer")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Tap to start a new timer session")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct ActiveTimerRowView: View {
    let session: TimerSession
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Color indicator
                Circle()
                    .fill(Color(hex: session.tag.color ?? "#999999"))
                    .frame(width: 12, height: 12)
                
                Text(session.tag.name ?? "No Tag")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(timerManager.timeString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text(session.tag.note ?? "No Note")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Started: \(timeFormatter.string(from: session.startTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Duration: \(session.formattedDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Ends: \(timeFormatter.string(from: endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            ProgressView(value: timerManager.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: session.tag.color ?? "#999999")))
                .frame(height: 4)
        }
        .padding(.vertical, 2)
    }
    
    private var endTime: Date {
        session.startTime.addingTimeInterval(session.duration)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - TimeEntry Views

struct TimeEntryRowView: View {
    let timeEntry: TimeEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Color indicator
                Circle()
                    .fill(Color(hex: timeEntry.tag?.color ?? "#999999"))
                    .frame(width: 12, height: 12)
                
                Text(timeEntry.tag?.name ?? "No Tag")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(duration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(timeEntry.tag?.note ?? "No Note")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(timeRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if timeEntry.distractedTime > 0 {
                HStack {
                    Text("\(timeEntry.distractedTime)m distracted")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var duration: String {
        let interval = timeEntry.stop!.timeIntervalSince(timeEntry.start!)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60 + 1
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: timeEntry.start!)) - \(formatter.string(from: timeEntry.stop!))"
    }
}

struct TimeEntryDetailView: View {
    let timeEntry: TimeEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color(hex: timeEntry.tag?.color ?? "#999999"))
                        .frame(width: 20, height: 20)
                    
                    Text(timeEntry.tag?.name ?? "No Tag")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Text(timeEntry.tag?.note ?? "No Note")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Time Details")
                    .font(.headline)
                
                HStack {
                    Text("Start:")
                    Spacer()
                    Text(timeEntry.start!, formatter: itemFormatter)
                }
                
                HStack {
                    Text("Stop:")
                    Spacer()
                    Text(timeEntry.stop!, formatter: itemFormatter)
                }
                
                HStack {
                    Text("Duration:")
                    Spacer()
                    Text(duration)
                }
                
                if timeEntry.distractedTime > 0 {
                    HStack {
                        Text("Friction:")
                        Spacer()
                        Text("\(timeEntry.distractedTime)")
                            .foregroundColor(.orange)
                        Spacer()
                        Text("minutes")
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Time Entry")
        //.navigationBarTitleDisplayMode(.inline)
    }
    
    private var duration: String {
        let interval = timeEntry.stop!.timeIntervalSince(timeEntry.start!)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours) hours \(minutes) minutes"
        } else {
            return "\(minutes) minutes"
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    HomeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
