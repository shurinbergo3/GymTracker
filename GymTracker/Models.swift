//
//  Models.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import Foundation
import SwiftData

// MARK: - User Profile

@Model
final class UserProfile {
    var height: Double // в см
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \WeightRecord.userProfile)
    var weightHistory: [WeightRecord]
    
    // Computed property для текущего веса
    var currentWeight: Double {
        weightHistory
            .sorted { $0.date > $1.date }
            .first?.weight ?? 0
    }
    
    init(height: Double, initialWeight: Double) {
        self.height = height
        self.createdAt = Date()
        self.updatedAt = Date()
        self.weightHistory = []
        
        // Создаем первую запись веса
        let firstRecord = WeightRecord(weight: initialWeight, date: Date())
        self.weightHistory.append(firstRecord)
    }
}

// MARK: - Weight Record

@Model
final class WeightRecord {
    var weight: Double // в кг
    var date: Date
    var userProfile: UserProfile?
    
    init(weight: Double, date: Date = Date()) {
        self.weight = weight
        self.date = date
    }
}

// MARK: - Body Measurement

enum MeasurementType: String, Codable, CaseIterable {
    case biceps = "Бицепс"
    case chest = "Грудь"
    case waist = "Талия"
    case thigh = "Бедро"
    case calf = "Икра"
    case forearm = "Предплечье"
    case neck = "Шея"
    case shoulders = "Плечи"
}

@Model
final class BodyMeasurement {
    var date: Date
    var type: MeasurementType
    var value: Double // в см
    
    init(date: Date = Date(), type: MeasurementType, value: Double) {
        self.date = date
        self.type = type
        self.value = value
    }
}

// MARK: - Workout Type

enum WorkoutType: String, Codable, CaseIterable {
    case strength = "Силовая"
    case circuit = "Круговая"
    case cardio = "Кардио"
    
    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .circuit: return "flame.fill"
        case .cardio: return "heart.fill"
        }
    }
}

// MARK: - Program

@Model
final class Program {
    var name: String
    var desc: String
    var startDate: Date
    var isActive: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.program)
    var days: [WorkoutDay]
    
    init(name: String, desc: String = "", startDate: Date = Date(), isActive: Bool = false) {
        self.name = name
        self.desc = desc
        self.startDate = startDate
        self.isActive = isActive
        self.days = []
    }
    
    /// Вычисляет индекс текущего дня тренировки на основе циклического повторения программы
    func currentDayIndex() -> Int {
        guard !days.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let daysPassed = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        return daysPassed % days.count
    }
    
    /// Возвращает текущую тренировку дня
    func currentWorkoutDay() -> WorkoutDay? {
        guard !days.isEmpty else { return nil }
        let sortedDays = days.sorted { $0.orderIndex < $1.orderIndex }
        return sortedDays[currentDayIndex()]
    }
}

// MARK: - Workout Day

@Model
final class WorkoutDay {
    var name: String // например, "День спины"
    var orderIndex: Int // порядковый номер в программе (0, 1, 2...)
    var _workoutType: WorkoutType? // тип тренировки (силовая, круговая, кардио)
    
    // Computed property для безопасного доступа с дефолтным значением
    var workoutType: WorkoutType {
        get { _workoutType ?? .strength }
        set { _workoutType = newValue }
    }
    
    var program: Program?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseTemplate.workoutDay)
    var exercises: [ExerciseTemplate]
    
    init(name: String, orderIndex: Int, workoutType: WorkoutType = .strength) {
        self.name = name
        self.orderIndex = orderIndex
        self._workoutType = workoutType
        self.exercises = []
    }
}

// MARK: - Exercise Template

@Model
final class ExerciseTemplate {
    var name: String // название упражнения
    var plannedSets: Int // плановое кол-во подходов
    var orderIndex: Int // порядок в списке упражнений
    
    var workoutDay: WorkoutDay?
    
    init(name: String, plannedSets: Int = 3, orderIndex: Int = 0) {
        self.name = name
        self.plannedSets = plannedSets
        self.orderIndex = orderIndex
    }
}

// MARK: - Workout Session

@Model
final class WorkoutSession {
    var date: Date
    var workoutDayName: String // название дня тренировки
    var programName: String? // название программы
    var notes: String?
    var isCompleted: Bool
    var endTime: Date?
    var calories: Int?
    var averageHeartRate: Int?
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet]
    
    init(date: Date = Date(), workoutDayName: String, programName: String? = nil, notes: String? = nil) {
        self.date = date
        self.workoutDayName = workoutDayName
        self.programName = programName
        self.notes = notes
        self.isCompleted = false
        self.sets = []
    }
}

// MARK: - Workout Set

@Model
final class WorkoutSet {
    var exerciseName: String // название упражнения
    var weight: Double // вес в кг
    var reps: Int // количество повторений
    var date: Date
    var isCompleted: Bool
    var comment: String?
    var setNumber: Int // номер подхода (1, 2, 3...)
    var duration: TimeInterval? // длительность для круговых/кардио (в секундах)
    var distance: Double? // дистанция для кардио (в км)
    
    var session: WorkoutSession?
    
    init(exerciseName: String, weight: Double = 0, reps: Int = 0, setNumber: Int = 1, date: Date = Date()) {
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.setNumber = setNumber
        self.date = date
        self.isCompleted = false
        self.comment = nil
    }
}
