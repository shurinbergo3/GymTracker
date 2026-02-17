//
//  AppDependencies.swift
//  GymTracker
//
//  Dependency Injection Container (replaces Singleton pattern)
//

import Foundation
import SwiftData

/// Dependency Injection Container
/// Replaces static shared instances with proper DI
@MainActor
final class AppDependencies {
    // MARK: - Core Services (Protocols)
    
    let authService: AuthenticationService
    let storageService: StorageService
    let healthService: HealthService
    
    // MARK: - Auth Services
    
    let sessionManager: UserSessionManager
    let accountDeletionService: AccountDeletionService
    
    // MARK: - Sync Services
    
    let networkMonitor: NetworkMonitor
    let workoutSyncService: WorkoutSyncService
    let profileSyncService: ProfileSyncService
    let programSyncService: ProgramSyncService
    let offlineQueueManager: OfflineQueueManager
    
    // MARK: - Workout Services
    
    let workoutStateMachine: WorkoutStateMachine
    let workoutTimerService: WorkoutTimerService
    
    // MARK: - Initialization
    
    init() {
        // Create service implementations
        self.authService = FirebaseAuthService()
        self.storageService = FirestoreStorageService()
        self.healthService = HealthKitService()
        
        // Create auth managers
        self.sessionManager = UserSessionManager(storage: .standard)
        self.accountDeletionService = AccountDeletionService(storage: storageService)
        
        // Create sync services
        self.networkMonitor = NetworkMonitor()
        self.workoutSyncService = WorkoutSyncService(storage: storageService)
        self.profileSyncService = ProfileSyncService(storage: storageService)
        self.programSyncService = ProgramSyncService(storage: storageService)
        self.offlineQueueManager = OfflineQueueManager()
        
        // Create workout services
        self.workoutStateMachine = WorkoutStateMachine()
        self.workoutTimerService = WorkoutTimerService()
    }
    
    // MARK: - Factory Methods
    
    /// Factory method to create WorkoutSessionRepository with context
    nonisolated func createWorkoutSessionRepository(context: ModelContext) -> WorkoutSessionRepository {
        WorkoutSessionRepository(context: context)
    }
    
    /// Factory method to create ProgramRepository with context
    nonisolated func createProgramRepository(context: ModelContext) -> ProgramRepository {
        ProgramRepository(context: context)
    }
}
