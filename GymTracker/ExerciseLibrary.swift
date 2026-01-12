//
//  ExerciseLibrary.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import Foundation

// MARK: - Exercise Categories

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case chest = "Грудь"
    case back = "Спина"
    case legs = "Ноги"
    case shoulders = "Плечи"
    case arms = "Руки"
    case core = "Кор"
    case cardio = "Кардио"
    case complex = "Комплексные"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.arms.open"
        case .legs: return "figure.walk"
        case .shoulders: return "figure.arms.open"
        case .arms: return "figure.flexibility"
        case .core: return "figure.core.training"
        case .cardio: return "heart.fill"
        case .complex: return "figure.mixed.cardio"
        }
    }
}

enum MuscleGroup: String, CaseIterable {
    // Грудь
    case upperChest = "Верх груди"
    case middleChest = "Середина груди"
    case lowerChest = "Низ груди"
    
    // Спина
    case lats = "Широчайшие"
    case trapezius = "Трапеции"
    case lowerBack = "Поясница"
    
    // Ноги
    case quadriceps = "Квадрицепсы"
    case hamstrings = "Бицепс бедра"
    case glutes = "Ягодицы"
    case calves = "Икры"
    
    // Плечи
    case frontDelts = "Передние дельты"
    case sideDelts = "Средние дельты"
    case rearDelts = "Задние дельты"
    
    // Руки
    case biceps = "Бицепс"
    case triceps = "Трицепс"
    case forearms = "Предплечья"
    
    // Кор и полное тело
    case core = "Кор"
    case fullBody = "Все тело"
}

// MARK: - Library Exercise

struct LibraryExercise: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let muscleGroup: MuscleGroup
    let technique: String? // Описание техники выполнения и cue
    
    init(name: String, category: ExerciseCategory, muscleGroup: MuscleGroup, technique: String? = nil) {
        self.name = name
        self.category = category
        self.muscleGroup = muscleGroup
        self.technique = technique
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LibraryExercise, rhs: LibraryExercise) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Exercise Library

