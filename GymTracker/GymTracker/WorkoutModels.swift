//
//  WorkoutModels.swift
//  GymTracker
//
//  Created by Antigravity on 14.01.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore Models

struct Workout: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var workoutType: String
    var duration: TimeInterval
    var calories: Int?
    var notes: String?
    var exercises: [Exercise]
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case workoutType
        case duration
        case calories
        case notes
        case exercises
    }
}

struct Exercise: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var sets: [ExerciseSet]
}

struct ExerciseSet: Codable, Identifiable {
    var id: String = UUID().uuidString
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    var setNumber: Int
    var comment: String? // Added comment support
}

// MARK: - Stable identity

extension Workout {
    /// Deterministic Firestore document ID derived from the workout's immutable
    /// (date, type) identity. Re-uploading the same workout — including a session
    /// restored from the cloud — yields the same ID, so `setData` overwrites the
    /// existing document instead of creating a duplicate. This makes sync
    /// idempotent and retry-safe without a stored UUID on `WorkoutSession`.
    ///
    /// Second-level precision is robust to the microsecond drift introduced by a
    /// Firestore `Date`↔`Timestamp` round-trip, and is unique in practice (a user
    /// cannot start two workouts of the same type within the same second).
    var deterministicDocumentID: String {
        let seconds = Int(date.timeIntervalSince1970.rounded())
        let safeType = workoutType
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Firestore document IDs must be ≤1500 bytes; clamp defensively.
        return String("\(seconds)_\(safeType)".prefix(1400))
    }
}

// MARK: - Mappers

extension Workout {
    init(from session: WorkoutSession) {
        self.date = session.date
        self.workoutType = session.workoutDayName
        self.notes = session.notes
        // Duration logic: if endTime is present, calculate diff, else 0
        if let endTime = session.endTime {
            self.duration = endTime.timeIntervalSince(session.date)
        } else {
            self.duration = 0
        }
        self.calories = session.calories 
        
        let groupedSets = Dictionary(grouping: session.sets) { $0.exerciseName }
        self.exercises = groupedSets.map { (name, sets) in
            let exerciseSets = sets.sorted { 
                // Сортируем по времени создания, потом по номеру подхода
                if $0.date != $1.date {
                    return $0.date < $1.date
                }
                return $0.setNumber < $1.setNumber
            }.map { set in
                ExerciseSet(
                    weight: set.weight,
                    reps: set.reps,
                    isCompleted: set.isCompleted,
                    setNumber: set.setNumber,
                    comment: set.comment
                )
            }
            return Exercise(name: name, sets: exerciseSets)
        }
    }
}
