//
//  ProgramSeeder.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import Foundation
import SwiftData

/// Утилита для создания предустановленных программ тренировок
struct ProgramSeeder {
    
    // MARK: - Main Seed Function
    
    /// Генерирует все 15 предустановленных программ
    static func generateDefaultPrograms(context: ModelContext) -> [Program] {
        var allPrograms: [Program] = []
        
        // Category I: Full Body
        allPrograms.append(createFundamental2Day())
        allPrograms.append(createHighFrequency3Day())
        allPrograms.append(createAdvancedDUP4Day())
        
        // Category II: Split
        allPrograms.append(createAestheticsBalance())
        allPrograms.append(createVolumeSplit())
        allPrograms.append(createPreExhaustion())
        
        // Category III: Fat Loss / Circuit
        allPrograms.append(createBearComplex())
        allPrograms.append(createEDT())
        allPrograms.append(createPHA())
        
        // Category IV: Strength
        allPrograms.append(create531Beginner())
        allPrograms.append(createGZCLP())
        allPrograms.append(createUpperLowerStrength())
        
        // Category V: Cardio
        allPrograms.append(createHIITPyramid())
        allPrograms.append(createStairmasterGlutes())
        allPrograms.append(createLISSElliptical())
        
        // Insert all programs into context
        for program in allPrograms {
            context.insert(program)
        }
        
        return allPrograms
    }
    
    /// Проверяет и создает программы, если их еще нет
    static func seedProgramsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Program>()
        
