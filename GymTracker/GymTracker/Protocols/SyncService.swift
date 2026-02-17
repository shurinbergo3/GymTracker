//
//  SyncService.swift
//  GymTracker
//
//  Protocol for data synchronization (DIP)
//

import Foundation
import SwiftData

/// Abstraction for data synchronization operations
protocol SyncService {
    /// Sync unsynced workouts to cloud
    func syncWorkouts(context: ModelContext) async
    
    /// Sync user profile to cloud
    func syncProfile(profile: UserProfile, activeProgram: Program?, context: ModelContext) async
    
    /// Sync programs to cloud
    func syncPrograms(context: ModelContext) async
    
    /// Restore workouts from cloud
    func restoreWorkouts(container: ModelContainer) async -> Bool
    
    /// Restore user profile from cloud
    func restoreProfile(container: ModelContainer) async
    
    /// Restore programs from cloud
    func restorePrograms(container: ModelContainer) async -> Bool
    
    /// Check if there are unsynced items
    var hasUnsyncedData: Bool { get }
}
