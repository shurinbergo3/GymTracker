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
    var notes: String?
    var exercises: [Exercise]
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case workoutType
        case duration
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
}

// MARK: - Mappers

extension Workout {
    init(from session: WorkoutSession) {
        self.date = session.date
        self.workoutType = session.workoutDayName
        self.notes = session.notes
        // Assuming duration logic is handled elsewhere or default 0 if not tracked per session
        self.duration = 0 
        
        let groupedSets = Dictionary(grouping: session.sets) { $0.exerciseName }
        self.exercises = groupedSets.map { (name, sets) in
            let exerciseSets = sets.sorted { $0.setNumber < $1.setNumber }.map { set in
                ExerciseSet(
                    weight: set.weight,
                    reps: set.reps,
                    isCompleted: set.isCompleted,
                    setNumber: set.setNumber
                )
            }
            return Exercise(name: name, sets: exerciseSets)
        }
    }
}
