//
//  ProgramModels.swift
//  GymTracker
//
//  Created by Antigravity on 30.01.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Program DTOs (Firestore)

struct ProgramDTO: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var desc: String
    var startDate: Date
    var isActive: Bool
    var displayOrder: Int
    var days: [WorkoutDayDTO]
    
    // Explicit init for mapping
    init(from program: Program) {
        self.id = program.id.uuidString // Use improved UUID for robustness
        self.name = program.name
        self.desc = program.desc
        self.startDate = program.startDate
        self.isActive = program.isActive
        self.displayOrder = program.displayOrder
        self.days = program.days.sorted { $0.orderIndex < $1.orderIndex }.map { WorkoutDayDTO(from: $0) }
    }
}

struct WorkoutDayDTO: Codable {
    var name: String
    var orderIndex: Int
    var workoutType: String
    var defaultRestTime: Int
    var restTimerEnabled: Bool
    var exercises: [ExerciseTemplateDTO]
    
    init(from day: WorkoutDay) {
        self.name = day.name
        self.orderIndex = day.orderIndex
        self.workoutType = day.workoutType.rawValue
        self.defaultRestTime = day.defaultRestTime
        self.restTimerEnabled = day.restTimerEnabled
        self.exercises = day.exercises.sorted { $0.orderIndex < $1.orderIndex }.map { ExerciseTemplateDTO(from: $0) }
    }
}

struct ExerciseTemplateDTO: Codable {
    var id: String
    var name: String
    var plannedSets: Int
    var orderIndex: Int
    var customWorkoutType: String?
    
    init(from template: ExerciseTemplate) {
        self.id = template.id.uuidString
        self.name = template.name
        self.plannedSets = template.plannedSets
        self.orderIndex = template.orderIndex
        self.customWorkoutType = template._customWorkoutType?.rawValue
    }
}
