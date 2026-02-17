//
//  ProgramRepository.swift
//  GymTracker
//
//  Manages program persistence (SRP: Only program CRUD)
//

import Foundation
import SwiftData

/// Repository for workout programs
/// Single Responsibility: CRUD operations for programs
final class ProgramRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Read
    
    func fetchActiveProgram() -> Program? {
        let descriptor = FetchDescriptor<Program>(
            predicate: #Predicate { $0.isActive == true }
        )
        return try? context.fetch(descriptor).first
    }
    
    func fetchAllPrograms() -> [Program] {
        let descriptor = FetchDescriptor<Program>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Update
    
    func setActiveProgram(_ program: Program) {
        // Деактивировать все программы
        let all = fetchAllPrograms()
        all.forEach { $0.isActive = false }
        
        // Активировать выбранную
        program.isActive = true
        
        try? context.save()
    }
    
    
    // MARK: - Delete
    
    func deleteProgram(_ program: Program) {
        context.delete(program)
        try? context.save()
    }
}
