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
        // TODO: Implement when ProgramDTO is created
        #if DEBUG
        print("⚠️ Program sync not yet fully implemented for '\(program.name)'")
        #endif
    }
    
    // MARK: - Download (Pull)
    
    func restorePrograms(container: ModelContainer) async -> Bool {
        // TODO: Implement when storage.fetchPrograms() is ready
        #if DEBUG
        print("⚠️ Program restore not yet implemented")
        #endif
        return false
    }
}
