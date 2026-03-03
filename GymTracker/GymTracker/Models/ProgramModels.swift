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
    var isUserModified: Bool
    var days: [WorkoutDayDTO]

    enum CodingKeys: String, CodingKey {
        case id, name, desc, startDate, isActive, displayOrder, isUserModified, days
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        desc = try container.decode(String.self, forKey: .desc)
        startDate = try container.decode(Date.self, forKey: .startDate)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 0
        isUserModified = try container.decodeIfPresent(Bool.self, forKey: .isUserModified) ?? false
        days = try container.decode([WorkoutDayDTO].self, forKey: .days)
    }
    
    // Explicit init for mapping
    init(from program: Program) {
        self.id = program.id.uuidString // Use improved UUID for robustness
        self.name = program.name
        self.desc = program.desc
        self.startDate = program.startDate
        self.isActive = program.isActive
        self.displayOrder = program.displayOrder
        self.isUserModified = program.isUserModified
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

// MARK: - Custom Exercise DTO (Firestore)

struct CustomExerciseDTO: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var category: String
    var muscleGroup: String
    var defaultType: String
    var technique: String?
    var videoUrl: String?
    var createdAt: Date
    
    init(from exercise: CustomExercise) {
        self.id = exercise.id.uuidString
        self.name = exercise.name
        self.category = exercise.category
        self.muscleGroup = exercise.muscleGroup
        self.defaultType = exercise.defaultType
        self.technique = exercise.technique
        self.videoUrl = exercise.videoUrl
        self.createdAt = exercise.createdAt
    }
}
