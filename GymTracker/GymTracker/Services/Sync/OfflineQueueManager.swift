//
//  OfflineQueueManager.swift
//  GymTracker
//
//  Manages offline sync queue (SRP: Only queue management)
//

import Foundation
import SwiftData
import Combine

/// Manages offline sync queue
/// Single Responsibility: Track unsynced items
@MainActor
final class OfflineQueueManager: ObservableObject {
    @Published var hasUnsyncedData = false
    
    func checkForUnsyncedWorkouts(context: ModelContext) {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true && $0.isSynced != true }
        )
        
        let count = (try? context.fetchCount(descriptor)) ?? 0
        hasUnsyncedData = count > 0
    }
    
    func markAllAsSynced(context: ModelContext) throws {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true && $0.isSynced != true }
        )
        
        let sessions = try context.fetch(descriptor)
        
        for session in sessions {
            session.isSynced = true
        }
        
        try context.save()
        hasUnsyncedData = false
    }
}
