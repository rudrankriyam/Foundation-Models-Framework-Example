import Foundation
import Network

enum AppBenchConnectivityObservation: String, Sendable {
    case connected
    case disconnected
    case connectionRequired
    case unknown

    var verifiesOfflineExperiment: Bool {
        self == .disconnected
    }

    var displayName: String {
        switch self {
        case .connected:
            "an active network path"
        case .disconnected:
            "no active network path"
        case .connectionRequired:
            "a network path that can connect on demand"
        case .unknown:
            "an unknown network state"
        }
    }

    init(status: NWPath.Status) {
        switch status {
        case .satisfied:
            self = .connected
        case .unsatisfied:
            self = .disconnected
        case .requiresConnection:
            self = .connectionRequired
        @unknown default:
            self = .unknown
        }
    }
}

enum AppBenchConnectivityObserver {
    static func observe() async -> AppBenchConnectivityObservation {
        let monitor = NWPathMonitor()
        let state = AppBenchConnectivityObservationState()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                state.install(continuation)
                monitor.pathUpdateHandler = { path in
                    state.complete(with: AppBenchConnectivityObservation(status: path.status))
                    monitor.cancel()
                }
                monitor.start(queue: DispatchQueue(label: "AppBenchConnectivityObserver"))
            }
        } onCancel: {
            state.complete(with: .unknown)
            monitor.cancel()
        }
    }
}

enum AppBenchOfflineResultPolicy {
    static func isSuccess(connectivityVerified: Bool, model: AppBenchModel) -> Bool {
        connectivityVerified && model == .onDevice
    }
}

private final class AppBenchConnectivityObservationState: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<AppBenchConnectivityObservation, Never>?
    private var completedObservation: AppBenchConnectivityObservation?

    func install(
        _ continuation: CheckedContinuation<AppBenchConnectivityObservation, Never>
    ) {
        lock.lock()
        if let completedObservation {
            lock.unlock()
            continuation.resume(returning: completedObservation)
        } else {
            self.continuation = continuation
            lock.unlock()
        }
    }

    func complete(with observation: AppBenchConnectivityObservation) {
        lock.lock()
        guard completedObservation == nil else {
            lock.unlock()
            return
        }
        completedObservation = observation
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: observation)
    }
}
