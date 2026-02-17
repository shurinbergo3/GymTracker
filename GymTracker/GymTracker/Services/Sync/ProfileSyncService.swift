//
//  ProfileSyncService.swift
//  GymTracker
//
//  Syncs user profile to/from cloud (SRP: Only profile sync)
//

import Foundation
import SwiftData

/// Handles user profile synchronization
/// Single Responsibility: Sync profile only
final class ProfileSyncService {
    private let storage: StorageService
    
    init(storage: StorageService) {
        self.storage = storage
    }
    
    // MARK: - Upload (Push)
    
    func syncProfile(profile: UserProfile, activeProgram: Program?, context: ModelContext) async {
        // TODO: Implement when ProfileDTO is created
        // Real UserProfile fields: height, age, weightHistory
        #if DEBUG
        print("⚠️ Profile sync not yet fully implemented")
        print("   Height: \(profile.height), Age: \(profile.age)")
        print("   Weight history: \(profile.weightHistory.count) records")
        #endif
    }
    
    // MARK: - Download (Pull)
    
    func restoreProfile(container: ModelContext) async {
        // TODO: Implement when storage methods are ready
        #if DEBUG
        print("⚠️ Profile restore not yet implemented")
        #endif
    }
}
