import SwiftUI
import CoreData

// MARK: - Dependency Container

class DIContainer: ObservableObject {
    let persistenceController: PersistenceController
    let timerManager: any TimerManagerProtocol
    let timerSubscriber: TimerSubscriber
    
    init(
        persistenceController: PersistenceController = PersistenceController.shared,
        timerManager: (any TimerManagerProtocol)? = nil
    ) {
        self.persistenceController = persistenceController
        self.timerManager = timerManager ?? TimerManager.shared
        self.timerSubscriber = TimerSubscriber(viewContext: persistenceController.container.viewContext)
    }
    
    // MARK: - Factory Methods
    
    static func production() -> DIContainer {
        return DIContainer()
    }
    
    @MainActor static func testing() -> DIContainer {
        return DIContainer(
            persistenceController: PersistenceController.preview,
            timerManager: MockTimerManager()
        )
    }
}

// MARK: - Environment Extension for DI Container

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer.production()
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