        do {
            let existingPrograms = try context.fetch(descriptor)
            
            // Если уже есть программы, не создаем новые
            guard existingPrograms.isEmpty else {
                print("Programs already exist, skipping seed")
                return
            }
            
            print("Seeding default programs...")
            let programs = generateDefaultPrograms(context: context)
            try context.save()
            print("Successfully seeded \\(programs.count) programs")
        } catch {
            print("Failed to seed programs: \\(error)")
        }
    }
    
    // MARK: - Category I: Full Body
    
    private static func createFundamental2Day() -> Program {
        let program = Program(
            name: "Фундаментальная (2 дня)",
            desc: "Базовая программа full body для начинающих. Две тренировки в неделю с акцентом на основные движения."
        )
        
        // День A
        let dayA = WorkoutDay(name: "День A", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayA, name: "Приседания со штангой", sets: 3, order: 0)
        addExercise(to: dayA, name: "Жим штанги лежа", sets: 3, order: 1)
        addExercise(to: dayA, name: "Тяга верхнего блока", sets: 3, order: 2)
        dayA.program = program
        program.days.append(dayA)
        
        // День B
        let dayB = WorkoutDay(name: "День B", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayB, name: "Румынская тяга", sets: 3, order: 0)
        addExercise(to: dayB, name: "Жим на наклонной скамье", sets: 3, order: 1)
        addExercise(to: dayB, name: "Тяга штанги в наклоне", sets: 3, order: 2)
        dayB.program = program
        program.days.append(dayB)
        
        return program
    }
    
    private static func createHighFrequency3Day() -> Program {
        let program = Program(
            name: "Высокочастотная (3 дня)",
            desc: "Тренировка всего тела 3 раза в неделю с волновой периодизацией."
        )
        
        // День 1: Тяжелый
        let day1 = WorkoutDay(name: "День 1 - Тяжелый", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Приседания со штангой", sets: 4, order: 0)
        addExercise(to: day1, name: "Жим штанги лежа", sets: 4, order: 1)
        addExercise(to: day1, name: "Тяга штанги в наклоне", sets: 4, order: 2)
        day1.program = program
        program.days.append(day1)
        
        // День 2: Средний
        let day2 = WorkoutDay(name: "День 2 - Средний", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Жим ногами", sets: 3, order: 0)
        addExercise(to: day2, name: "Жим гантелей лежа", sets: 3, order: 1)
        addExercise(to: day2, name: "Подтягивания", sets: 3, order: 2)
        day2.program = program
        program.days.append(day2)
        
        // День 3: Легкий
        let day3 = WorkoutDay(name: "День 3 - Легкий", orderIndex: 2, workoutType: .strength)
        addExercise(to: day3, name: "Кубковые приседания", sets: 3, order: 0)
        addExercise(to: day3, name: "Отжимания на брусьях", sets: 3, order: 1)
        addExercise(to: day3, name: "Тяга верхнего блока", sets: 3, order: 2)
        day3.program = program
        program.days.append(day3)
        
        return program
    }
    
    private static func createAdvancedDUP4Day() -> Program {
        let program = Program(
            name: "Продвинутый DUP (4 дня)",
            desc: "Волновая периодизация с чередованием силовых и объемных дней."
        )
        
        let day1 = WorkoutDay(name: "Сила - Низ", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Приседания со штангой", sets: 5, order: 0)
        addExercise(to: day1, name: "Румынская тяга", sets: 4, order: 1)
        day1.program = program
        program.days.append(day1)
        
        let day2 = WorkoutDay(name: "Сила - Верх", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Жим штанги лежа", sets: 5, order: 0)
        addExercise(to: day2, name: "Тяга штанги в наклоне", sets: 4, order: 1)
        day2.program = program
        program.days.append(day2)
        
        let day3 = WorkoutDay(name: "Объем - Низ", orderIndex: 2, workoutType: .strength)
        addExercise(to: day3, name: "Жим ногами", sets: 4, order: 0)
        addExercise(to: day3, name: "Болгарские выпады", sets: 3, order: 1)
        addExercise(to: day3, name: "Ягодичный мост со штангой", sets: 3, order: 2)
        day3.program = program
        program.days.append(day3)
        
        let day4 = WorkoutDay(name: "Объем - Верх", orderIndex: 3, workoutType: .strength)
        addExercise(to: day4, name: "Жим на наклонной скамье", sets: 4, order: 0)
        addExercise(to: day4, name: "Подтягивания", sets: 4, order: 1)
        addExercise(to: day4, name: "Жим гантелей сидя", sets: 3, order: 2)
        day4.program = program
        program.days.append(day4)
        
        return program
    }
    
    // MARK: - Category II: Split
    
    private static func createAestheticsBalance() -> Program {
        let program = Program(
            name: "Эстетика и Баланс",
            desc: "Сплит верх/низ с акцентом на пропорции и эстетику."
        )
        
        let day1 = WorkoutDay(name: "Верх A", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Жим штанги лежа", sets: 4, order: 0)
        addExercise(to: day1, name: "Тяга штанги в наклоне", sets: 4, order: 1)
        addExercise(to: day1, name: "Жим гантелей сидя", sets: 3, order: 2)
        addExercise(to: day1, name: "Лицевая тяга", sets: 3, order: 3)
        day1.program = program
        program.days.append(day1)
        
        let day2 = WorkoutDay(name: "Низ A", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Приседания со штангой", sets: 4, order: 0)
        addExercise(to: day2, name: "Румынская тяга", sets: 3, order: 1)
        addExercise(to: day2, name: "Ягодичный мост со штангой", sets: 3, order: 2)
        day2.program = program
        program.days.append(day2)
        
        let day3 = WorkoutDay(name: "Верх B", orderIndex: 2, workoutType: .strength)
        addExercise(to: day3, name: "Жим на наклонной скамье", sets: 4, order: 0)
        addExercise(to: day3, name: "Подтягивания", sets: 4, order: 1)
        addExercise(to: day3, name: "Махи гантелями в стороны", sets: 3, order: 2)
        day3.program = program
        program.days.append(day3)
        
        let day4 = WorkoutDay(name: "Низ B", orderIndex: 3, workoutType: .strength)
        addExercise(to: day4, name: "Жим ногами", sets: 4, order: 0)
        addExercise(to: day4, name: "Болгарские выпады", sets: 3, order: 1)
        addExercise(to: day4, name: "Сгибания ног лежа", sets: 3, order: 2)
        day4.program = program
        program.days.append(day4)
        
        return program
    }
    
    private static func createVolumeSplit() -> Program {
        let program = Program(
            name: "Объемный Сплит",
            desc: "Высокообъемная программа с акцентом на плечи и руки."
        )
        
        let day1 = WorkoutDay(name: "Грудь + Трицепс", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Жим штанги лежа", sets: 4, order: 0)
        addExercise(to: day1, name: "Жим на наклонной скамье", sets: 3, order: 1)
        addExercise(to: day1, name: "Разводка гантелей", sets: 3, order: 2)
        addExercise(to: day1, name: "Французский жим", sets: 3, order: 3)
        addExercise(to: day1, name: "Разгибания на блоке", sets: 3, order: 4)
        day1.program = program
        program.days.append(day1)
        
        let day2 = WorkoutDay(name: "Спина + Бицепс", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Подтягивания", sets: 4, order: 0)
        addExercise(to: day2, name: "Тяга штанги в наклоне", sets: 4, order: 1)
        addExercise(to: day2, name: "Тяга верхнего блока", sets: 3, order: 2)
        addExercise(to: day2, name: "Подъем штанги на бицепс", sets: 3, order: 3)
        addExercise(to: day2, name: "Молотковые сгибания", sets: 3, order: 4)
        day2.program = program
        program.days.append(day2)
        
        let day3 = WorkoutDay(name: "Ноги", orderIndex: 2, workoutType: .strength)
        addExercise(to: day3, name: "Приседания со штангой", sets: 4, order: 0)
        addExercise(to: day3, name: "Румынская тяга", sets: 4, order: 1)
        addExercise(to: day3, name: "Жим ногами", sets: 3, order: 2)
        addExercise(to: day3, name: "Подъемы на носки стоя", sets: 4, order: 3)
        day3.program = program
        program.days.append(day3)
        
        let day4 = WorkoutDay(name: "Плечи + Руки", orderIndex: 3, workoutType: .strength)
        addExercise(to: day4, name: "Жим штанги стоя", sets: 4, order: 0)
        addExercise(to: day4, name: "Махи гантелями в стороны", sets: 4, order: 1)
        addExercise(to: day4, name: "Махи в наклоне", sets: 3, order: 2)
        addExercise(to: day4, name: "Сгибание на блоке спиной", sets: 3, order: 3)
        addExercise(to: day4, name: "Разгибание на канате над головой", sets: 3, order: 4)
        day4.program = program
        program.days.append(day4)
        
        return program
    }
    
    private static func createPreExhaustion() -> Program {
        let program = Program(
            name: "Pre-Exhaustion",
            desc: "Изоляция перед базовыми упражнениями для усиленной активации целевых мышц."
        )
        
        let day1 = WorkoutDay(name: "Грудь", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Разводка гантелей", sets: 3, order: 0)
        addExercise(to: day1, name: "Жим штанги лежа", sets: 4, order: 1)
        addExercise(to: day1, name: "Жим на наклонной скамье", sets: 3, order: 2)
        day1.program = program
        program.days.append(day1)
        
        let day2 = WorkoutDay(name: "Спина", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Тяга верхнего блока", sets: 3, order: 0)
        addExercise(to: day2, name: "Подтягивания", sets: 4, order: 1)
        addExercise(to: day2, name: "Тяга штанги в наклоне", sets: 4, order: 2)
        day2.program = program
        program.days.append(day2)
        
        let day3 = WorkoutDay(name: "Ноги", orderIndex: 2, workoutType: .strength)
        addExercise(to: day3, name: "Выпады с гантелями", sets: 3, order: 0)
        addExercise(to: day3, name: "Приседания со штангой", sets: 4, order: 1)
        addExercise(to: day3, name: "Румынская тяга", sets: 4, order: 2)
        day3.program = program
        program.days.append(day3)
        
        let day4 = WorkoutDay(name: "Плечи", orderIndex: 3, workoutType: .strength)
        addExercise(to: day4, name: "Махи гантелями в стороны", sets: 3, order: 0)
        addExercise(to: day4, name: "Жим штанги стоя", sets: 4, order: 1)
        addExercise(to: day4, name: "Лицевая тяга", sets: 3, order: 2)
        day4.program = program
        program.days.append(day4)
        
        return program
    }
    
    // MARK: - Category III: Fat Loss / Circuit
    
    private static func createBearComplex() -> Program {
        let program = Program(
            name: "Комплекс Медведь (The Bear)",
            desc: "Классический барбелл комплекс: взятие, присед, жим, присед, жим."
        )
        
        let day1 = WorkoutDay(name: "Раунд 1", orderIndex: 0, workoutType: .circuit)
        addExercise(to: day1, name: "Взятие на грудь", sets: 5, order: 0)
        addExercise(to: day1, name: "Приседания со штангой", sets: 5, order: 1)
        addExercise(to: day1, name: "Швунг жимовой", sets: 5, order: 2)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    private static func createEDT() -> Program {
        let program = Program(
            name: "EDT (Плотность)",
            desc: "Escalating Density Training - суперсеты антагонистов на время."
        )
        
        let day1 = WorkoutDay(name: "Блок 1", orderIndex: 0, workoutType: .circuit)
        addExercise(to: day1, name: "Подтягивания", sets: 10, order: 0)
        addExercise(to: day1, name: "Отжимания на брусьях", sets: 10, order: 1)
        day1.program = program
        program.days.append(day1)
        
        let day2 = WorkoutDay(name: "Блок 2", orderIndex: 1, workoutType: .circuit)
        addExercise(to: day2, name: "Приседания со штангой", sets: 10, order: 0)
        addExercise(to: day2, name: "Румынская тяга", sets: 10, order: 1)
        day2.program = program
        program.days.append(day2)
        
        return program
    }
    
    private static func createPHA() -> Program {
        let program = Program(
            name: "PHA (Сердце)",
            desc: "Peripheral Heart Action - чередование верха и низа тела в круговом режиме."
        )
        
        let day1 = WorkoutDay(name: "Круг 1", orderIndex: 0, workoutType: .circuit)
        addExercise(to: day1, name: "Приседания со штангой", sets: 3, order: 0)
        addExercise(to: day1, name: "Жим штанги лежа", sets: 3, order: 1)
        addExercise(to: day1, name: "Румынская тяга", sets: 3, order: 2)
        addExercise(to: day1, name: "Тяга штанги в наклоне", sets: 3, order: 3)
        addExercise(to: day1, name: "Выпады с гантелями", sets: 3, order: 4)
        addExercise(to: day1, name: "Жим гантелей сидя", sets: 3, order: 5)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    // MARK: - Category IV: Strength
    
    private static func create531Beginner() -> Program {
        let program = Program(
            name: "5/3/1 для новичков",
            desc: "Классическая программа Wendler для развития силы в базовых движениях."
        )
        
        let day1 = WorkoutDay(name: "Присед + Жим", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Приседания со штангой", sets: 3, order: 0)
        addExercise(to: day1, name: "Жим штанги лежа", sets: 3, order: 1)
        addExercise(to: day1, name: "Тяга штанги в наклоне", sets: 3, order: 2)
        day1.program = program
        program.days.append(day1)
        
        let day2 = WorkoutDay(name: "Тяга + Жим стоя", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Румынская тяга", sets: 3, order: 0)
        addExercise(to: day2, name: "Жим штанги стоя", sets: 3, order: 1)
        addExercise(to: day2, name: "Подтягивания", sets: 3, order: 2)
        day2.program = program
        program.days.append(day2)
        
        return program
    }
    
    private static func createGZCLP() -> Program {
        let program = Program(
            name: "GZCLP Линейная",
            desc: "Система Tier 1-2-3: тяжелые базовые, средние вспомогательные, легкие изоляции."
        )
        
        let day1 = WorkoutDay(name: "День 1", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Приседания со штангой", sets: 5, order: 0) // T1
        addExercise(to: day1, name: "Жим штанги лежа", sets: 3, order: 1) // T2
        addExercise(to: day1, name: "Тяга верхнего блока", sets: 3, order: 2) // T3
        day1.program = program
        program.days.append(day1)
        
        let day2 = WorkoutDay(name: "День 2", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Жим штанги стоя", sets: 5, order: 0) // T1
        addExercise(to: day2, name: "Румынская тяга", sets: 3, order: 1) // T2
        addExercise(to: day2, name: "Разводка гантелей", sets: 3, order: 2) // T3
        day2.program = program
        program.days.append(day2)
        
        let day3 = WorkoutDay(name: "День 3", orderIndex: 2, workoutType: .strength)
        addExercise(to: day3, name: "Жим штанги лежа", sets: 5, order: 0) // T1
        addExercise(to: day3, name: "Приседания со штангой", sets: 3, order: 1) // T2
        addExercise(to: day3, name: "Махи гантелями в стороны", sets: 3, order: 2) // T3
        day3.program = program
        program.days.append(day3)
        
        let day4 = WorkoutDay(name: "День 4", orderIndex: 3, workoutType: .strength)
        addExercise(to: day4, name: "Румынская тяга", sets: 5, order: 0) // T1
        addExercise(to: day4, name: "Жим штанги стоя", sets: 3, order: 1) // T2
        addExercise(to: day4, name: "Подъем штанги на бицепс", sets: 3, order: 2) // T3
        day4.program = program
        program.days.append(day4)
        
        return program
    }
    
    private static func createUpperLowerStrength() -> Program {
        let program = Program(
            name: "Верх/Низ Силовой",
            desc: "Традиционный верх/низ с упором на тяжелые базовые упражнения."
        )
        
        let day1 = WorkoutDay(name: "Верх 1", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Жим штанги лежа", sets: 5, order: 0)
        addExercise(to: day1, name: "Тяга штанги в наклоне", sets: 5, order: 1)
        addExercise(to: day1, name: "Жим гантелей сидя", sets: 3, order: 2)
        day1.program = program
        program.days.append(day1)
        
        let day2 = WorkoutDay(name: "Низ 1", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Приседания со штангой", sets: 5, order: 0)
        addExercise(to: day2, name: "Румынская тяга", sets: 4, order: 1)
        addExercise(to: day2, name: "Подъемы на носки стоя", sets: 4, order: 2)
        day2.program = program
        program.days.append(day2)
        
        let day3 = WorkoutDay(name: "Верх 2", orderIndex: 2, workoutType: .strength)
        addExercise(to: day3, name: "Жим штанги стоя", sets: 5, order: 0)
        addExercise(to: day3, name: "Подтягивания", sets: 5, order: 1)
        addExercise(to: day3, name: "Отжимания на брусьях", sets: 3, order: 2)
        day3.program = program
        program.days.append(day3)
        
        let day4 = WorkoutDay(name: "Низ 2", orderIndex: 3, workoutType: .strength)
        addExercise(to: day4, name: "Жим ногами", sets: 4, order: 0)
        addExercise(to: day4, name: "Болгарские выпады", sets: 3, order: 1)
        addExercise(to: day4, name: "Сгибания ног лежа", sets: 3, order: 2)
        day4.program = program
        program.days.append(day4)
        
        return program
    }
    
    // MARK: - Category V: Cardio
    
    private static func createHIITPyramid() -> Program {
        let program = Program(
            name: "HIIT Пирамида",
            desc: "Высокоинтенсивные интервалы на беговой дорожке с пирамидальной схемой."
        )
        
        let day1 = WorkoutDay(name: "Пирамида", orderIndex: 0, workoutType: .cardio)
        addExercise(to: day1, name: "Бег", sets: 1, order: 0)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    private static func createStairmasterGlutes() -> Program {
        let program = Program(
            name: "Stairmaster Glutes",
            desc: "Степпер с акцентом на развитие ягодиц. Умеренная интенсивность, долгая длительность."
        )
        
        let day1 = WorkoutDay(name: "Ступени", orderIndex: 0, workoutType: .cardio)
        addExercise(to: day1, name: "Степпер", sets: 1, order: 0)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    private static func createLISSElliptical() -> Program {
        let program = Program(
            name: "LISS Эллипс",
            desc: "Низкоинтенсивное равномерное кардио для восстановления и жиросжигания."
        )
        
        let day1 = WorkoutDay(name: "Эллипс", orderIndex: 0, workoutType: .cardio)
        addExercise(to: day1, name: "Эллипс", sets: 1, order: 0)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    // MARK: - Helper
    
    private static func addExercise(to day: WorkoutDay, name: String, sets: Int, order: Int) {
        let exercise = ExerciseTemplate(name: name, plannedSets: sets, orderIndex: order)
        exercise.workoutDay = day
        day.exercises.append(exercise)
    }
}
