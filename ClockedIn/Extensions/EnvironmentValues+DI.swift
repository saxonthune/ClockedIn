import SwiftUI

// MARK: - Environment Keys

private struct TimerManagerKey: EnvironmentKey {
    static let defaultValue: any TimerManagerProtocol = TimerManager.shared
}

private struct TimerSubscriberKey: EnvironmentKey {
    static let defaultValue: TimerSubscriber? = nil
}

// MARK: - Environment Extensions

extension EnvironmentValues {
    var timerManager: any TimerManagerProtocol {
        get { self[TimerManagerKey.self] }
        set { self[TimerManagerKey.self] = newValue }
    }
    
    var timerSubscriber: TimerSubscriber? {
        get { self[TimerSubscriberKey.self] }
        set { self[TimerSubscriberKey.self] = newValue }
    }
}
