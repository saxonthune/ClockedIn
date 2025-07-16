import SwiftUI
import UserNotifications

@main
struct ClockedInApp: App {
    let persistenceController = PersistenceController.shared
    let timerManager = TimerManager.shared
    
    // Create persistent timer subscriber
    @StateObject private var timerSubscriber = TimerSubscriber(viewContext: PersistenceController.shared.container.viewContext)
    @StateObject private var notificationDelegate = NotificationDelegate()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.timerManager, timerManager)
                .environment(\.timerSubscriber, timerSubscriber)
                .environmentObject(notificationDelegate)
                .onAppear {
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                }
        }
    }
}
