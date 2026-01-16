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
        
        // Category VI: Calisthenics
        allPrograms.append(createStreetWorkoutBeginner())
        allPrograms.append(createStreetWorkoutIntermediate())
        
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
            let existingNames = Set(existingPrograms.map { $0.name })
            
            // Список ожидаемых программ
            let expectedPrograms = [
                "Фулбади: Фундаментальная",
                "Высокочастотная Гипертрофия",
                "Продвинутый DUP",
                "Эстетика и Баланс",
                "Объемный Сплит",
                "Pre-Exhaustion",
                "Комплекс Медведь (The Bear)",
                "EDT Плотность",
                "PHA (Сердце)",
                "5/3/1 Новичок",
                "GZCLP Линейная",
                "Верх/Низ Силовой",
                "HIIT Пирамида",
                "Stairmaster Glutes",
                "LISS Эллипс",
                "Воркаут: Старт",
                "Воркаут: Прогресс"
            ]
            
            // Если все программы уже есть, не создаем новые
            let missingPrograms = expectedPrograms.filter { !existingNames.contains($0) }
            
            if missingPrograms.isEmpty {
                print("All programs already exist (\(existingPrograms.count) programs)")
                return
            }
            
            print("Seeding \(missingPrograms.count) missing programs...")
            let allPrograms = generateDefaultPrograms(context: context)
            
            // Вставляем только недостающие программы
            for program in allPrograms {
                if missingPrograms.contains(program.name) {
                    context.insert(program)
                }
            }
            
            try context.save()
            print("Successfully seeded programs. Total: \(try context.fetch(descriptor).count)")
        } catch {
            print("Failed to seed programs: \(error)")
        }
    }
    
    // MARK: - Category I: Full Body (Силовая)
    
    private static func createFundamental2Day() -> Program {
        let program = Program(
            name: "Фулбади: Фундаментальная",
            desc: "Базовая программа full body для начинающих. 2 тренировки в неделю с акцентом на основные движения."
        )
        
        // День A
        let dayA = WorkoutDay(name: "День A", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayA, name: "Приседания со штангой", sets: 3, order: 0)
        addExercise(to: dayA, name: "Жим штанги лежа", sets: 3, order: 1)
        addExercise(to: dayA, name: "Тяга горизонтального блока", sets: 3, order: 2)
        addExercise(to: dayA, name: "Жим гантелей стоя", sets: 3, order: 3)
        addExercise(to: dayA, name: "Сгибание ног лежа", sets: 3, order: 4)
        addExercise(to: dayA, name: "Лицевая тяга", sets: 3, order: 5)
        dayA.program = program
        program.days.append(dayA)
        
        // День B
        let dayB = WorkoutDay(name: "День B", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayB, name: "Румынская тяга", sets: 3, order: 0)
        addExercise(to: dayB, name: "Жим гантелей на наклонной", sets: 3, order: 1)
        addExercise(to: dayB, name: "Тяга верхнего блока", sets: 3, order: 2)
        addExercise(to: dayB, name: "Жим ногами", sets: 3, order: 3)
        addExercise(to: dayB, name: "Махи гантелями в стороны", sets: 3, order: 4)
        addExercise(to: dayB, name: "Ягодичный мост", sets: 3, order: 5)
        dayB.program = program
        program.days.append(dayB)
        
        return program
    }
    
    private static func createHighFrequency3Day() -> Program {
        let program = Program(
            name: "Высокочастотная Гипертрофия",
            desc: "Тренировка всего тела 3 раза в неделю. Высокая частота для максимальной гипертрофии."
        )
        
        // День A
        let dayA = WorkoutDay(name: "День A", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayA, name: "Фронтальные приседания", sets: 4, order: 0)
        addExercise(to: dayA, name: "Жим лежа (Силовой)", sets: 4, order: 1)
        addExercise(to: dayA, name: "Тяга штанги в наклоне", sets: 4, order: 2)
        addExercise(to: dayA, name: "Болгарские выпады", sets: 3, order: 3)
        addExercise(to: dayA, name: "Разгибание на трицепс", sets: 3, order: 4)
        dayA.program = program
        program.days.append(dayA)
        
        // День B
        let dayB = WorkoutDay(name: "День B", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayB, name: "Становая тяга", sets: 4, order: 0)
        addExercise(to: dayB, name: "Армейский жим", sets: 4, order: 1)
        addExercise(to: dayB, name: "Подтягивания", sets: 4, order: 2, type: .repsOnly)
        addExercise(to: dayB, name: "Сгибание ног сидя", sets: 3, order: 3)
        addExercise(to: dayB, name: "Bayesian Curl", sets: 3, order: 4)
        dayB.program = program
        program.days.append(dayB)
        
        return program
    }
    
    private static func createAdvancedDUP4Day() -> Program {
        let program = Program(
            name: "Продвинутый DUP",
            desc: "4 дня в неделю. Волновая периодизация: чередование силовых и объемных дней."
        )
        
        // День 1: Сила
        let day1 = WorkoutDay(name: "День 1 (Сила)", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Приседания Low bar", sets: 5, order: 0)
        addExercise(to: day1, name: "Жим лежа", sets: 5, order: 1)
        addExercise(to: day1, name: "Тяга Пендли", sets: 4, order: 2)
        addExercise(to: day1, name: "Прогулка фермера", sets: 3, order: 3)
        day1.program = program
        program.days.append(day1)
        
        // День 2: Гипертрофия
        let day2 = WorkoutDay(name: "День 2 (Гипертрофия)", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Жим ногами", sets: 4, order: 0)
        addExercise(to: day2, name: "Жим Арнольда", sets: 4, order: 1)
        addExercise(to: day2, name: "Тяга верхнего блока", sets: 4, order: 2)
        addExercise(to: day2, name: "Подъем на носки", sets: 3, order: 3)
        addExercise(to: day2, name: "Бицепс + Трицепс", sets: 3, order: 4)
        day2.program = program
        program.days.append(day2)
        
        // День 3: Сила Тяга
        let day3 = WorkoutDay(name: "День 3 (Сила Тяга)", orderIndex: 2, workoutType: .strength)
        addExercise(to: day3, name: "Становая тяга", sets: 5, order: 0)
        addExercise(to: day3, name: "Отжимания на брусьях", sets: 4, order: 1, type: .repsOnly)
        addExercise(to: day3, name: "Подтягивания с весом", sets: 4, order: 2, type: .repsOnly)
        day3.program = program
        program.days.append(day3)
        
        // День 4: Гипертрофия
        let day4 = WorkoutDay(name: "День 4 (Гипертрофия)", orderIndex: 3, workoutType: .strength)
        addExercise(to: day4, name: "Гоблет-приседания", sets: 4, order: 0)
        addExercise(to: day4, name: "Жим гантелей наклонный", sets: 4, order: 1)
        addExercise(to: day4, name: "Тяга Т-грифа", sets: 4, order: 2)
        addExercise(to: day4, name: "Махи на блоке", sets: 3, order: 3)
        day4.program = program
        program.days.append(day4)
        
        return program
    }
    
    // MARK: - Category II: Split (Силовая)
    
    private static func createAestheticsBalance() -> Program {
        let program = Program(
            name: "Эстетика и Баланс",
            desc: "2-дневный сплит. Фокус на гармоничное развитие всех мышечных групп."
        )
        
        // День A: Ноги + Плечи
        let dayA = WorkoutDay(name: "День A (Ноги+Плечи)", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayA, name: "Приседания", sets: 4, order: 0)
        addExercise(to: dayA, name: "Жим штанги стоя", sets: 4, order: 1)
        addExercise(to: dayA, name: "Румынская тяга гантели", sets: 3, order: 2)
        addExercise(to: dayA, name: "Махи сидя", sets: 3, order: 3)
        addExercise(to: dayA, name: "Разгибание ног", sets: 3, order: 4)
        addExercise(to: dayA, name: "Подъем ног в висе", sets: 3, order: 5)
        dayA.program = program
        program.days.append(dayA)
        
        // День B: Спина + Грудь
        let dayB = WorkoutDay(name: "День B (Спина+Грудь)", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayB, name: "Жим гантелей наклонный", sets: 4, order: 0)
        addExercise(to: dayB, name: "Тяга штанги в наклоне", sets: 4, order: 1)
        addExercise(to: dayB, name: "Жим лежа", sets: 4, order: 2)
        addExercise(to: dayB, name: "Подтягивания", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: dayB, name: "Пуловер", sets: 3, order: 4)
        addExercise(to: dayB, name: "Молотки на бицепс", sets: 3, order: 5)
        dayB.program = program
        program.days.append(dayB)
        
        return program
    }
    
    private static func createVolumeSplit() -> Program {
        let program = Program(
            name: "Объемный Сплит",
            desc: "Фокус на плечи и руки. Высокий объем работы."
        )
        
        // День A
        let dayA = WorkoutDay(name: "День A", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayA, name: "Жим ногами", sets: 4, order: 0)
        addExercise(to: dayA, name: "Выпады", sets: 4, order: 1)
        addExercise(to: dayA, name: "Жим Арнольда", sets: 4, order: 2)
        addExercise(to: dayA, name: "Тяга к подбородку", sets: 3, order: 3)
        addExercise(to: dayA, name: "Обратные разведения", sets: 3, order: 4)
        dayA.program = program
        program.days.append(dayA)
        
        // День B
        let dayB = WorkoutDay(name: "День B", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayB, name: "Отжимания на брусьях", sets: 4, order: 0, type: .repsOnly)
        addExercise(to: dayB, name: "Тяга блока узким хватом", sets: 4, order: 1)
        addExercise(to: dayB, name: "Тяга одной рукой", sets: 4, order: 2)
        addExercise(to: dayB, name: "Сведения (Flyes)", sets: 3, order: 3)
        addExercise(to: dayB, name: "Сгибание Паук", sets: 3, order: 4)
        addExercise(to: dayB, name: "Жим узким хватом", sets: 3, order: 5)
        dayB.program = program
        program.days.append(dayB)
        
        return program
    }
    
    private static func createPreExhaustion() -> Program {
        let program = Program(
            name: "Pre-Exhaustion",
            desc: "Изоляция перед базой. Предварительное утомление целевых мышц."
        )
        
        // День A
        let dayA = WorkoutDay(name: "День A", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayA, name: "Разгибание ног", sets: 3, order: 0)
        addExercise(to: dayA, name: "Гоблет присед", sets: 4, order: 1)
        addExercise(to: dayA, name: "Махи в стороны", sets: 3, order: 2)
        addExercise(to: dayA, name: "Жим Смита", sets: 4, order: 3)
        dayA.program = program
        program.days.append(dayA)
        
        // День B
        let dayB = WorkoutDay(name: "День B", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayB, name: "Пуловер", sets: 3, order: 0)
        addExercise(to: dayB, name: "Тяга верхнего блока", sets: 4, order: 1)
        addExercise(to: dayB, name: "Сведение рук", sets: 3, order: 2)
        addExercise(to: dayB, name: "Жим в Хаммере", sets: 4, order: 3)
        dayB.program = program
        program.days.append(dayB)
        
        return program
    }
    
    // MARK: - Category III: Circuit / Fat Loss (Круговая)
    
    private static func createBearComplex() -> Program {
        let program = Program(
            name: "Комплекс Медведь (The Bear)",
            desc: "Выполнить 7 циклов без отдыха = 1 раунд. Всего 3-5 раундов."
        )
        
        let day1 = WorkoutDay(name: "День 1", orderIndex: 0, workoutType: .duration)
        addExercise(to: day1, name: "Взятие на грудь", sets: 1, order: 0)
        addExercise(to: day1, name: "Фронтальный присед", sets: 1, order: 1)
        addExercise(to: day1, name: "Жим швунг", sets: 1, order: 2)
        addExercise(to: day1, name: "Присед на спине", sets: 1, order: 3)
        addExercise(to: day1, name: "Жим из-за головы", sets: 1, order: 4)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    private static func createEDT() -> Program {
        let program = Program(
            name: "EDT Плотность",
            desc: "Escalating Density Training. Два 15-минутных блока."
        )
        
        let day1 = WorkoutDay(name: "День 1", orderIndex: 0, workoutType: .duration)
        addExercise(to: day1, name: "Гоблет приседания", sets: 1, order: 0)
        addExercise(to: day1, name: "Отжимания", sets: 1, order: 1, type: .repsOnly)
        addExercise(to: day1, name: "Махи гирей", sets: 1, order: 2)
        addExercise(to: day1, name: "Тяга TRX/Блока", sets: 1, order: 3, type: .repsOnly)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    private static func createPHA() -> Program {
        let program = Program(
            name: "PHA (Сердце)",
            desc: "Peripheral Heart Action. Круговая без остановки для максимальной кардио-нагрузки."
        )
        
        let day1 = WorkoutDay(name: "Круговая", orderIndex: 0, workoutType: .duration)
        addExercise(to: day1, name: "Выпады назад", sets: 1, order: 0)
        addExercise(to: day1, name: "Жим гантелей стоя", sets: 1, order: 1)
        addExercise(to: day1, name: "Становая сумо", sets: 1, order: 2)
        addExercise(to: day1, name: "Отжимания", sets: 1, order: 3, type: .repsOnly)
        addExercise(to: day1, name: "Планка", sets: 1, order: 4, type: .duration)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    // MARK: - Category IV: Strength (Силовая)
    
    private static func create531Beginner() -> Program {
        let program = Program(
            name: "5/3/1 Новичок",
            desc: "Классическая программа Джима Вендлера для новичков. 2 дня в неделю."
        )
        
        // День A
        let dayA = WorkoutDay(name: "День A", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayA, name: "Приседания (5/3/1)", sets: 3, order: 0)
        addExercise(to: dayA, name: "Жим лежа (5/3/1)", sets: 3, order: 1)
        addExercise(to: dayA, name: "Подсобка (50 reps)", sets: 5, order: 2)
        dayA.program = program
        program.days.append(dayA)
        
        // День B
        let dayB = WorkoutDay(name: "День B", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayB, name: "Становая тяга (5/3/1)", sets: 3, order: 0)
        addExercise(to: dayB, name: "Армейский жим (5/3/1)", sets: 3, order: 1)
        addExercise(to: dayB, name: "Подсобка", sets: 5, order: 2)
        dayB.program = program
        program.days.append(dayB)
        
        return program
    }
    
    private static func createGZCLP() -> Program {
        let program = Program(
            name: "GZCLP Линейная",
            desc: "GZCL Linear Progression. Три уровня интенсивности: T1, T2, T3."
        )
        
        // День 1
        let day1 = WorkoutDay(name: "День 1", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Присед (Т1 5×3)", sets: 5, order: 0)
        addExercise(to: day1, name: "Жим лежа (Т2 3×10)", sets: 3, order: 1)
        addExercise(to: day1, name: "Тяга блока (Т3 3×15)", sets: 3, order: 2)
        day1.program = program
        program.days.append(day1)
        
        // День 2
        let day2 = WorkoutDay(name: "День 2", orderIndex: 1, workoutType: .strength)
        addExercise(to: day2, name: "Армейский жим (Т1)", sets: 5, order: 0)
        addExercise(to: day2, name: "Становая (Т2)", sets: 3, order: 1)
        addExercise(to: day2, name: "Разведения (Т3)", sets: 3, order: 2)
        day2.program = program
        program.days.append(day2)
        
        return program
    }
    
    private static func createUpperLowerStrength() -> Program {
        let program = Program(
            name: "Верх/Низ Силовой",
            desc: "Сплит верх/низ для максимальной силы. Тяжелые базовые движения."
        )
        
        // День Верх
        let dayUpper = WorkoutDay(name: "Day Upper", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayUpper, name: "Жим лежа", sets: 5, order: 0)
        addExercise(to: dayUpper, name: "Тяга в наклоне", sets: 5, order: 1)
        addExercise(to: dayUpper, name: "Жим стоя", sets: 4, order: 2)
        addExercise(to: dayUpper, name: "Подтягивания (Heavy)", sets: 4, order: 3, type: .repsOnly)
        dayUpper.program = program
        program.days.append(dayUpper)
        
        // День Низ
        let dayLower = WorkoutDay(name: "Day Lower", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayLower, name: "Приседания", sets: 5, order: 0)
        addExercise(to: dayLower, name: "Становая тяга", sets: 5, order: 1)
        addExercise(to: dayLower, name: "Ягодичный мост (Hip Thrust)", sets: 4, order: 2)
        dayLower.program = program
        program.days.append(dayLower)
        
        return program
    }
    
    // MARK: - Category V: Cardio (Кардио)
    
    private static func createHIITPyramid() -> Program {
        let program = Program(
            name: "HIIT Пирамида",
            desc: "Высокоинтенсивные интервалы на беговой дорожке. 30/30, 45/45, 60/60."
        )
        
        let day1 = WorkoutDay(name: "Workout", orderIndex: 0, workoutType: .duration)
        addExercise(to: day1, name: "Бег (Интервалы: 30/30, 45/45, 60/60)", sets: 1, order: 0)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    private static func createStairmasterGlutes() -> Program {
        let program = Program(
            name: "Stairmaster Glutes",
            desc: "Степпер для ягодиц. Шаг через ступеньку, перекрестный шаг. Не держаться за поручни!"
        )
        
        let day1 = WorkoutDay(name: "Workout", orderIndex: 0, workoutType: .duration)
        addExercise(to: day1, name: "Степпер (Шаг через ступеньку, Перекрестный шаг)", sets: 1, order: 0)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    private static func createLISSElliptical() -> Program {
        let program = Program(
            name: "LISS Эллипс",
            desc: "40-60 минут в зоне 2 пульса. Активно работать руками (push-pull)."
        )
        
        let day1 = WorkoutDay(name: "Workout", orderIndex: 0, workoutType: .duration)
        addExercise(to: day1, name: "Эллипс (40-60 мин, зона 2)", sets: 1, order: 0)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    // MARK: - Category VI: Calisthenics (Стрит Воркаут)
    
    private static func createStreetWorkoutBeginner() -> Program {
        let program = Program(
            name: "Воркаут: Старт",
            desc: "Программа для начинающих на турниках и брусьях. Базовые движения."
        )
        
        let day1 = WorkoutDay(name: "Фулбади Воркаут", orderIndex: 0, workoutType: .strength)
        addExercise(to: day1, name: "Подтягивания", sets: 3, order: 0, type: .repsOnly)
        addExercise(to: day1, name: "Отжимания на брусьях", sets: 3, order: 1, type: .repsOnly)
        addExercise(to: day1, name: "Австралийские подтягивания", sets: 3, order: 2, type: .repsOnly)
        addExercise(to: day1, name: "Отжимания", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: day1, name: "Приседания", sets: 4, order: 4, type: .repsOnly)
        addExercise(to: day1, name: "Подъем ног в висе", sets: 3, order: 5, type: .repsOnly)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    private static func createStreetWorkoutIntermediate() -> Program {
        let program = Program(
            name: "Воркаут: Прогресс",
            desc: "Продвинутая программа для уличной площадки. Изучение элементов."
        )
        
        // День А: Тяни (Pull)
        let dayA = WorkoutDay(name: "День A (Тяни)", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayA, name: "Выход силой на две руки", sets: 3, order: 0, type: .repsOnly)
        addExercise(to: dayA, name: "Подтягивания с весом", sets: 4, order: 1, type: .repsOnly)
        addExercise(to: dayA, name: "Подтягивания обратным хватом", sets: 3, order: 2, type: .repsOnly)
        addExercise(to: dayA, name: "Австралийские подтягивания", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: dayA, name: "Подъем ног к перекладине (Toes to Bar)", sets: 3, order: 4, type: .repsOnly)
        dayA.program = program
        program.days.append(dayA)
        
        // День B: Толкай + Ноги (Push + Legs)
        let dayB = WorkoutDay(name: "День B (Толкай+Ноги)", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayB, name: "Отжимания на брусьях (с весом)", sets: 4, order: 0, type: .repsOnly)
        addExercise(to: dayB, name: "Отжимания от перекладины", sets: 3, order: 1, type: .repsOnly)
        addExercise(to: dayB, name: "Приседания Пистолетик", sets: 3, order: 2, type: .repsOnly)
        addExercise(to: dayB, name: "Выпады", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: dayB, name: "Уголок (L-sit) на брусьях", sets: 3, order: 4, type: .repsOnly)
        dayB.program = program
        program.days.append(dayB)
        
        return program
    }

    // MARK: - Helper
    
    private static func addExercise(to day: WorkoutDay, name: String, sets: Int, order: Int, type: WorkoutType? = nil) {
        let exercise = ExerciseTemplate(name: name, plannedSets: sets, orderIndex: order, type: type)
        day.exercises.append(exercise)
    }
}
