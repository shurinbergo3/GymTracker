//
//  WorkoutSessionRepository.swift
//  GymTracker
//
//  Repository for WorkoutSession CRUD (SRP: Only session persistence)
//

import Foundation
import SwiftData

/// Handles WorkoutSession data persistence
/// Single Responsibility: Session CRUD operations only
final class WorkoutSessionRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Create
    
    func createSession(for day: WorkoutDay, startDate: Date) -> WorkoutSession {
        let session = WorkoutSession(
            date: startDate,
            workoutDayName: day.name,
            programName: day.program?.name
        )
        
        context.insert(session)
        return session
    }
    
    // MARK: - Read
    
    func fetchAll() -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func fetchCompleted() -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Update
    
    func completeSession(_ session: WorkoutSession, calories: Int?) {
        session.isCompleted = true
        session.endTime = Date()
        if let calories = calories {
            session.calories = calories
        }
        
        try? context.save()
    }
    
    func markAsSynced(_ session: WorkoutSession) {
        session.isSynced = true
        try? context.save()
    }
    
    // MARK: - Delete
    
    func deleteSession(_ session: WorkoutSession) {
        context.delete(session)
        try? context.save()
    }
    
    func deleteOldSessions(olderThan days: Int) -> Int {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        ) ?? Date()
        
        let oldSessions = fetchOlderThan(date: cutoffDate)
        oldSessions.forEach { context.delete($0) }
        try? context.save()
        
        return oldSessions.count
    }
    
    private func fetchOlderThan(date: Date) -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.date < date }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
