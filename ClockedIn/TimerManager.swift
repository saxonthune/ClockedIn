import SwiftUI
import CoreData
import Combine

// MARK: - Timer Manager Protocol

protocol TimerManagerProtocol: ObservableObject {
    var isTimerRunning: Bool { get }
    var timeRemaining: TimeInterval { get }
    var currentTimerSession: TimerSession? { get }
    var timerDidComplete: TimerSession? { get }
    
    var timeString: String { get }
    var progress: Double { get }
    
    // Publisher for timer completion
    var timerDidCompletePublisher: Published<TimerSession?>.Publisher { get }
    
    func startTimer(duration: TimeInterval, tag: Tag, context: NSManagedObjectContext)
    func abortTimer()
}

// MARK: - Timer Manager Implementation

class TimerManager: TimerManagerProtocol {
    static let shared = TimerManager()
    
    // Published properties for UI updates
    @Published var isTimerRunning: Bool = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var currentTimerSession: TimerSession?
    @Published var timerDidComplete: TimerSession? = nil // For triggering TimeEntry creation
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    var timerDidCompletePublisher: Published<TimerSession?>.Publisher {
        $timerDidComplete
    }
    
    func startTimer(duration: TimeInterval, tag: Tag, context: NSManagedObjectContext) {
        guard !isTimerRunning else { return }
        
        let session = TimerSession(
            id: UUID(),
            duration: duration,
            tag: tag,
            startTime: Date(),
            context: context
        )
        
        currentTimerSession = session
        timeRemaining = duration
        isTimerRunning = true
        
        // Start the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        // Request background task permission
        requestBackgroundTaskPermission()
    }
    
    func abortTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        
        // Save partial time entry if some time was tracked
        if let session = currentTimerSession {
            let actualDuration = Date().timeIntervalSince(session.startTime)
            if actualDuration > 30 { // Only save if more than 30 seconds
                createTimeEntryFromAbortedTimer(session: session, stopTime: Date())
            }
        }
        
        currentTimerSession = nil
        timeRemaining = 0
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // Timer completed
            completeTimer()
        }
    }
    
    private func completeTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        
        // Trigger TimeEntry creation through published property
        if let session = currentTimerSession {
            timerDidComplete = session
        }
        
        currentTimerSession = nil
        timeRemaining = 0
        
        // Send completion notification
        sendCompletionNotification()
    }
    
    // Method for creating TimeEntry from aborted timer (synchronous)
    private func createTimeEntryFromAbortedTimer(session: TimerSession, stopTime: Date) {
        let newTimeEntry = TimeEntry(context: session.context)
        newTimeEntry.id = UUID()
        newTimeEntry.start = session.startTime
        newTimeEntry.stop = stopTime
        newTimeEntry.distractedTime = 0
        newTimeEntry.tag = session.tag
        
        do {
            try session.context.save()
            print("✅ TimeEntry created for aborted timer: \(session.tag.name ?? "Unknown")")
        } catch {
            print("❌ Error creating TimeEntry for aborted timer: \(error)")
        }
    }
    
    private func requestBackgroundTaskPermission() {
        // Request permission to run in background
        // This would be implemented based on your app's background requirements
    }
    
    private func sendCompletionNotification() {
        // Send local notification when timer completes
        // This would integrate with your notification system
    }
}

// Timer session model
struct TimerSession {
    let id: UUID
    let duration: TimeInterval
    let tag: Tag
    let startTime: Date
    let context: NSManagedObjectContext
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Helper extensions for formatting
extension TimerManager {
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard let session = currentTimerSession else { return 0 }
        return 1.0 - (timeRemaining / session.duration)
    }
}
