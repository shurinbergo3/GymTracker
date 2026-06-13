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
        // NOT IMPLEMENTED + NOT WIRED. The live app syncs the profile via
        // SyncManager. Trap in DEBUG so accidentally routing real sync through
        // this stub is caught immediately instead of silently dropping data.
        assertionFailure("ProfileSyncService.syncProfile is a stub — use SyncManager")
    }

    // MARK: - Download (Pull)

    func restoreProfile(container: ModelContext) async {
        assertionFailure("ProfileSyncService.restoreProfile is a stub — use SyncManager")
    }
}
