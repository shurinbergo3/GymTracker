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
        
        #if DEBUG
        print("📥 Fetching workouts from Firestore...")
        #endif
        
        let snapshot = try await db.collection(collectionPath)
            .order(by: "date", descending: true)
            .getDocuments()
        
        #if DEBUG
        print("📥 Found \(snapshot.documents.count) workout documents in Firestore")
        #endif
        
        var workouts: [Workout] = []
        var failedCount = 0
        
        for (index, document) in snapshot.documents.enumerated() {
            do {
                let workout = try document.data(as: Workout.self)
                workouts.append(workout)
            } catch {
                failedCount += 1
                #if DEBUG
                if failedCount <= 3 {
                    // Log first 3 errors only to avoid spam
                    print("⚠️ Failed to parse workout document \(index): \(error)")
                }
                #endif
            }
        }
        
        #if DEBUG
        if failedCount > 0 {
            print("⚠️ Failed to parse \(failedCount)/\(snapshot.documents.count) workout documents")
        }
        print("✅ Successfully parsed \(workouts.count) workouts")
        #endif
        
        return workouts
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
    
    /// Remove duplicate workouts from Firestore
    /// Returns tuple: (total workouts, duplicates removed, unique kept)
    func removeDuplicateWorkoutsFromFirestore() async throws -> (total: Int, removed: Int, kept: Int) {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let collectionPath = "users/\(userId)/workouts"
        let workoutsSnapshot = try await db.collection(collectionPath).getDocuments()
        
        let totalCount = workoutsSnapshot.documents.count
        
        // Group by workout signature (date + dayName)
        var workoutGroups: [String: [(docId: String, date: Date)]] = [:]
        
        for document in workoutsSnapshot.documents {
            guard let workout = try? document.data(as: Workout.self) else { continue }
            
            // Create unique key: date (rounded to nearest 5 minutes) + workoutType (which stores day name)
            let roundedDate = Date(timeIntervalSince1970: floor(workout.date.timeIntervalSince1970 / 300) * 300)
            let key = "\(workout.workoutType)_\(roundedDate.timeIntervalSince1970)"
            
            if workoutGroups[key] == nil {
                workoutGroups[key] = []
            }
            workoutGroups[key]?.append((docId: document.documentID, date: workout.date))
        }
        
        // Find duplicates (keep the earliest one in each group)
        var documentsToDelete: [String] = []
        
        for (_, group) in workoutGroups {
            if group.count > 1 {
                // Sort by date and keep the first one
                let sorted = group.sorted { $0.date < $1.date }
                // Delete all except the first (earliest)
                for duplicate in sorted.dropFirst() {
                    documentsToDelete.append(duplicate.docId)
                }
            }
        }
        
        // Delete duplicates in batches
        for batch in stride(from: 0, to: documentsToDelete.count, by: 500) {
            let batchDocIds = Array(documentsToDelete[batch..<min(batch + 500, documentsToDelete.count)])
            let writeBatch = db.batch()
            
            for docId in batchDocIds {
                let docRef = db.collection(collectionPath).document(docId)
                writeBatch.deleteDocument(docRef)
            }
            
            try await commitBatchSafely(writeBatch)
        }
        
        let uniqueCount = totalCount - documentsToDelete.count
        
        #if DEBUG
        print("✅ Firestore deduplication: \(totalCount) total, removed \(documentsToDelete.count) duplicates, kept \(uniqueCount) unique")
        #endif
        
        return (total: totalCount, removed: documentsToDelete.count, kept: uniqueCount)
    }
    
    /// Delete ALL workouts from Firestore (for cleaning duplicates)
    func deleteAllWorkouts() async throws -> Int {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let collectionPath = "users/\(userId)/workouts"
        let workoutsSnapshot = try await db.collection(collectionPath).getDocuments()
        
        let count = workoutsSnapshot.documents.count
        
        // Delete in batches of 500 (Firestore limit)
        for batch in stride(from: 0, to: workoutsSnapshot.documents.count, by: 500) {
            let batchDocuments = Array(workoutsSnapshot.documents[batch..<min(batch + 500, workoutsSnapshot.documents.count)])
            let writeBatch = db.batch()
            
            for document in batchDocuments {
                writeBatch.deleteDocument(document.reference)
            }
            
            try await commitBatchSafely(writeBatch)
        }
        
        #if DEBUG
        print("✅ Deleted \(count) workouts from Firestore")
        #endif
        
        return count
    }
    
    // Helper to safely commit batch without weird compiler warnings
    private func commitBatchSafely(_ batch: WriteBatch) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            batch.commit { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Delete user document and all subcollections from Firestore
    /// Used during account deletion for compliance with App Store guidelines
    func deleteUserDocument(uid: String) async throws {
        let userDocRef = db.collection("users").document(uid)
        
        // Delete workouts subcollection first
        let workoutsSnapshot = try await userDocRef.collection("workouts").getDocuments()
        for document in workoutsSnapshot.documents {
            let docRef = document.reference
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                docRef.delete { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
        
        // Delete user document
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            userDocRef.delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        #if DEBUG
        print("✅ Deleted Firestore data for user: \(uid)")
        #endif
    }
    // MARK: - Programs Sync
    
    func saveProgram(_ program: ProgramDTO) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let collectionPath = "users/\(userId)/programs"
        
        // Use program name (sanitized) or UUID as document ID
        // Use UUID from DTO (preferred) or sanitized name as fallback
        let docId = program.id ?? program.name.replacingOccurrences(of: "/", with: "_") 
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try db.collection(collectionPath).document(docId).setData(from: program) { error in
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
        
        #if DEBUG
        print("✅ Saved program '\(program.name)' to Firestore")
        #endif
    }
    
    func fetchPrograms() async throws -> [ProgramDTO] {
        guard let userId = Auth.auth().currentUser?.uid else { 
            #if DEBUG
            print("⚠️ Cannot fetch programs: User not logged in")
            #endif
            return [] 
        }
        
        let collectionPath = "users/\(userId)/programs"
        
        #if DEBUG
        print("📥 Fetching programs from Firestore...")
        #endif
        
        let snapshot = try await db.collection(collectionPath).getDocuments()
        
        #if DEBUG
        print("📥 Found \(snapshot.documents.count) program documents in Firestore")
        #endif
        
        let programs = snapshot.documents.compactMap { document -> ProgramDTO? in
            do {
                return try document.data(as: ProgramDTO.self)
            } catch {
                #if DEBUG
                print("⚠️ Failed to parse program document: \(error)")
                #endif
                return nil
            }
        }
        
        #if DEBUG
        print("✅ Successfully parsed \(programs.count) programs")
        #endif
        
        return programs
    }
    
    func deleteProgram(id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let collectionPath = "users/\(userId)/programs"
        
        // We need to handle both cases: manual ID logic or Firestore ID
        // Since we pass an ID, we assume it's the document ID.
        // However, if the legacy saved strategy was `program.name`, we might need to be careful.
        // But for deletion, we should rely on what SyncManager passes.
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(collectionPath).document(id).delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        #if DEBUG
        print("✅ Deleted program '\(id)' from Firestore")
        #endif
    }
    
    // MARK: - Custom Exercises Sync
    
    func saveCustomExercise(_ exercise: CustomExerciseDTO) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let collectionPath = "users/\(userId)/customExercises"
        let docId = exercise.id ?? UUID().uuidString
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try db.collection(collectionPath).document(docId).setData(from: exercise) { error in
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
        
        #if DEBUG
        print("✅ Saved custom exercise '\(exercise.name)' to Firestore")
        #endif
    }
    
    func fetchCustomExercises() async throws -> [CustomExerciseDTO] {
        guard let userId = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("⚠️ Cannot fetch custom exercises: User not logged in")
            #endif
            return []
        }
        
        let collectionPath = "users/\(userId)/customExercises"
        
        #if DEBUG
        print("📥 Fetching custom exercises from Firestore...")
        #endif
        
        let snapshot = try await db.collection(collectionPath).getDocuments()
        
        #if DEBUG
        print("📥 Found \(snapshot.documents.count) custom exercise documents in Firestore")
        #endif
        
        let exercises = snapshot.documents.compactMap { document -> CustomExerciseDTO? in
            do {
                return try document.data(as: CustomExerciseDTO.self)
            } catch {
                #if DEBUG
                print("⚠️ Failed to parse custom exercise document: \(error)")
                #endif
                return nil
            }
        }
        
        #if DEBUG
        print("✅ Successfully parsed \(exercises.count) custom exercises")
        #endif
        
        return exercises
    }
}
