//
//  AccountDeletionService.swift
//  GymTracker
//
//  Service for account deletion (SRP: Only deletion logic)
//

import Foundation
import SwiftData
import FirebaseAuth

/// Handles account deletion logic
/// Single Responsibility: Delete user account and all data
final class AccountDeletionService {
    private let storage: StorageService
    
    init(storage: StorageService) {
        self.storage = storage
    }
    
    func deleteAccount(modelContext: ModelContext) async throws {
        guard let user = getCurrentUser() else {
            throw DeletionError.notAuthenticated
        }
        
        let uid = user.uid
        
        try await deleteFirestoreData(uid: uid)
        try await deleteAuthUser(user)
        try await clearLocalData(context: modelContext)
        clearUserDefaults()
    }
    
    // MARK: - Private Helpers (<10 lines)
    
    private func getCurrentUser() -> FirebaseAuth.User? {
        Auth.auth().currentUser
    }
    
    private func deleteFirestoreData(uid: String) async throws {
        do {
            try await storage.deleteUserDocument(uid: uid)
        } catch {
            // Continue even if Firestore deletion fails
            #if DEBUG
            print("⚠️ Firestore deletion failed: \(error)")
            #endif
        }
    }
    
    private func deleteAuthUser(_ user: FirebaseAuth.User) async throws {
        do {
            try await user.delete()
        } catch let error as NSError {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                throw DeletionError.reauthenticationRequired
            }
            throw error
        }
    }
    
    private func clearLocalData(context: ModelContext) async throws {
        try context.delete(model: WorkoutSession.self)
        try context.delete(model: WorkoutSet.self)
        try context.delete(model: UserProfile.self)
        try context.delete(model: WeightRecord.self)
        try context.delete(model: BodyMeasurement.self)
        try context.delete(model: Program.self)
        try context.delete(model: WorkoutDay.self)
        try context.delete(model: ExerciseTemplate.self)
        try context.save()
    }
    
    private func clearUserDefaults() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Error Types

enum DeletionError: Error {
    case notAuthenticated
    case reauthenticationRequired
}
