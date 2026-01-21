//
//  FirestoreManager.swift
//  GymTracker
//
//  Created by Antigravity on 14.01.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreManager {
    
    static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Save
    
    func save(workout: Workout) {
        // Authenticated user check
        guard let userId = Auth.auth().currentUser?.uid else {
             #if DEBUG
             print("Error: User not logged in, cannot save workout.")
             #endif
             return
        }
        
        // Path: users/{userID}/workouts
        let collectionPath = "users/\(userId)/workouts"
        
        do {
            try db.collection(collectionPath).addDocument(from: workout) { error in
                if let error = error {
                    #if DEBUG
                    print("Error saving workout to Firestore: \(error.localizedDescription)")
                    #endif
                } else {
                    #if DEBUG
                    print("Successfully saved workout to \(collectionPath)!")
                    #endif
                }
            }
        } catch {
            #if DEBUG
            print("Error encoding workout: \(error.localizedDescription)")
            #endif
        }
    }
    
    // MARK: - Fetch
    
    func fetchHistory() async throws -> [Workout] {
        guard let userId = Auth.auth().currentUser?.uid else {
             #if DEBUG
             print("Error: User not logged in, cannot fetch history.")
             #endif
             return []
        }
        
        let collectionPath = "users/\(userId)/workouts"
        
        let snapshot = try await db.collection(collectionPath)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Workout.self)
        }
    }
    
    /// Async version of save that throws errors for sync tracking
    func saveAsync(workout: Workout) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let collectionPath = "users/\(userId)/workouts"
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try db.collection(collectionPath).addDocument(from: workout) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Delete User Data
    
    /// Delete user document and all subcollections from Firestore
    /// Used during account deletion for compliance with App Store guidelines
    func deleteUserDocument(uid: String) async throws {
        let userDocRef = db.collection("users").document(uid)
        
        // Delete workouts subcollection first
        let workoutsSnapshot = try await userDocRef.collection("workouts").getDocuments()
        for document in workoutsSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete user document
        try await userDocRef.delete()
        
        #if DEBUG
        print("✅ Deleted Firestore data for user: \(uid)")
        #endif
    }
}
