//
//  WorkoutSyncService.swift
//  GymTracker
//
//  Syncs workouts to/from cloud (SRP: Only workout sync)
//

import Foundation
import SwiftData

/// Handles workout synchronization
/// Single Responsibility: Sync workouts only
final class WorkoutSyncService {
    private let storage: StorageService
    
    init(storage: StorageService) {
        self.storage = storage
    }
    
    // MARK: - Upload (Push)
    
    func syncUnsyncedWorkouts(context: ModelContext) async -> Int {
        let unsyncedSessions = fetchUnsyncedSessions(context: context)
        
        guard !unsyncedSessions.isEmpty else {
            return 0
        }
        
        var syncedCount = 0
        
        for session in unsyncedSessions {
            if await syncSession(session, context: context) {
                syncedCount += 1
            }
        }
        
        return syncedCount
    }
    
    private func fetchUnsyncedSessions(context: ModelContext) -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true && $0.isSynced != true }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    private func syncSession(_ session: WorkoutSession, context: ModelContext) async -> Bool {
        // NOT IMPLEMENTED + NOT WIRED. The live app syncs workouts via
        // SyncManager / FirestoreManager. Trap in DEBUG so accidentally routing
        // real sync through this stub is caught instead of silently dropping data.
        assertionFailure("WorkoutSyncService.syncSession is a stub — use SyncManager")
        return false
    }

    // MARK: - Download (Pull)

    func restoreWorkouts(container: ModelContainer) async -> Bool {
        assertionFailure("WorkoutSyncService.restoreWorkouts is a stub — use SyncManager")
        return false
    }
}
