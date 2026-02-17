//
//  NetworkMonitor.swift
//  GymTracker
//
//  Monitors network connectivity (SRP: Only network monitoring)
//

import Foundation
import Combine
import Network

/// Monitors network connectivity status
/// Single Responsibility: Track network availability
@MainActor
final class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    nonisolated private func stopMonitoring() {
        monitor.cancel()
    }
}
