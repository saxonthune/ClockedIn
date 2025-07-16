import SwiftUI
import CoreData
import Combine
import UserNotifications

// MARK: - Timer Manager Protocol

protocol TimerManagerProtocol: ObservableObject {
    var isTimerRunning: Bool { get }
    var timeRemaining: TimeInterval { get }
    var currentTimerSession: TimerSession? { get }
    var timerDidComplete: TimerSession? { get }
    var pendingReviewSession: TimerSession? { get }
    
    var timeString: String { get }
    var progress: Double { get }
    
    // Publisher for timer completion
    var timerDidCompletePublisher: Published<TimerSession?>.Publisher { get }
    
    func startTimer(duration: TimeInterval, tag: Tag, context: NSManagedObjectContext)
    func abortTimer()
    func clearPendingReview()
}

// MARK: - Timer Manager Implementation

class TimerManager: TimerManagerProtocol {
    static let shared = TimerManager()
    
    // Published properties for UI updates
    @Published var isTimerRunning: Bool = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var currentTimerSession: TimerSession?
    @Published var timerDidComplete: TimerSession? = nil // For triggering TimeEntry creation
    @Published var pendingReviewSession: TimerSession? = nil // For session awaiting review
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotifications()
    }
    
    var timerDidCompletePublisher: Published<TimerSession?>.Publisher {
        $timerDidComplete
    }
    
    func startTimer(duration: TimeInterval, tag: Tag, context: NSManagedObjectContext) {
        guard !isTimerRunning && pendingReviewSession == nil else { return }
        
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
        
        // Store session for review and trigger completion
        if let session = currentTimerSession {
            pendingReviewSession = session
            timerDidComplete = session
        }
        
        currentTimerSession = nil
        timeRemaining = 0
        
        // Send completion notification
        sendCompletionNotification()
    }
    
    func clearPendingReview() {
        pendingReviewSession = nil
        timerDidComplete = nil
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
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendCompletionNotification() {
        guard let session = pendingReviewSession else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Timer Completed!"
        content.body = "\(session.tag.name ?? "Timer") session finished. Tap to review and save."
        content.sound = .default
        content.badge = 1
        
        // Add custom data to identify this is a timer completion
        content.userInfo = [
            "type": "timer_completion",
            "sessionId": session.id.uuidString,
            "tagName": session.tag.name ?? "Unknown"
        ]
        
        // Trigger notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "timer_completion_\(session.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Timer completion notification scheduled")
            }
        }
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
