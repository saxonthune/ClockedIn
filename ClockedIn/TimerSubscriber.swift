import SwiftUI
import CoreData
import Combine

class TimerSubscriber: ObservableObject {
    private let timerManager = TimerManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        setupTimerSubscription()
    }
    
    private func setupTimerSubscription() {
        // Subscribe to timer completion events
        timerManager.$timerDidComplete
            .compactMap { $0 } // Only emit non-nil values
            .sink { [weak self] completedSession in
                self?.handleTimerCompletion(session: completedSession)
            }
            .store(in: &cancellables)
    }
    
    private func handleTimerCompletion(session: TimerSession) {
        // Create TimeEntry for completed timer
        let newTimeEntry = TimeEntry(context: viewContext)
        newTimeEntry.id = UUID()
        newTimeEntry.start = session.startTime
        newTimeEntry.stop = Date()
        newTimeEntry.distractedTime = 0
        newTimeEntry.tag = session.tag
        
        do {
            try viewContext.save()
            print("✅ TimeEntry created for completed timer: \(session.tag.name ?? "Unknown")")
            
            // Reset the completion trigger in TimerManager
            timerManager.timerDidComplete = nil
        } catch {
            print("❌ Error creating TimeEntry for completed timer: \(error)")
        }
    }
}
