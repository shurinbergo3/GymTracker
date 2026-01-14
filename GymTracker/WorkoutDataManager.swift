//
//  WorkoutDataManager.swift
//  GymTracker
//
//  Created by Antigravity on 14.01.2026.
//

import Foundation
import FirebaseFirestore

class WorkoutDataManager {
    
    static let shared = WorkoutDataManager()
    
    private let db = Firestore.firestore()
    private let collectionName = "workouts"
    
    private init() {}
    
    // MARK: - Save
    
    func saveWorkout(workout: Workout) {
        do {
            try db.collection(collectionName).addDocument(from: workout) { error in
                if let error = error {
                    print("Error saving workout: \(error.localizedDescription)")
                } else {
                    print("Successfully saved workout!")
                }
            }
        } catch {
            print("Error encoding workout: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch
    
    func fetchHistory() async throws -> [Workout] {
        let snapshot = try await db.collection(collectionName)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Workout.self)
        }
    }
}