struct ExerciseLibrary {
    static let allExercises: [LibraryExercise] = [
        // ГРУДЬ
        LibraryExercise(
            name: "Жим штанги лежа",
            category: .chest,
            muscleGroup: .middleChest,
            technique: "Cue: Пытайся сдвинуть руки друг к другу, будто хочешь согнуть гриф буквой U. Лопатки в задние карманы."
        ),
        LibraryExercise(name: "Жим гантелей лежа", category: .chest, muscleGroup: .middleChest),
        LibraryExercise(name: "Жим на наклонной скамье", category: .chest, muscleGroup: .upperChest),
        LibraryExercise(name: "Разводка гантелей", category: .chest, muscleGroup: .middleChest),
        LibraryExercise(name: "Отжимания на брусьях", category: .chest, muscleGroup: .lowerChest),
        
        // СПИНА
        LibraryExercise(name: "Подтягивания", category: .back, muscleGroup: .lats),
        LibraryExercise(name: "Тяга штанги в наклоне", category: .back, muscleGroup: .lats),
        LibraryExercise(
            name: "Тяга верхнего блока",
            category: .back,
            muscleGroup: .lats,
            technique: "Cue: Тяни локтями вниз. Представь, что руки - это крюки."
        ),
        LibraryExercise(name: "Тяга гантелей в наклоне", category: .back, muscleGroup: .lats),
        LibraryExercise(name: "Шраги со штангой", category: .back, muscleGroup: .trapezius),
        LibraryExercise(name: "Гиперэкстензия", category: .back, muscleGroup: .lowerBack),
        LibraryExercise(
            name: "Лицевая тяга",
            category: .back,
            muscleGroup: .rearDelts,
            technique: "Cue: Поза двойной бицепс. Тяни к лицу, вращая плечи наружу. Не поднимай плечи к ушам."
        ),
        LibraryExercise(name: "Тяга Т-грифа с упором", category: .back, muscleGroup: .lats),
        
        // НОГИ
        LibraryExercise(
            name: "Приседания со штангой",
            category: .legs,
            muscleGroup: .quadriceps,
            technique: "Cue: Разорви пол стопами в стороны. На старте сгибай колени и таз одновременно. Дави пятками."
        ),
        LibraryExercise(name: "Жим ногами", category: .legs, muscleGroup: .quadriceps),
        LibraryExercise(name: "Выпады с гантелями", category: .legs, muscleGroup: .quadriceps),
        LibraryExercise(
            name: "Румынская тяга",
            category: .legs,
            muscleGroup: .hamstrings,
            technique: "Cue: Толкай планету ногами вниз, а не тяни спиной. Представь, что держишь апельсины подмышками."
        ),
        LibraryExercise(name: "Сгибания ног лежа", category: .legs, muscleGroup: .hamstrings),
        LibraryExercise(name: "Подъемы на носки стоя", category: .legs, muscleGroup: .calves),
        LibraryExercise(
            name: "Ягодичный мост со штангой",
            category: .legs,
            muscleGroup: .glutes,
            technique: "Cue: Подкрути таз в верхней точке. Подбородок прижат к груди."
        ),
        LibraryExercise(name: "Кубковые приседания", category: .legs, muscleGroup: .quadriceps),
        LibraryExercise(name: "Болгарские выпады", category: .legs, muscleGroup: .quadriceps),
        
        // ПЛЕЧИ
        LibraryExercise(name: "Жим штанги стоя", category: .shoulders, muscleGroup: .frontDelts),
        LibraryExercise(name: "Жим гантелей сидя", category: .shoulders, muscleGroup: .frontDelts),
        LibraryExercise(name: "Махи гантелями в стороны", category: .shoulders, muscleGroup: .sideDelts),
        LibraryExercise(name: "Махи в наклоне", category: .shoulders, muscleGroup: .rearDelts),
        
        // РУКИ
        LibraryExercise(name: "Подъем штанги на бицепс", category: .arms, muscleGroup: .biceps),
        LibraryExercise(name: "Молотковые сгибания", category: .arms, muscleGroup: .biceps),
        LibraryExercise(name: "Французский жим", category: .arms, muscleGroup: .triceps),
        LibraryExercise(name: "Разгибания на блоке", category: .arms, muscleGroup: .triceps),
        LibraryExercise(name: "Сгибание на блоке спиной", category: .arms, muscleGroup: .biceps),
        LibraryExercise(name: "Разгибание на канате над головой", category: .arms, muscleGroup: .triceps),
        
        // КОР
        LibraryExercise(name: "Планка", category: .core, muscleGroup: .core),
        LibraryExercise(name: "Скручивания", category: .core, muscleGroup: .core),
        
        // КАРДИО
        LibraryExercise(name: "Берпи", category: .cardio, muscleGroup: .fullBody),
        LibraryExercise(name: "Махи гирей", category: .cardio, muscleGroup: .fullBody),
        LibraryExercise(name: "Запрыгивания на тумбу", category: .cardio, muscleGroup: .fullBody),
        LibraryExercise(name: "Канаты", category: .cardio, muscleGroup: .fullBody),
        LibraryExercise(name: "Бег", category: .cardio, muscleGroup: .fullBody),
        LibraryExercise(name: "Эллипс", category: .cardio, muscleGroup: .fullBody),
        LibraryExercise(name: "Степпер", category: .cardio, muscleGroup: .fullBody),
        
        // КОМПЛЕКСНЫЕ
        LibraryExercise(name: "Взятие на грудь", category: .complex, muscleGroup: .fullBody),
        LibraryExercise(name: "Швунг жимовой", category: .complex, muscleGroup: .fullBody),
    ]
    
    /// Упражнения, сгруппированные по категориям
    static var exercisesByCategory: [ExerciseCategory: [LibraryExercise]] {
        Dictionary(grouping: allExercises, by: { $0.category })
    }
    
    /// Поиск упражнений по названию
    static func search(_ query: String) -> [LibraryExercise] {
        guard !query.isEmpty else { return allExercises }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
