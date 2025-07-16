import SwiftUI

@main
struct ClockedInApp: App {
    let persistenceController = PersistenceController.shared
    let timerManager = TimerManager.shared
    
    // Create persistent timer subscriber
    @StateObject private var timerSubscriber = TimerSubscriber(viewContext: PersistenceController.shared.container.viewContext)

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.timerManager, timerManager)
                .environment(\.timerSubscriber, timerSubscriber)
        }
    }
}
