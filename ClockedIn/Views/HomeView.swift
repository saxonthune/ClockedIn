import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.timerManager) private var timerManager
    @State private var showingAddTimeEntry = false
    @State private var showingStartTimer = false
    @State private var showingTimerDisplay = false

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
                // Active Timer Banner
                if timerManager.currentTimerSession != nil {
                    Button(action: {
                        showingTimerDisplay = true
                    }) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Timer Running")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                if let session = timerManager.currentTimerSession {
                                    Text("\(session.tag.name ?? "Unknown") • \(timerManager.timeString)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Spacer()
                            
                            Text("View")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                List {
                    // Recent TimeEntries Section
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
                    
                    // Original Items Section
                    Section("Items") {
                        ForEach(items) { item in
                            NavigationLink {
                                Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                            } label: {
                                Text(item.timestamp!, formatter: itemFormatter)
                            }
                        }
                        .onDelete(perform: deleteItems)
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
                            showingStartTimer = true
                        }) {
                            Label("Start Timer", systemImage: "timer")
                        }
                    }
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
                Text("Select an item")
            }
        }
        .fullScreenCover(isPresented: $showingTimerDisplay) {
            TimerDisplayView()
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
                    Text("Friction: \(timeEntry.distractedTime)")
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
