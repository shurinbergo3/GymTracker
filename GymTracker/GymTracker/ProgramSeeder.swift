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
    
    /// Генерирует и обновляет список программ
    nonisolated static func generateDefaultPrograms(context: ModelContext) -> [Program] {
        var allPrograms: [Program] = []
        var order = 1

        func add(_ program: Program) {
            program.displayOrder = order
            allPrograms.append(program)
            order += 1
        }

        // 1. Beginner-friendly Full Body
        add(createFundamental2Day())
        add(createHighFrequency3Day())
        add(createStrongLifts5x5())

        // 2. Mass / Hypertrophy splits
        add(createPushPullLegs())
        add(createUpperLowerHypertrophy())
        add(createBroSplit())
        add(createUpperLowerStrength())
        add(createAestheticsBalance())
        add(createArnoldSplit())
        add(createPowerbuilding4Day())

        // 3. Strength
        add(create531Beginner())
        add(createGZCLP())
        add(createMadcow5x5())
        add(createNSuns531LP())

        // 4. Cardio / Conditioning / Fat Loss
        add(createHIITPyramid())
        add(createTabataTotalBody())
        add(createEMOMConditioning())
        add(createNorwegian4x4())
        add(createCouchTo5K())
        add(createLISSElliptical())

        // 5. Specials
        add(createGluteBuilder())
        add(createBootyBuilderPro())
        add(createCoreCrusher())
        add(createMobilityFlow())
        add(createYogaFlowRecovery())

        // 6. Calisthenics
        add(createStreetWorkoutBeginner())
        add(createStreetWorkoutIntermediate())

        // 7. Hybrid & Volume (popular modern programs)
        add(createGermanVolumeTraining())
        add(createHybridAthlete())

        return allPrograms
    }
    
    /// Проверяет и создает программы, удаляет устаревшие
    nonisolated static func seedProgramsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Program>()

        // MIGRATION v3: Удаляем все программы и пере-сидим, чтобы убрать дубликаты,
        // которые накопились из-за разных стор-имён (локализованных vs ключей),
        // приходящих из Firestore-restore.
        let migrationKey = "DidMigrateProgramsToKeys_v3"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            deleteAllPrograms(context: context)
            UserDefaults.standard.set(true, forKey: migrationKey)
            // Сбрасываем старый флаг чтобы не путаться при следующих миграциях
            UserDefaults.standard.set(true, forKey: "DidMigrateProgramsToKeys_v2")
            #if DEBUG
            print("🔄 Migration v3: Wiped all programs to dedupe localization-key collisions")
            #endif
        }

        // MIGRATION v4: Перегружаем seed после расширения списка популярных
        // программ (Upper/Lower Hypertrophy, Booty Builder, Couch to 5K и др.).
        // Стираем только не-user-modified, чтобы не уничтожать кастомизации.
        let migrationKeyV4 = "DidExpandPopularPrograms_v4"
        if !UserDefaults.standard.bool(forKey: migrationKeyV4) {
            let descriptorAll = FetchDescriptor<Program>()
            if let all = try? context.fetch(descriptorAll) {
                for prog in all where !prog.isUserModified {
                    context.delete(prog)
                }
                try? context.save()
            }
            UserDefaults.standard.set(true, forKey: migrationKeyV4)
            #if DEBUG
            print("🔄 Migration v4: Reseeded library to add new popular programs")
            #endif
        }

        // MIGRATION v5: добавлены German Volume Training и Hybrid Athlete.
        // Стираем только не-user-modified.
        let migrationKeyV5 = "DidExpandPopularPrograms_v5"
        if !UserDefaults.standard.bool(forKey: migrationKeyV5) {
            let descriptorAll = FetchDescriptor<Program>()
            if let all = try? context.fetch(descriptorAll) {
                for prog in all where !prog.isUserModified {
                    context.delete(prog)
                }
                try? context.save()
            }
            UserDefaults.standard.set(true, forKey: migrationKeyV5)
            #if DEBUG
            print("🔄 Migration v5: Reseeded library to add GVT and Hybrid Athlete")
            #endif
        }
        
        // Programs to REMOVE (Unpopular)
        let deprecatedPrograms = [
            "Продвинутый DUP",
            "Объемный Сплит",
            "Pre-Exhaustion",
            "Комплекс Медведь (The Bear)",
            "EDT Плотность",
            "PHA (Сердце)",
            "Stairmaster Glutes"
        ]
        
        do {
            let existingPrograms = try context.fetch(descriptor)
            
            // 0. Remove Duplicates — дедупим по ЛОКАЛИЗОВАННОМУ имени.
            // Раньше две программы с разными raw-именами ("GZCLP Linear Progression"
            // и "GZCLP Линейная прогрессия") обе локализовались в "GZCLP Линейная"
            // и обе оставались в списке. Теперь лишние удаляются.
            var seenLocalizedNames = Set<String>()
            var duplicatesToDelete: [Program] = []

            // Сортируем так, чтобы оставлять программы с активными статусом или
            // user-modified (приоритет) — остальные отбрасываются.
            let sorted = existingPrograms.sorted { lhs, rhs in
                if lhs.isActive != rhs.isActive { return lhs.isActive }
                if lhs.isUserModified != rhs.isUserModified { return lhs.isUserModified }
                return lhs.name < rhs.name
            }
            for prog in sorted {
                let key = prog.name.localized()
                if seenLocalizedNames.contains(key) {
                    duplicatesToDelete.append(prog)
                } else {
                    seenLocalizedNames.insert(key)
                }
            }
            
            // Delete all duplicates
            for prog in duplicatesToDelete {
                context.delete(prog)
            }
            
            if !duplicatesToDelete.isEmpty {
                try context.save()
            }
            
            // Refresh after dedup - get fresh list from DB
            let refreshedPrograms = try context.fetch(descriptor)
            
            // 1. Remove Deprecated
            var deprecatedToDelete: [Program] = []
            for prog in refreshedPrograms {
                if deprecatedPrograms.contains(prog.name) {
                    deprecatedToDelete.append(prog)
                }
            }
            
            for prog in deprecatedToDelete {
                context.delete(prog)
            }
            
            if !deprecatedToDelete.isEmpty {
                try context.save()
                #if DEBUG
                print("Deleted \(deprecatedToDelete.count) deprecated programs")
                #endif
            }
            
            // 2. Add Missing
            let programsToCreate = generateDefaultPrograms(context: context)
            
            // Refresh names again after deprecated removal
            let finalPrograms = try context.fetch(descriptor)
            let finalExistingNames = Set(finalPrograms.map { $0.name })
            
            for program in programsToCreate {
                if !finalExistingNames.contains(program.name) {
                    context.insert(program)
                } else {
                    // Update order of existing ONLY if NOT user-modified
                    if let existing = finalPrograms.first(where: { $0.name == program.name }),
                       !existing.isUserModified {
                        existing.displayOrder = program.displayOrder
                    }
                }
            }
            
            try context.save()
            #if DEBUG
            print("Successfully updated programs library.")
            #endif
        } catch {
            #if DEBUG
            print("Failed to seed programs: \(error)")
            #endif
        }
    }
    
    /// Удаляет ВСЕ программы (для миграции)
    nonisolated static func deleteAllPrograms(context: ModelContext) {
        let descriptor = FetchDescriptor<Program>()
        if let allPrograms = try? context.fetch(descriptor) {
            for program in allPrograms {
                context.delete(program)
            }
            try? context.save()
            #if DEBUG
            print("Deleted all \(allPrograms.count) programs for migration")
            #endif
        }
    }
    
    // MARK: - Category I: Full Body (Силовая)
    
    private nonisolated static func createFundamental2Day() -> Program {
        let program = Program(
            name: "Full Body: Fundamental",
            desc: "Basic full body program for beginners. 2 workouts per week focusing on fundamental movements."
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
    
    private nonisolated static func createHighFrequency3Day() -> Program {
        let program = Program(
            name: "High Frequency Full Body",
            desc: "Full body workout 3 times per week. High frequency for maximum hypertrophy."
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
        addExercise(to: dayB, name: "Байезианские сгибания", sets: 3, order: 4)
        dayB.program = program
        program.days.append(dayB)
        
        return program
    }
    
    private nonisolated static func createAdvancedDUP4Day() -> Program {
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
    
    private nonisolated static func createAestheticsBalance() -> Program {
        let program = Program(
            name: "Aesthetics & Balance",
            desc: "2-day split. Focus on balanced development of all muscle groups."
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
    
    private nonisolated static func createVolumeSplit() -> Program {
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
    
    private nonisolated static func createPreExhaustion() -> Program {
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
    
    private nonisolated static func createBearComplex() -> Program {
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
    
    private nonisolated static func createEDT() -> Program {
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
    
    private nonisolated static func createPHA() -> Program {
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
    
    private nonisolated static func create531Beginner() -> Program {
        let program = Program(
            name: "5/3/1 for Beginners",
            desc: "Classic Jim Wendler program for beginners. 2 days per week."
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
    
    private nonisolated static func createGZCLP() -> Program {
        let program = Program(
            name: "GZCLP Linear Progression",
            desc: "GZCL Linear Progression. Three intensity tiers: T1, T2, T3."
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
    
    private nonisolated static func createUpperLowerStrength() -> Program {
        let program = Program(
            name: "Upper/Lower Strength",
            desc: "Upper/lower split for maximum strength. Heavy compound movements."
        )
        // День Верх
        let dayUpper = WorkoutDay(name: "День Верх", orderIndex: 0, workoutType: .strength)
        addExercise(to: dayUpper, name: "Жим лежа", sets: 5, order: 0)
        addExercise(to: dayUpper, name: "Тяга штанги в наклоне", sets: 5, order: 1)
        addExercise(to: dayUpper, name: "Жим стоя", sets: 4, order: 2)
        addExercise(to: dayUpper, name: "Подтягивания (Heavy)", sets: 4, order: 3, type: .repsOnly)
        dayUpper.program = program
        program.days.append(dayUpper)
        
        // День Низ
        let dayLower = WorkoutDay(name: "День Низ", orderIndex: 1, workoutType: .strength)
        addExercise(to: dayLower, name: "Приседания", sets: 5, order: 0)
        addExercise(to: dayLower, name: "Становая тяга", sets: 5, order: 1)
        addExercise(to: dayLower, name: "Ягодичный мост (Hip Thrust)", sets: 4, order: 2)
        dayLower.program = program
        program.days.append(dayLower)
        
        return program
    }
    
    // MARK: - Category V: Cardio (Кардио)
    
    private nonisolated static func createHIITPyramid() -> Program {
        let program = Program(
            name: "HIIT Pyramid",
            desc: "High-intensity intervals on treadmill. 30/30, 45/45, 60/60."
        )
        
        let day1 = WorkoutDay(name: "Workout", orderIndex: 0, workoutType: .duration)
        addExercise(to: day1, name: "Бег (Интервалы: 30/30, 45/45, 60/60)", sets: 1, order: 0)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    private nonisolated static func createStairmasterGlutes() -> Program {
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
    
    private nonisolated static func createLISSElliptical() -> Program {
        let program = Program(
            name: "LISS Elliptical",
            desc: "40-60 minutes in heart rate zone 2. Actively engage arms (push-pull)."
        )
        
        let day1 = WorkoutDay(name: "Workout", orderIndex: 0, workoutType: .duration)
        addExercise(to: day1, name: "Эллипс (40-60 мин, зона 2)", sets: 1, order: 0)
        day1.program = program
        program.days.append(day1)
        
        return program
    }
    
    // MARK: - Category VI: Calisthenics (Стрит Воркаут)
    
    private nonisolated static func createStreetWorkoutBeginner() -> Program {
        let program = Program(
            name: "Street Workout: Beginner",
            desc: "Beginner program for pull-up bars and parallel bars. Basic movements."
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
    
    private nonisolated static func createStreetWorkoutIntermediate() -> Program {
        let program = Program(
            name: "Street Workout: Intermediate",
            desc: "Advanced program for outdoor training. Learning skills and elements."
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

    // MARK: - Category VI.5: Modern Upper/Lower Hypertrophy

    private nonisolated static func createUpperLowerHypertrophy() -> Program {
        let program = Program(
            name: "Upper/Lower Hypertrophy",
            desc: "2-day hypertrophy split. Day 1 — back, chest, biceps, triceps. Day 2 — legs and shoulders. Beginner-friendly volume."
        )

        // День Верх: Спина + Грудь + Бицепс + Трицепс
        let dayUpper = WorkoutDay(name: "Верх (Спина+Грудь+Руки)", orderIndex: 0, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: dayUpper, name: "Жим штанги лежа", sets: 4, order: 0)
        addExercise(to: dayUpper, name: "Тяга штанги в наклоне", sets: 4, order: 1)
        addExercise(to: dayUpper, name: "Жим гантелей на наклонной", sets: 3, order: 2)
        addExercise(to: dayUpper, name: "Подтягивания", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: dayUpper, name: "Тяга горизонтального блока", sets: 3, order: 4)
        addExercise(to: dayUpper, name: "Подъем штанги на бицепс", sets: 3, order: 5)
        addExercise(to: dayUpper, name: "Французский жим", sets: 3, order: 6)
        dayUpper.program = program
        program.days.append(dayUpper)

        // День Низ + Плечи
        let dayLower = WorkoutDay(name: "Низ + Плечи", orderIndex: 1, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: dayLower, name: "Приседания со штангой", sets: 4, order: 0)
        addExercise(to: dayLower, name: "Румынская тяга", sets: 4, order: 1)
        addExercise(to: dayLower, name: "Жим ногами", sets: 3, order: 2)
        addExercise(to: dayLower, name: "Армейский жим", sets: 4, order: 3)
        addExercise(to: dayLower, name: "Махи гантелями в стороны", sets: 4, order: 4)
        addExercise(to: dayLower, name: "Подъем на носки", sets: 4, order: 5)
        addExercise(to: dayLower, name: "Подъем ног в висе", sets: 3, order: 6, type: .repsOnly)
        dayLower.program = program
        program.days.append(dayLower)

        return program
    }

    // MARK: - Category VII: Modern Hypertrophy Splits

    private nonisolated static func createPushPullLegs() -> Program {
        let program = Program(
            name: "Push Pull Legs (PPL)",
            desc: "Classic 6-day split: push, pull, legs — twice a week. The most popular intermediate program."
        )

        let push1 = WorkoutDay(name: "Push (Грудь+Плечи+Трицепс)", orderIndex: 0, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: push1, name: "Жим штанги лежа", sets: 4, order: 0)
        addExercise(to: push1, name: "Жим гантелей на наклонной", sets: 3, order: 1)
        addExercise(to: push1, name: "Армейский жим", sets: 3, order: 2)
        addExercise(to: push1, name: "Махи гантелями в стороны", sets: 3, order: 3)
        addExercise(to: push1, name: "Разгибание на трицепс на блоке", sets: 3, order: 4)
        addExercise(to: push1, name: "Французский жим", sets: 3, order: 5)
        push1.program = program
        program.days.append(push1)

        let pull1 = WorkoutDay(name: "Pull (Спина+Бицепс)", orderIndex: 1, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: pull1, name: "Подтягивания", sets: 4, order: 0, type: .repsOnly)
        addExercise(to: pull1, name: "Тяга штанги в наклоне", sets: 4, order: 1)
        addExercise(to: pull1, name: "Тяга верхнего блока", sets: 3, order: 2)
        addExercise(to: pull1, name: "Тяга горизонтального блока", sets: 3, order: 3)
        addExercise(to: pull1, name: "Подъем штанги на бицепс", sets: 3, order: 4)
        addExercise(to: pull1, name: "Молотки на бицепс", sets: 3, order: 5)
        pull1.program = program
        program.days.append(pull1)

        let legs1 = WorkoutDay(name: "Legs (Ноги+Пресс)", orderIndex: 2, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: legs1, name: "Приседания со штангой", sets: 4, order: 0)
        addExercise(to: legs1, name: "Румынская тяга", sets: 4, order: 1)
        addExercise(to: legs1, name: "Жим ногами", sets: 3, order: 2)
        addExercise(to: legs1, name: "Сгибание ног лежа", sets: 3, order: 3)
        addExercise(to: legs1, name: "Подъем на носки", sets: 4, order: 4)
        addExercise(to: legs1, name: "Подъем ног в висе", sets: 3, order: 5, type: .repsOnly)
        legs1.program = program
        program.days.append(legs1)

        let push2 = WorkoutDay(name: "Push (вариация)", orderIndex: 3, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: push2, name: "Жим гантелей лежа", sets: 4, order: 0)
        addExercise(to: push2, name: "Жим лежа на наклонной", sets: 3, order: 1)
        addExercise(to: push2, name: "Жим Арнольда", sets: 3, order: 2)
        addExercise(to: push2, name: "Махи на блоке", sets: 3, order: 3)
        addExercise(to: push2, name: "Отжимания на брусьях", sets: 3, order: 4, type: .repsOnly)
        addExercise(to: push2, name: "Разгибание над головой", sets: 3, order: 5)
        push2.program = program
        program.days.append(push2)

        let pull2 = WorkoutDay(name: "Pull (вариация)", orderIndex: 4, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: pull2, name: "Становая тяга", sets: 4, order: 0)
        addExercise(to: pull2, name: "Тяга Т-грифа", sets: 3, order: 1)
        addExercise(to: pull2, name: "Тяга одной рукой", sets: 3, order: 2)
        addExercise(to: pull2, name: "Лицевая тяга", sets: 3, order: 3)
        addExercise(to: pull2, name: "Сгибание Паук", sets: 3, order: 4)
        addExercise(to: pull2, name: "Подъем гантелей на бицепс", sets: 3, order: 5)
        pull2.program = program
        program.days.append(pull2)

        let legs2 = WorkoutDay(name: "Legs (вариация)", orderIndex: 5, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: legs2, name: "Фронтальные приседания", sets: 4, order: 0)
        addExercise(to: legs2, name: "Болгарские выпады", sets: 3, order: 1)
        addExercise(to: legs2, name: "Ягодичный мост", sets: 4, order: 2)
        addExercise(to: legs2, name: "Разгибание ног", sets: 3, order: 3)
        addExercise(to: legs2, name: "Сгибание ног сидя", sets: 3, order: 4)
        addExercise(to: legs2, name: "Подъем на носки сидя", sets: 4, order: 5)
        legs2.program = program
        program.days.append(legs2)

        return program
    }

    private nonisolated static func createBroSplit() -> Program {
        let program = Program(
            name: "Bro Split",
            desc: "Classic 5-day bodybuilder split: one muscle group per day. High volume per session."
        )

        let chest = WorkoutDay(name: "Грудь", orderIndex: 0, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: chest, name: "Жим штанги лежа", sets: 4, order: 0)
        addExercise(to: chest, name: "Жим гантелей на наклонной", sets: 4, order: 1)
        addExercise(to: chest, name: "Сведения (Flyes)", sets: 3, order: 2)
        addExercise(to: chest, name: "Отжимания на брусьях", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: chest, name: "Пуловер", sets: 3, order: 4)
        chest.program = program
        program.days.append(chest)

        let back = WorkoutDay(name: "Спина", orderIndex: 1, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: back, name: "Подтягивания", sets: 4, order: 0, type: .repsOnly)
        addExercise(to: back, name: "Тяга штанги в наклоне", sets: 4, order: 1)
        addExercise(to: back, name: "Тяга верхнего блока", sets: 3, order: 2)
        addExercise(to: back, name: "Тяга одной рукой", sets: 3, order: 3)
        addExercise(to: back, name: "Лицевая тяга", sets: 3, order: 4)
        back.program = program
        program.days.append(back)

        let legs = WorkoutDay(name: "Ноги", orderIndex: 2, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: legs, name: "Приседания со штангой", sets: 4, order: 0)
        addExercise(to: legs, name: "Жим ногами", sets: 4, order: 1)
        addExercise(to: legs, name: "Румынская тяга", sets: 3, order: 2)
        addExercise(to: legs, name: "Сгибание ног лежа", sets: 3, order: 3)
        addExercise(to: legs, name: "Подъем на носки", sets: 4, order: 4)
        legs.program = program
        program.days.append(legs)

        let shoulders = WorkoutDay(name: "Плечи", orderIndex: 3, workoutType: .strength, defaultRestTime: 75)
        addExercise(to: shoulders, name: "Армейский жим", sets: 4, order: 0)
        addExercise(to: shoulders, name: "Жим гантелей стоя", sets: 4, order: 1)
        addExercise(to: shoulders, name: "Махи гантелями в стороны", sets: 4, order: 2)
        addExercise(to: shoulders, name: "Тяга к подбородку", sets: 3, order: 3)
        addExercise(to: shoulders, name: "Обратные разведения", sets: 3, order: 4)
        shoulders.program = program
        program.days.append(shoulders)

        let arms = WorkoutDay(name: "Руки", orderIndex: 4, workoutType: .strength, defaultRestTime: 60)
        addExercise(to: arms, name: "Подъем штанги на бицепс", sets: 4, order: 0)
        addExercise(to: arms, name: "Молотки на бицепс", sets: 3, order: 1)
        addExercise(to: arms, name: "Жим узким хватом", sets: 4, order: 2)
        addExercise(to: arms, name: "Французский жим", sets: 3, order: 3)
        addExercise(to: arms, name: "Разгибание на трицепс на блоке", sets: 3, order: 4)
        arms.program = program
        program.days.append(arms)

        return program
    }

    private nonisolated static func createArnoldSplit() -> Program {
        let program = Program(
            name: "Arnold Split",
            desc: "Arnold Schwarzenegger's 6-day double split: push pairings hit each muscle 2x/week with high volume."
        )

        let cb1 = WorkoutDay(name: "Грудь+Спина", orderIndex: 0, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: cb1, name: "Жим штанги лежа", sets: 5, order: 0)
        addExercise(to: cb1, name: "Тяга штанги в наклоне", sets: 5, order: 1)
        addExercise(to: cb1, name: "Жим гантелей на наклонной", sets: 4, order: 2)
        addExercise(to: cb1, name: "Подтягивания", sets: 4, order: 3, type: .repsOnly)
        addExercise(to: cb1, name: "Сведения (Flyes)", sets: 3, order: 4)
        addExercise(to: cb1, name: "Пуловер", sets: 3, order: 5)
        cb1.program = program
        program.days.append(cb1)

        let sa1 = WorkoutDay(name: "Плечи+Руки", orderIndex: 1, workoutType: .strength, defaultRestTime: 75)
        addExercise(to: sa1, name: "Жим Арнольда", sets: 5, order: 0)
        addExercise(to: sa1, name: "Махи гантелями в стороны", sets: 4, order: 1)
        addExercise(to: sa1, name: "Тяга к подбородку", sets: 3, order: 2)
        addExercise(to: sa1, name: "Подъем штанги на бицепс", sets: 4, order: 3)
        addExercise(to: sa1, name: "Французский жим", sets: 4, order: 4)
        addExercise(to: sa1, name: "Молотки на бицепс", sets: 3, order: 5)
        sa1.program = program
        program.days.append(sa1)

        let legs = WorkoutDay(name: "Ноги", orderIndex: 2, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: legs, name: "Приседания со штангой", sets: 5, order: 0)
        addExercise(to: legs, name: "Выпады", sets: 4, order: 1)
        addExercise(to: legs, name: "Сгибание ног лежа", sets: 4, order: 2)
        addExercise(to: legs, name: "Разгибание ног", sets: 3, order: 3)
        addExercise(to: legs, name: "Подъем на носки", sets: 5, order: 4)
        legs.program = program
        program.days.append(legs)

        let cb2 = WorkoutDay(name: "Грудь+Спина (вариация)", orderIndex: 3, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: cb2, name: "Жим лежа на наклонной", sets: 4, order: 0)
        addExercise(to: cb2, name: "Тяга Т-грифа", sets: 4, order: 1)
        addExercise(to: cb2, name: "Жим гантелей лежа", sets: 4, order: 2)
        addExercise(to: cb2, name: "Тяга верхнего блока", sets: 4, order: 3)
        addExercise(to: cb2, name: "Сведение рук", sets: 3, order: 4)
        addExercise(to: cb2, name: "Тяга одной рукой", sets: 3, order: 5)
        cb2.program = program
        program.days.append(cb2)

        let sa2 = WorkoutDay(name: "Плечи+Руки (вариация)", orderIndex: 4, workoutType: .strength, defaultRestTime: 75)
        addExercise(to: sa2, name: "Армейский жим", sets: 4, order: 0)
        addExercise(to: sa2, name: "Махи на блоке", sets: 4, order: 1)
        addExercise(to: sa2, name: "Обратные разведения", sets: 3, order: 2)
        addExercise(to: sa2, name: "Подъем гантелей на бицепс", sets: 4, order: 3)
        addExercise(to: sa2, name: "Жим узким хватом", sets: 4, order: 4)
        addExercise(to: sa2, name: "Сгибание Паук", sets: 3, order: 5)
        sa2.program = program
        program.days.append(sa2)

        let legs2 = WorkoutDay(name: "Ноги (вариация)", orderIndex: 5, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: legs2, name: "Фронтальные приседания", sets: 4, order: 0)
        addExercise(to: legs2, name: "Болгарские выпады", sets: 4, order: 1)
        addExercise(to: legs2, name: "Румынская тяга", sets: 4, order: 2)
        addExercise(to: legs2, name: "Сгибание ног сидя", sets: 3, order: 3)
        addExercise(to: legs2, name: "Подъем на носки сидя", sets: 5, order: 4)
        legs2.program = program
        program.days.append(legs2)

        return program
    }

    private nonisolated static func createPowerbuilding4Day() -> Program {
        let program = Program(
            name: "Powerbuilding 4-Day",
            desc: "Power + bodybuilding hybrid. Heavy compound first, hypertrophy work second. 4 days/week."
        )

        let upperHeavy = WorkoutDay(name: "Верх (Тяжёлый)", orderIndex: 0, workoutType: .strength, defaultRestTime: 180)
        addExercise(to: upperHeavy, name: "Жим штанги лежа", sets: 5, order: 0)
        addExercise(to: upperHeavy, name: "Тяга штанги в наклоне", sets: 5, order: 1)
        addExercise(to: upperHeavy, name: "Жим гантелей на наклонной", sets: 3, order: 2)
        addExercise(to: upperHeavy, name: "Подтягивания с весом", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: upperHeavy, name: "Махи гантелями в стороны", sets: 3, order: 4)
        upperHeavy.program = program
        program.days.append(upperHeavy)

        let lowerHeavy = WorkoutDay(name: "Низ (Тяжёлый)", orderIndex: 1, workoutType: .strength, defaultRestTime: 180)
        addExercise(to: lowerHeavy, name: "Приседания со штангой", sets: 5, order: 0)
        addExercise(to: lowerHeavy, name: "Становая тяга", sets: 3, order: 1)
        addExercise(to: lowerHeavy, name: "Жим ногами", sets: 3, order: 2)
        addExercise(to: lowerHeavy, name: "Ягодичный мост", sets: 3, order: 3)
        addExercise(to: lowerHeavy, name: "Подъем на носки", sets: 4, order: 4)
        lowerHeavy.program = program
        program.days.append(lowerHeavy)

        let upperVol = WorkoutDay(name: "Верх (Объём)", orderIndex: 2, workoutType: .strength, defaultRestTime: 75)
        addExercise(to: upperVol, name: "Армейский жим", sets: 4, order: 0)
        addExercise(to: upperVol, name: "Тяга верхнего блока", sets: 4, order: 1)
        addExercise(to: upperVol, name: "Жим лежа на наклонной", sets: 3, order: 2)
        addExercise(to: upperVol, name: "Тяга Т-грифа", sets: 3, order: 3)
        addExercise(to: upperVol, name: "Подъем штанги на бицепс", sets: 3, order: 4)
        addExercise(to: upperVol, name: "Французский жим", sets: 3, order: 5)
        upperVol.program = program
        program.days.append(upperVol)

        let lowerVol = WorkoutDay(name: "Низ (Объём)", orderIndex: 3, workoutType: .strength, defaultRestTime: 75)
        addExercise(to: lowerVol, name: "Фронтальные приседания", sets: 4, order: 0)
        addExercise(to: lowerVol, name: "Румынская тяга", sets: 4, order: 1)
        addExercise(to: lowerVol, name: "Болгарские выпады", sets: 3, order: 2)
        addExercise(to: lowerVol, name: "Сгибание ног лежа", sets: 3, order: 3)
        addExercise(to: lowerVol, name: "Подъем на носки сидя", sets: 4, order: 4)
        lowerVol.program = program
        program.days.append(lowerVol)

        return program
    }

    // MARK: - Category VIII: Strength Classics

    private nonisolated static func createStrongLifts5x5() -> Program {
        let program = Program(
            name: "StrongLifts 5x5",
            desc: "Classic linear progression for beginners. 5 sets of 5 reps, 3 days a week. Two alternating workouts."
        )

        let dayA = WorkoutDay(name: "Workout A", orderIndex: 0, workoutType: .strength, defaultRestTime: 180)
        addExercise(to: dayA, name: "Приседания со штангой", sets: 5, order: 0)
        addExercise(to: dayA, name: "Жим штанги лежа", sets: 5, order: 1)
        addExercise(to: dayA, name: "Тяга штанги в наклоне", sets: 5, order: 2)
        dayA.program = program
        program.days.append(dayA)

        let dayB = WorkoutDay(name: "Workout B", orderIndex: 1, workoutType: .strength, defaultRestTime: 180)
        addExercise(to: dayB, name: "Приседания со штангой", sets: 5, order: 0)
        addExercise(to: dayB, name: "Армейский жим", sets: 5, order: 1)
        addExercise(to: dayB, name: "Становая тяга", sets: 1, order: 2)
        dayB.program = program
        program.days.append(dayB)

        return program
    }

    private nonisolated static func createMadcow5x5() -> Program {
        let program = Program(
            name: "Madcow 5x5",
            desc: "Intermediate 5x5 with weekly periodization. Heavy Mon, Light Wed, Volume Fri."
        )

        let mon = WorkoutDay(name: "Понедельник (Тяжёлый)", orderIndex: 0, workoutType: .strength, defaultRestTime: 180)
        addExercise(to: mon, name: "Приседания со штангой", sets: 5, order: 0)
        addExercise(to: mon, name: "Жим штанги лежа", sets: 5, order: 1)
        addExercise(to: mon, name: "Тяга штанги в наклоне", sets: 5, order: 2)
        mon.program = program
        program.days.append(mon)

        let wed = WorkoutDay(name: "Среда (Лёгкий)", orderIndex: 1, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: wed, name: "Приседания со штангой", sets: 4, order: 0)
        addExercise(to: wed, name: "Армейский жим", sets: 4, order: 1)
        addExercise(to: wed, name: "Становая тяга", sets: 4, order: 2)
        wed.program = program
        program.days.append(wed)

        let fri = WorkoutDay(name: "Пятница (Объём)", orderIndex: 2, workoutType: .strength, defaultRestTime: 180)
        addExercise(to: fri, name: "Приседания со штангой", sets: 4, order: 0)
        addExercise(to: fri, name: "Жим штанги лежа", sets: 4, order: 1)
        addExercise(to: fri, name: "Тяга штанги в наклоне", sets: 4, order: 2)
        addExercise(to: fri, name: "Жим лежа (1×3)", sets: 3, order: 3)
        fri.program = program
        program.days.append(fri)

        return program
    }

    private nonisolated static func createNSuns531LP() -> Program {
        let program = Program(
            name: "nSuns 5/3/1 LP",
            desc: "Aggressive 5/3/1 LP variant. 9 sets on the main lift with progressive intensity. 6 days/week."
        )

        let benchDay = WorkoutDay(name: "Жим / Армейский", orderIndex: 0, workoutType: .strength, defaultRestTime: 150)
        addExercise(to: benchDay, name: "Жим штанги лежа (T1: 8×5/3/1+)", sets: 8, order: 0)
        addExercise(to: benchDay, name: "Армейский жим (T2: 8×6)", sets: 8, order: 1)
        addExercise(to: benchDay, name: "Тяга верхнего блока", sets: 3, order: 2)
        addExercise(to: benchDay, name: "Махи гантелями в стороны", sets: 3, order: 3)
        benchDay.program = program
        program.days.append(benchDay)

        let squatDay = WorkoutDay(name: "Присед / Становая", orderIndex: 1, workoutType: .strength, defaultRestTime: 180)
        addExercise(to: squatDay, name: "Приседания (T1: 8×5/3/1+)", sets: 8, order: 0)
        addExercise(to: squatDay, name: "Становая тяга (T2: 8×6)", sets: 8, order: 1)
        addExercise(to: squatDay, name: "Сгибание ног лежа", sets: 3, order: 2)
        addExercise(to: squatDay, name: "Подъем на носки", sets: 3, order: 3)
        squatDay.program = program
        program.days.append(squatDay)

        let ohpDay = WorkoutDay(name: "Армейский / Жим", orderIndex: 2, workoutType: .strength, defaultRestTime: 150)
        addExercise(to: ohpDay, name: "Армейский жим (T1: 8×5/3/1+)", sets: 8, order: 0)
        addExercise(to: ohpDay, name: "Жим лежа (T2: 8×6)", sets: 8, order: 1)
        addExercise(to: ohpDay, name: "Подтягивания", sets: 3, order: 2, type: .repsOnly)
        addExercise(to: ohpDay, name: "Подъем штанги на бицепс", sets: 3, order: 3)
        ohpDay.program = program
        program.days.append(ohpDay)

        let dlDay = WorkoutDay(name: "Становая / Присед", orderIndex: 3, workoutType: .strength, defaultRestTime: 180)
        addExercise(to: dlDay, name: "Становая тяга (T1: 8×5/3/1+)", sets: 8, order: 0)
        addExercise(to: dlDay, name: "Фронтальные приседания (T2: 8×6)", sets: 8, order: 1)
        addExercise(to: dlDay, name: "Тяга штанги в наклоне", sets: 3, order: 2)
        addExercise(to: dlDay, name: "Подъем ног в висе", sets: 3, order: 3, type: .repsOnly)
        dlDay.program = program
        program.days.append(dlDay)

        return program
    }

    // MARK: - Category IX: Conditioning / Fat Loss

    private nonisolated static func createTabataTotalBody() -> Program {
        let program = Program(
            name: "Tabata Total Body",
            desc: "8 rounds × 20s work / 10s rest. 4 minutes of intense conditioning per block, 4-6 blocks total."
        )

        let day1 = WorkoutDay(name: "Tabata Block 1", orderIndex: 0, workoutType: .duration, defaultRestTime: 60, restTimerEnabled: true)
        addExercise(to: day1, name: "Burpees (Берпи)", sets: 8, order: 0, type: .duration)
        addExercise(to: day1, name: "Прыжки на скакалке", sets: 8, order: 1, type: .duration)
        addExercise(to: day1, name: "Приседания с прыжком", sets: 8, order: 2, type: .duration)
        addExercise(to: day1, name: "Mountain Climbers (Скалолаз)", sets: 8, order: 3, type: .duration)
        day1.program = program
        program.days.append(day1)

        let day2 = WorkoutDay(name: "Tabata Block 2", orderIndex: 1, workoutType: .duration, defaultRestTime: 60, restTimerEnabled: true)
        addExercise(to: day2, name: "Отжимания", sets: 8, order: 0, type: .duration)
        addExercise(to: day2, name: "Махи гирей", sets: 8, order: 1, type: .duration)
        addExercise(to: day2, name: "Приседания", sets: 8, order: 2, type: .duration)
        addExercise(to: day2, name: "Планка", sets: 8, order: 3, type: .duration)
        day2.program = program
        program.days.append(day2)

        return program
    }

    private nonisolated static func createEMOMConditioning() -> Program {
        let program = Program(
            name: "EMOM Conditioning",
            desc: "Every Minute On the Minute. Complete prescribed reps within 60 seconds, rest the remainder."
        )

        let day1 = WorkoutDay(name: "EMOM 20", orderIndex: 0, workoutType: .duration, defaultRestTime: 0)
        addExercise(to: day1, name: "Махи гирей (15 раз)", sets: 5, order: 0, type: .repsOnly)
        addExercise(to: day1, name: "Burpees (10 раз)", sets: 5, order: 1, type: .repsOnly)
        addExercise(to: day1, name: "Воздушные приседания (20 раз)", sets: 5, order: 2, type: .repsOnly)
        addExercise(to: day1, name: "Подъем ног в висе (10 раз)", sets: 5, order: 3, type: .repsOnly)
        day1.program = program
        program.days.append(day1)

        return program
    }

    // MARK: - Category X: Specials (Glutes / Core / Mobility)

    private nonisolated static func createGluteBuilder() -> Program {
        let program = Program(
            name: "Glute Builder",
            desc: "Glute-focused program. 3 sessions/week with hip thrusts as the cornerstone."
        )

        let dayHeavy = WorkoutDay(name: "Тяжёлый ягодичный", orderIndex: 0, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: dayHeavy, name: "Ягодичный мост (Hip Thrust)", sets: 5, order: 0)
        addExercise(to: dayHeavy, name: "Румынская тяга", sets: 4, order: 1)
        addExercise(to: dayHeavy, name: "Болгарские выпады", sets: 3, order: 2)
        addExercise(to: dayHeavy, name: "Отведение ноги на блоке", sets: 3, order: 3)
        addExercise(to: dayHeavy, name: "Подъем на носки сидя", sets: 4, order: 4)
        dayHeavy.program = program
        program.days.append(dayHeavy)

        let dayPump = WorkoutDay(name: "Памп ягодиц", orderIndex: 1, workoutType: .strength, defaultRestTime: 45)
        addExercise(to: dayPump, name: "Hip Thrust (с резинкой)", sets: 4, order: 0, type: .repsOnly)
        addExercise(to: dayPump, name: "Ягодичный мост одной ногой", sets: 3, order: 1, type: .repsOnly)
        addExercise(to: dayPump, name: "Отведение ноги (Cable Kickback)", sets: 3, order: 2)
        addExercise(to: dayPump, name: "Step Up на платформу", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: dayPump, name: "Frog Pump (Лягушка)", sets: 3, order: 4, type: .repsOnly)
        dayPump.program = program
        program.days.append(dayPump)

        let dayFunc = WorkoutDay(name: "Функциональный день", orderIndex: 2, workoutType: .strength, defaultRestTime: 60)
        addExercise(to: dayFunc, name: "Гоблет приседания", sets: 4, order: 0)
        addExercise(to: dayFunc, name: "Выпады назад", sets: 3, order: 1)
        addExercise(to: dayFunc, name: "Становая сумо", sets: 4, order: 2)
        addExercise(to: dayFunc, name: "Махи гирей", sets: 3, order: 3)
        dayFunc.program = program
        program.days.append(dayFunc)

        return program
    }

    private nonisolated static func createCoreCrusher() -> Program {
        let program = Program(
            name: "Core Crusher",
            desc: "Quick core finisher. 3 short sessions/week — perfect after main workouts."
        )

        let day1 = WorkoutDay(name: "Core A", orderIndex: 0, workoutType: .strength, defaultRestTime: 30)
        addExercise(to: day1, name: "Планка", sets: 3, order: 0, type: .duration)
        addExercise(to: day1, name: "Подъем ног в висе", sets: 3, order: 1, type: .repsOnly)
        addExercise(to: day1, name: "Скручивания на блоке", sets: 3, order: 2)
        addExercise(to: day1, name: "Russian Twist", sets: 3, order: 3, type: .repsOnly)
        day1.program = program
        program.days.append(day1)

        let day2 = WorkoutDay(name: "Core B", orderIndex: 1, workoutType: .strength, defaultRestTime: 30)
        addExercise(to: day2, name: "Боковая планка", sets: 3, order: 0, type: .duration)
        addExercise(to: day2, name: "Hollow Body Hold", sets: 3, order: 1, type: .duration)
        addExercise(to: day2, name: "Toes to Bar", sets: 3, order: 2, type: .repsOnly)
        addExercise(to: day2, name: "V-ups", sets: 3, order: 3, type: .repsOnly)
        day2.program = program
        program.days.append(day2)

        let day3 = WorkoutDay(name: "Core C", orderIndex: 2, workoutType: .strength, defaultRestTime: 30)
        addExercise(to: day3, name: "Уголок (L-sit) на брусьях", sets: 3, order: 0, type: .duration)
        addExercise(to: day3, name: "Велосипед", sets: 3, order: 1, type: .repsOnly)
        addExercise(to: day3, name: "Dead Bug", sets: 3, order: 2, type: .repsOnly)
        addExercise(to: day3, name: "Bird Dog", sets: 3, order: 3, type: .repsOnly)
        day3.program = program
        program.days.append(day3)

        return program
    }

    private nonisolated static func createMobilityFlow() -> Program {
        let program = Program(
            name: "Mobility Flow",
            desc: "Daily mobility routine. 15-20 minutes for joints and recovery."
        )

        let day1 = WorkoutDay(name: "Утренний поток", orderIndex: 0, workoutType: .duration, defaultRestTime: 15)
        addExercise(to: day1, name: "Cat-Cow (Кошка-Корова)", sets: 2, order: 0, type: .duration)
        addExercise(to: day1, name: "World's Greatest Stretch", sets: 2, order: 1, type: .duration)
        addExercise(to: day1, name: "Hip 90/90", sets: 2, order: 2, type: .duration)
        addExercise(to: day1, name: "Cossack Squat", sets: 2, order: 3, type: .duration)
        addExercise(to: day1, name: "Thoracic Bridge", sets: 2, order: 4, type: .duration)
        addExercise(to: day1, name: "Down Dog → Up Dog", sets: 2, order: 5, type: .duration)
        day1.program = program
        program.days.append(day1)

        return program
    }

    // MARK: - Category XI: New Specials (Glutes / Mobility)

    private nonisolated static func createBootyBuilderPro() -> Program {
        let program = Program(
            name: "Booty Builder Pro",
            desc: "Advanced 4-day glute hypertrophy program. Hip thrust as the cornerstone, plus targeted accessory work for medial/upper glutes."
        )

        let dayHipThrust = WorkoutDay(name: "Тяжёлый Hip Thrust", orderIndex: 0, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: dayHipThrust, name: "Ягодичный мост (Hip Thrust)", sets: 5, order: 0)
        addExercise(to: dayHipThrust, name: "Болгарские выпады", sets: 4, order: 1)
        addExercise(to: dayHipThrust, name: "Отведение ноги на блоке", sets: 4, order: 2)
        addExercise(to: dayHipThrust, name: "Frog Pump (Лягушка)", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: dayHipThrust, name: "Боковая планка", sets: 3, order: 4, type: .duration)
        dayHipThrust.program = program
        program.days.append(dayHipThrust)

        let daySumo = WorkoutDay(name: "Тяга Сумо + Памп", orderIndex: 1, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: daySumo, name: "Становая сумо", sets: 5, order: 0)
        addExercise(to: daySumo, name: "Румынская тяга", sets: 4, order: 1)
        addExercise(to: daySumo, name: "Step Up на платформу", sets: 3, order: 2, type: .repsOnly)
        addExercise(to: daySumo, name: "Отведение ноги (Cable Kickback)", sets: 3, order: 3)
        addExercise(to: daySumo, name: "Ягодичный мост одной ногой", sets: 3, order: 4, type: .repsOnly)
        daySumo.program = program
        program.days.append(daySumo)

        let dayQuadGlute = WorkoutDay(name: "Квадрицепс + Ягодицы", orderIndex: 2, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: dayQuadGlute, name: "Гоблет приседания", sets: 4, order: 0)
        addExercise(to: dayQuadGlute, name: "Выпады назад", sets: 4, order: 1)
        addExercise(to: dayQuadGlute, name: "Жим ногами", sets: 3, order: 2)
        addExercise(to: dayQuadGlute, name: "Hip Thrust (с резинкой)", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: dayQuadGlute, name: "Подъем на носки сидя", sets: 4, order: 4)
        dayQuadGlute.program = program
        program.days.append(dayQuadGlute)

        let dayBands = WorkoutDay(name: "Памп с резинками", orderIndex: 3, workoutType: .strength, defaultRestTime: 45)
        addExercise(to: dayBands, name: "Hip Thrust (с резинкой)", sets: 4, order: 0, type: .repsOnly)
        addExercise(to: dayBands, name: "Frog Pump (Лягушка)", sets: 4, order: 1, type: .repsOnly)
        addExercise(to: dayBands, name: "Отведение ноги (Cable Kickback)", sets: 3, order: 2)
        addExercise(to: dayBands, name: "Ягодичный мост", sets: 3, order: 3, type: .repsOnly)
        addExercise(to: dayBands, name: "Step Up на платформу", sets: 3, order: 4, type: .repsOnly)
        dayBands.program = program
        program.days.append(dayBands)

        return program
    }

    private nonisolated static func createYogaFlowRecovery() -> Program {
        let program = Program(
            name: "Yoga Flow Recovery",
            desc: "Recovery yoga flow. 25-30 minutes for the spine, hips, and shoulders. Perfect for active rest days."
        )

        let day1 = WorkoutDay(name: "Yoga Flow", orderIndex: 0, workoutType: .duration, defaultRestTime: 10)
        addExercise(to: day1, name: "Sun Salutation A (Сурья Намаскар)", sets: 3, order: 0, type: .duration)
        addExercise(to: day1, name: "Downward Dog (Собака мордой вниз)", sets: 2, order: 1, type: .duration)
        addExercise(to: day1, name: "Warrior II (Воин II)", sets: 2, order: 2, type: .duration)
        addExercise(to: day1, name: "Pigeon Pose (Голубь)", sets: 2, order: 3, type: .duration)
        addExercise(to: day1, name: "Cobra (Кобра)", sets: 2, order: 4, type: .duration)
        addExercise(to: day1, name: "Seated Forward Fold (Наклон сидя)", sets: 2, order: 5, type: .duration)
        addExercise(to: day1, name: "Child's Pose (Поза ребёнка)", sets: 2, order: 6, type: .duration)
        addExercise(to: day1, name: "Savasana (Шавасана)", sets: 1, order: 7, type: .duration)
        day1.program = program
        program.days.append(day1)

        return program
    }

    // MARK: - Category XII: New Cardio

    private nonisolated static func createCouchTo5K() -> Program {
        let program = Program(
            name: "Couch to 5K",
            desc: "Classic 9-week beginner running program. 3 sessions/week, alternating run/walk intervals. Builds up to a 5K run."
        )

        let week1 = WorkoutDay(name: "Неделя 1-2 (Run/Walk)", orderIndex: 0, workoutType: .duration, defaultRestTime: 0)
        addExercise(to: week1, name: "Разминка ходьбой (5 мин)", sets: 1, order: 0, type: .duration)
        addExercise(to: week1, name: "Бег 60 сек / Ходьба 90 сек × 8", sets: 8, order: 1, type: .duration)
        addExercise(to: week1, name: "Заминка ходьбой (5 мин)", sets: 1, order: 2, type: .duration)
        week1.program = program
        program.days.append(week1)

        let week3 = WorkoutDay(name: "Неделя 3-4 (Прогресс)", orderIndex: 1, workoutType: .duration, defaultRestTime: 0)
        addExercise(to: week3, name: "Разминка ходьбой (5 мин)", sets: 1, order: 0, type: .duration)
        addExercise(to: week3, name: "Бег 3 мин / Ходьба 90 сек × 5", sets: 5, order: 1, type: .duration)
        addExercise(to: week3, name: "Заминка ходьбой (5 мин)", sets: 1, order: 2, type: .duration)
        week3.program = program
        program.days.append(week3)

        let week6 = WorkoutDay(name: "Неделя 5-6 (Долгий бег)", orderIndex: 2, workoutType: .duration, defaultRestTime: 0)
        addExercise(to: week6, name: "Разминка ходьбой (5 мин)", sets: 1, order: 0, type: .duration)
        addExercise(to: week6, name: "Непрерывный бег 20 мин", sets: 1, order: 1, type: .duration)
        addExercise(to: week6, name: "Заминка ходьбой (5 мин)", sets: 1, order: 2, type: .duration)
        week6.program = program
        program.days.append(week6)

        let week9 = WorkoutDay(name: "Неделя 7-9 (5K)", orderIndex: 3, workoutType: .duration, defaultRestTime: 0)
        addExercise(to: week9, name: "Разминка ходьбой (5 мин)", sets: 1, order: 0, type: .duration)
        addExercise(to: week9, name: "Непрерывный бег 30 мин (≈5 км)", sets: 1, order: 1, type: .duration)
        addExercise(to: week9, name: "Заминка ходьбой (5 мин)", sets: 1, order: 2, type: .duration)
        week9.program = program
        program.days.append(week9)

        return program
    }

    private nonisolated static func createNorwegian4x4() -> Program {
        let program = Program(
            name: "Norwegian 4x4",
            desc: "Norwegian VO2max protocol. 4 minutes hard (90-95% HR max) / 3 minutes easy × 4 rounds. The most efficient cardio for VO2max."
        )

        let day1 = WorkoutDay(name: "4×4 Интервалы", orderIndex: 0, workoutType: .duration, defaultRestTime: 180)
        addExercise(to: day1, name: "Разминка (10 мин лёгкий бег)", sets: 1, order: 0, type: .duration)
        addExercise(to: day1, name: "Интервал 4 мин (90-95% ЧСС)", sets: 4, order: 1, type: .duration)
        addExercise(to: day1, name: "Восстановление 3 мин (60-70% ЧСС)", sets: 4, order: 2, type: .duration)
        addExercise(to: day1, name: "Заминка (5 мин ходьба)", sets: 1, order: 3, type: .duration)
        day1.program = program
        program.days.append(day1)

        return program
    }

    // MARK: - Category XIII: Hybrid & Volume

    private nonisolated static func createGermanVolumeTraining() -> Program {
        let program = Program(
            name: "German Volume Training (10×10)",
            desc: "Classic GVT hypertrophy method by Rolf Feser. 10 sets × 10 reps with one weight on the main lift, high volume for fast mass."
        )

        let dayChestBack = WorkoutDay(name: "День 1: Грудь + Спина", orderIndex: 0, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: dayChestBack, name: "Жим штанги лежа", sets: 10, order: 0)
        addExercise(to: dayChestBack, name: "Тяга вертикального блока", sets: 10, order: 1)
        addExercise(to: dayChestBack, name: "Сведение гантелей лежа", sets: 3, order: 2)
        addExercise(to: dayChestBack, name: "Тяга штанги в наклоне", sets: 3, order: 3)
        dayChestBack.program = program
        program.days.append(dayChestBack)

        let dayLegsAbs = WorkoutDay(name: "День 2: Ноги + Пресс", orderIndex: 1, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: dayLegsAbs, name: "Приседания со штангой", sets: 10, order: 0)
        addExercise(to: dayLegsAbs, name: "Сгибание ног лежа", sets: 10, order: 1)
        addExercise(to: dayLegsAbs, name: "Подъем на носки", sets: 3, order: 2)
        addExercise(to: dayLegsAbs, name: "Подъем ног в висе", sets: 3, order: 3, type: .repsOnly)
        dayLegsAbs.program = program
        program.days.append(dayLegsAbs)

        let dayArmsShoulders = WorkoutDay(name: "День 3: Руки + Плечи", orderIndex: 2, workoutType: .strength, defaultRestTime: 90)
        addExercise(to: dayArmsShoulders, name: "Жим гантелей стоя", sets: 10, order: 0)
        addExercise(to: dayArmsShoulders, name: "Подъем гантелей на бицепс", sets: 10, order: 1)
        addExercise(to: dayArmsShoulders, name: "Разгибание на трицепс на блоке", sets: 3, order: 2)
        addExercise(to: dayArmsShoulders, name: "Махи гантелями в стороны", sets: 3, order: 3)
        dayArmsShoulders.program = program
        program.days.append(dayArmsShoulders)

        return program
    }

    private nonisolated static func createHybridAthlete() -> Program {
        let program = Program(
            name: "Hybrid Athlete",
            desc: "Strength + endurance combo. 4 days/week: 2 strength, 2 conditioning. Build size, strength, and a strong engine in parallel."
        )

        let dayUpperStrength = WorkoutDay(name: "День 1: Сила Верх", orderIndex: 0, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: dayUpperStrength, name: "Жим штанги лежа", sets: 5, order: 0)
        addExercise(to: dayUpperStrength, name: "Подтягивания", sets: 5, order: 1, type: .repsOnly)
        addExercise(to: dayUpperStrength, name: "Жим гантелей стоя", sets: 4, order: 2)
        addExercise(to: dayUpperStrength, name: "Тяга гантели в наклоне", sets: 4, order: 3)
        addExercise(to: dayUpperStrength, name: "Лицевая тяга", sets: 3, order: 4)
        dayUpperStrength.program = program
        program.days.append(dayUpperStrength)

        let dayCondition1 = WorkoutDay(name: "День 2: Кондиции (Бег)", orderIndex: 1, workoutType: .duration, defaultRestTime: 60)
        addExercise(to: dayCondition1, name: "Разминка ходьбой (5 мин)", sets: 1, order: 0, type: .duration)
        addExercise(to: dayCondition1, name: "Бег (Интервалы: 30/30, 45/45, 60/60)", sets: 1, order: 1, type: .duration)
        addExercise(to: dayCondition1, name: "Заминка ходьбой (5 мин)", sets: 1, order: 2, type: .duration)
        dayCondition1.program = program
        program.days.append(dayCondition1)

        let dayLowerStrength = WorkoutDay(name: "День 3: Сила Низ", orderIndex: 2, workoutType: .strength, defaultRestTime: 120)
        addExercise(to: dayLowerStrength, name: "Приседания со штангой", sets: 5, order: 0)
        addExercise(to: dayLowerStrength, name: "Румынская тяга", sets: 4, order: 1)
        addExercise(to: dayLowerStrength, name: "Болгарские сплит-приседания", sets: 3, order: 2)
        addExercise(to: dayLowerStrength, name: "Ягодичный мост (Hip Thrust)", sets: 3, order: 3)
        addExercise(to: dayLowerStrength, name: "Подъем на носки", sets: 3, order: 4)
        dayLowerStrength.program = program
        program.days.append(dayLowerStrength)

        let dayCondition2 = WorkoutDay(name: "День 4: Метcон + Кор", orderIndex: 3, workoutType: .duration, defaultRestTime: 45)
        addExercise(to: dayCondition2, name: "Махи гирей", sets: 5, order: 0, type: .repsOnly)
        addExercise(to: dayCondition2, name: "Burpees (Берпи)", sets: 5, order: 1, type: .repsOnly)
        addExercise(to: dayCondition2, name: "Mountain Climbers (Скалолаз)", sets: 5, order: 2, type: .duration)
        addExercise(to: dayCondition2, name: "Планка", sets: 3, order: 3, type: .duration)
        dayCondition2.program = program
        program.days.append(dayCondition2)

        return program
    }

    private nonisolated static func addExercise(to day: WorkoutDay, name: String, sets: Int, order: Int, type: WorkoutType? = nil) {
        let exercise = ExerciseTemplate(name: name, plannedSets: sets, orderIndex: order, type: type)
        day.exercises.append(exercise)
    }
}
