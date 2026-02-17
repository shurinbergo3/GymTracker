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
    var age: Int // возраст
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
    
    init(height: Double, initialWeight: Double, age: Int = 30) {
        self.height = height
        self.age = age
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
    
    var localizedName: String {
        switch self {
        case .biceps: return "Бицепс".localized()
        case .chest: return "Грудь".localized()
        case .waist: return "Талия".localized()
        case .thigh: return "Бедро".localized()
        case .calf: return "Икра".localized()
        case .forearm: return "Предплечье".localized()
        case .neck: return "Шея".localized()
        case .shoulders: return "Плечи".localized()
        }
    }
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
    case strength = "strength"
    case repsOnly = "repsOnly"
    case duration = "duration"
    
    var displayName: String {
        switch self {
        case .strength: return "Силовая".localized()
        case .repsOnly: return "Свой вес".localized()
        case .duration: return "На время / Кардио".localized()
        }
    }
    
    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .repsOnly: return "figure.walk"
        case .duration: return "stopwatch.fill"
        }
    }
    
}

// MARK: - Custom Exercise (User-Created)

@Model
final class CustomExercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String // raw value of ExerciseCategory
    var muscleGroup: String // raw value of MuscleGroup
    var defaultType: String // raw value of WorkoutType
    var technique: String?
    var videoUrl: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, category: String, muscleGroup: String, defaultType: String, technique: String? = nil, videoUrl: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroup = muscleGroup
        self.defaultType = defaultType
        self.technique = technique
        self.videoUrl = videoUrl
        self.createdAt = createdAt
    }
    
    /// Initialize from LibraryExercise
    convenience init(from libraryExercise: LibraryExercise) {
        self.init(
            id: libraryExercise.id,
            name: libraryExercise.name,
            category: libraryExercise.category.rawValue,
            muscleGroup: libraryExercise.muscleGroup.rawValue,
            defaultType: libraryExercise.defaultType.rawValue,
            technique: libraryExercise.technique,
            videoUrl: libraryExercise.videoUrl,
            createdAt: Date()
        )
    }
}

// MARK: - Program

@Model
final class Program {
    @Attribute(.unique) var id: UUID = UUID() // Added for robust identification
    var name: String
    var desc: String
    var startDate: Date
    var isActive: Bool
    var displayOrder: Int = 100 // Default to 100 (low priority)
    var isUserModified: Bool = false // Track if user edited this program
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.program)
    var days: [WorkoutDay]
    
    init(name: String, desc: String = "", startDate: Date = Date(), isActive: Bool = false, displayOrder: Int = 100) {
        self.id = UUID()
        self.name = name
        self.desc = desc
        self.startDate = startDate
        self.isActive = isActive
        self.displayOrder = displayOrder
        self.isUserModified = false
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
    
    var defaultRestTime: Int = 90 // default rest time between sets in seconds
    var restTimerEnabled: Bool = true // whether rest timer is enabled for this day
    
    var program: Program?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseTemplate.workoutDay)
    var exercises: [ExerciseTemplate]
    
    init(name: String, orderIndex: Int, workoutType: WorkoutType = .strength, defaultRestTime: Int = 90, restTimerEnabled: Bool = true) {
        self.name = name
        self.orderIndex = orderIndex
        self._workoutType = workoutType
        self.defaultRestTime = defaultRestTime
        self.restTimerEnabled = restTimerEnabled
        self.exercises = []
    }
}

// MARK: - Exercise Template

@Model
final class ExerciseTemplate {
    var id: UUID
    var name: String // название упражнения
    var plannedSets: Int // плановое кол-во подходов
    var orderIndex: Int // порядок в списке упражнений
    
    var workoutDay: WorkoutDay?
    
    // New: Allow exercise-specific type override (e.g. Bodyweight in a Strength day)
    var _customWorkoutType: WorkoutType?
    

    
    init(name: String, plannedSets: Int = 3, orderIndex: Int = 0, type: WorkoutType? = nil) {
        self.id = UUID()
        self.name = name
        self.plannedSets = plannedSets
        self.orderIndex = orderIndex
        self._customWorkoutType = type
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
    var isSynced: Bool? // Optional to avoid migration - nil means needs sync
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet]
    
    init(date: Date = Date(), workoutDayName: String, programName: String? = nil, notes: String? = nil) {
        self.date = date
        self.workoutDayName = workoutDayName
        self.programName = programName
        self.notes = notes
        self.isCompleted = false
        self.isSynced = false
        self.sets = []
    }
    
    // Helper computed property for easy checking
    var needsSync: Bool {
        return isSynced != true && isCompleted
    }
}

// MARK: - Workout Set

@Model
final class WorkoutSet {
    var exerciseName: String // название упражнения
    private var _weight: Double // вес в кг
    private var _reps: Int // количество повторений
    var date: Date
    var isCompleted: Bool
    var comment: String?
    var setNumber: Int // номер подхода (1, 2, 3...)
    var duration: TimeInterval? // длительность для круговых/кардио (в секундах)
    var distance: Double? // дистанция для кардио (в км)
    
    var session: WorkoutSession?
    
    // New: Indicates if bodyweight exercise has added weight
    var isWeighted: Bool
    
    // Validated properties
    var weight: Double {
        get { _weight }
        set { _weight = max(0, newValue) } // Can't be negative
    }
    
    var reps: Int {
        get { _reps }
        set { _reps = max(0, newValue) } // Can't be negative
    }
    
    init(exerciseName: String, weight: Double = 0, reps: Int = 0, setNumber: Int = 1, date: Date = Date(), isWeighted: Bool = false) {
        self.exerciseName = exerciseName
        self._weight = max(0, weight)
        self._reps = max(0, reps)
        self.setNumber = setNumber
        self.date = date
        self.isCompleted = false
        self.comment = nil
        self.isWeighted = isWeighted
    }
}

extension ExerciseTemplate {
    var resolvedWorkoutType: WorkoutType {
        get { _customWorkoutType ?? workoutDay?.workoutType ?? .strength }
        set { _customWorkoutType = newValue }
    }
}
