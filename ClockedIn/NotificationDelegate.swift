import SwiftUI
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var shouldShowReviewView = false
    @Published var reviewSession: TimerSession?
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.list, .banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String, type == "timer_completion" {
            // Get the pending review session from TimerManager
            if let session = TimerManager.shared.pendingReviewSession {
                DispatchQueue.main.async {
                    self.reviewSession = session
                    self.shouldShowReviewView = true
                }
            }
        }
        
        completionHandler()
    }
}
