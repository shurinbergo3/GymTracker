//
//  FirestoreStorageService.swift
//  GymTracker
//
//  Firestore implementation of StorageService
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Firestore implementation of cloud storage
/// Single Responsibility: Handle Firestore operations only
final class FirestoreStorageService: StorageService {
    private let db = Firestore.firestore()
    
    // MARK: - Workouts
    
    func saveWorkout(_ workout: Workout) async throws {
        guard let userId = getCurrentUserId() else {
            throw StorageError.notAuthenticated
        }
        
        let data = try encodeWorkout(workout)
        let workoutId = workout.id ?? UUID().uuidString
        try await saveToFirestore(userId: userId, workoutId: workoutId, data: data)
    }
    
    func fetchWorkouts() async throws -> [Workout] {
        guard let userId = getCurrentUserId() else {
            return []
        }
        
        let snapshot = try await fetchWorkoutsSnapshot(userId: userId)
        return parseWorkouts(from: snapshot)
    }
    
    func deleteAllWorkouts() async throws -> Int {
        guard let userId = getCurrentUserId() else {
            throw StorageError.notAuthenticated
        }
        
        let snapshot = try await fetchWorkoutsSnapshot(userId: userId)
        try await deleteWorkouts(from: snapshot)
        return snapshot.documents.count
    }
    
    func removeDuplicateWorkouts() async throws -> (total: Int, removed: Int, kept: Int) {
        // Implementation similar to FirestoreManager
        guard let userId = getCurrentUserId() else {
            throw StorageError.notAuthenticated
        }
        
        let snapshot = try await fetchWorkoutsSnapshot(userId: userId)
        let duplicates = findDuplicates(in: snapshot)
        try await deleteDuplicates(duplicates)
        
        return (
            total: snapshot.documents.count,
            removed: duplicates.count,
            kept: snapshot.documents.count - duplicates.count
        )
    }
    
    // MARK: - Programs
    
    func saveProgram(_ program: ProgramDTO) async throws {
        // TODO: Implement when ProgramDTO is created
        #if DEBUG
        print("⚠️ Program save not yet implemented")
        #endif
    }
    
    func fetchPrograms() async throws -> [ProgramDTO] {
        // TODO: Implement when ProgramDTO is created
        #if DEBUG
        print("⚠️ Program fetch not yet implemented")
        #endif
        return []
    }
    
    func deleteProgram(id: String) async throws {
        guard let userId = getCurrentUserId() else {
            throw StorageError.notAuthenticated
        }
        
        try await db.collection("users")
            .document(userId)
            .collection("programs")
            .document(id)
            .delete()
    }
    
    // MARK: - User Data
    
    func deleteUserDocument(uid: String) async throws {
        let userRef = db.collection("users").document(uid)
        
        // Delete workouts subcollection
        let workoutsSnapshot = try await userRef.collection("workouts").getDocuments()
        try await deleteDocuments(workoutsSnapshot.documents)
        
        // Delete programs subcollection
        let programsSnapshot = try await userRef.collection("programs").getDocuments()
        try await deleteDocuments(programsSnapshot.documents)
        
        // Delete user document
        try await userRef.delete()
    }
    
    // MARK: - Private Helpers (<10 lines each)
    
    private func getCurrentUserId() -> String? {
        Auth.auth().currentUser?.uid
    }
    
    private func encodeWorkout(_ workout: Workout) throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(workout)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    private func saveToFirestore(userId: String, workoutId: String, data: [String: Any]) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("workouts")
            .document(workoutId)
            .setData(data)
    }
    
    private func fetchWorkoutsSnapshot(userId: String) async throws -> QuerySnapshot {
        try await db.collection("users")
            .document(userId)
            .collection("workouts")
            .getDocuments()
    }
    
    private func parseWorkouts(from snapshot: QuerySnapshot) -> [Workout] {
        snapshot.documents.compactMap { doc -> Workout? in
            try? JSONDecoder().decode(Workout.self, from: JSONSerialization.data(withJSONObject: doc.data()))
        }
    }
    
    private func deleteWorkouts(from snapshot: QuerySnapshot) async throws {
        let batch = db.batch()
        snapshot.documents.forEach { batch.deleteDocument($0.reference) }
        try await batch.commit()
    }
    
    private func deleteDocuments(_ documents: [QueryDocumentSnapshot]) async throws {
        let batch = db.batch()
        documents.forEach { batch.deleteDocument($0.reference) }
        try await batch.commit()
    }
    
    private func findDuplicates(in snapshot: QuerySnapshot) -> [String] {
        // Simplified duplicate detection
        var seen = Set<String>()
        var duplicates: [String] = []
        
        for doc in snapshot.documents {
            guard let workout = try? JSONDecoder().decode(
                Workout.self,
                from: JSONSerialization.data(withJSONObject: doc.data())
            ) else { continue }
            
            // Use workoutType instead of programName (which doesn't exist in Workout)
            let key = "\(workout.workoutType)-\(Int(workout.date.timeIntervalSince1970 / 60))"
            
            if seen.contains(key) {
                duplicates.append(doc.documentID)
            } else {
                seen.insert(key)
            }
        }
        
        return duplicates
    }
    
    private func deleteDuplicates(_ documentIds: [String]) async throws {
        guard let userId = getCurrentUserId() else { return }
        
        let batch = db.batch()
        for docId in documentIds {
            let ref = db.collection("users")
                .document(userId)
                .collection("workouts")
                .document(docId)
            batch.deleteDocument(ref)
        }
        try await batch.commit()
    }
}

// MARK: - Error Types

enum StorageError: Error {
    case notAuthenticated
    case encodingFailed
}
