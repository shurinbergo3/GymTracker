//
//  ProgramSyncService.swift
//  GymTracker
//
//  Syncs programs to/from cloud (SRP: Only program sync)
//

import Foundation
import SwiftData

/// Handles program synchronization
/// Single Responsibility: Sync programs only
final class ProgramSyncService {
    private let storage: StorageService
    
    init(storage: StorageService) {
        self.storage = storage
    }
    
    // MARK: - Upload (Push)
    
    func syncPrograms(context: ModelContext) async {
        let programs = fetchAllPrograms(context: context)
        
        for program in programs {
            await syncProgram(program)
        }
    }
    
    private func fetchAllPrograms(context: ModelContext) -> [Program] {
        let descriptor = FetchDescriptor<Program>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    private func syncProgram(_ program: Program) async {
        // NOT IMPLEMENTED + NOT WIRED. The live app syncs programs via
        // SyncManager. Trap in DEBUG so accidentally routing real sync through
        // this stub is caught immediately instead of silently dropping data.
        assertionFailure("ProgramSyncService.syncProgram is a stub — use SyncManager")
    }

    // MARK: - Download (Pull)

    func restorePrograms(container: ModelContainer) async -> Bool {
        assertionFailure("ProgramSyncService.restorePrograms is a stub — use SyncManager")
        return false
    }
}
