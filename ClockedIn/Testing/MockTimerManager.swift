import SwiftUI
import CoreData
import Combine

// MARK: - Mock Timer Manager for Testing

class MockTimerManager: TimerManagerProtocol {
    @Published var pendingReviewSession: TimerSession?
    
    func clearPendingReview() {
        pendingReviewSession = nil
        timerDidComplete = nil
    }
    
    @Published var isTimerRunning: Bool = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var currentTimerSession: TimerSession? = nil
    @Published var timerDidComplete: TimerSession? = nil
    
    var timerDidCompletePublisher: Published<TimerSession?>.Publisher {
        $timerDidComplete
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard let session = currentTimerSession else { return 0 }
        return 1.0 - (timeRemaining / session.duration)
    }
    
    func startTimer(duration: TimeInterval, tag: Tag, context: NSManagedObjectContext) {
        // Mock implementation
        isTimerRunning = true
        timeRemaining = duration
        currentTimerSession = TimerSession(
            id: UUID(),
            duration: duration,
            tag: tag,
            startTime: Date(),
            context: context
        )
    }
    
    func abortTimer() {
        isTimerRunning = false
        currentTimerSession = nil
        timeRemaining = 0
    }
}
