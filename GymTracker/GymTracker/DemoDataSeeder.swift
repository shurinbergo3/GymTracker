//
//  DemoDataSeeder.swift
//  GymTracker
//
//  Generates demo workout history for the test account "apple@demo1.com".
//  Triggered once per signed-in demo user; idempotent via UserDefaults flag.
//

import Foundation
import SwiftData

struct DemoDataSeeder {

    static let demoEmail = "apple@demo1.com"
    private static let flagKeyPrefix = "DemoSeeded_"

    /// Entry point. Safe to call multiple times — it returns early when:
    /// - The current user email is not the demo account
    /// - The demo data has already been seeded for this uid
    /// - Sessions already exist locally (either from a prior seed or from Firestore restore)
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        guard let user = AuthManager.shared.currentUser else { return }
        guard user.email.lowercased() == demoEmail else { return }

        let flagKey = flagKeyPrefix + user.uid
        if UserDefaults.standard.bool(forKey: flagKey) { return }

        // Skip if the DB already has sessions — they may have been restored from Firestore.
        let descriptor = FetchDescriptor<WorkoutSession>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        if existingCount > 0 {
            UserDefaults.standard.set(true, forKey: flagKey)
            return
        }

        #if DEBUG
        print("🌱 DemoDataSeeder: seeding demo data for \(user.email)")
        #endif

        seedUserProfile(context: context)
        seedMeasurements(context: context)
        activateMassProgram(context: context)
        seedWorkoutHistory(context: context, totalSessions: 120)

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: flagKey)
            #if DEBUG
            print("✅ DemoDataSeeder: seeded 120 sessions + profile + program (local)")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ DemoDataSeeder save failed: \(error)")
            #endif
            return
        }

        // Push everything to Firestore so the demo account is durable across reinstalls/devices.
        // User edits made later go through the standard sync paths, which overwrite cloud state.
        Task { @MainActor in
            await pushDemoDataToFirestore(context: context)
        }
    }

    /// Upload locally-seeded demo data to Firestore so the account survives reinstalls/devices.
    @MainActor
    private static func pushDemoDataToFirestore(context: ModelContext) async {
        #if DEBUG
        print("☁️ DemoDataSeeder: pushing demo data to Firestore…")
        #endif

        // 1. Workouts (uses isSynced=false marker we set in seedWorkoutHistory).
        await SyncManager.shared.syncUnsyncedWorkouts(context: context)

        // 2. User profile + weight history + measurements + active program reference.
        let profile = (try? context.fetch(FetchDescriptor<UserProfile>()))?.last
        let activeProgram = (try? context.fetch(
            FetchDescriptor<Program>(predicate: #Predicate { $0.isActive })
        ))?.first
        if let profile {
            await SyncManager.shared.syncUserProfile(
                profile: profile,
                activeProgram: activeProgram,
                context: context
            )
        }

        // 3. Programs (active flag goes to cloud too).
        await SyncManager.shared.syncAllPrograms(context: context)

        #if DEBUG
        print("✅ DemoDataSeeder: cloud sync complete")
        #endif
    }

    // MARK: - Profile + measurements

    @MainActor
    private static func seedUserProfile(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        let profile: UserProfile
        if let p = existing.last {
            profile = p
            profile.height = 180
            profile.age = 28
        } else {
            profile = UserProfile(height: 180, initialWeight: 75.0, age: 28)
            context.insert(profile)
        }

        // Add weight history showing gradual mass gain: 75kg → 82kg over ~9 months.
        let calendar = Calendar.current
        let now = Date()
        // Clear existing history (incl. the one created by init) — snapshot first to avoid mutating during iteration.
        let existingRecords = Array(profile.weightHistory)
        profile.weightHistory.removeAll()
        for record in existingRecords {
            context.delete(record)
        }

        let weightPoints: [(daysAgo: Int, weight: Double)] = [
            (280, 75.0), (266, 75.4), (252, 75.9), (238, 76.5),
            (224, 76.8), (210, 77.4), (196, 77.9), (182, 78.3),
            (168, 78.7), (154, 79.1), (140, 79.6), (126, 80.0),
            (112, 80.3), (98, 80.7), (84, 81.0), (70, 81.3),
            (56, 81.6), (42, 81.8), (28, 82.0), (14, 82.1),
            (1, 82.3)
        ]
        for point in weightPoints {
            let date = calendar.date(byAdding: .day, value: -point.daysAgo, to: now) ?? now
            let record = WeightRecord(weight: point.weight, date: date)
            record.userProfile = profile
            profile.weightHistory.append(record)
            context.insert(record)
        }
        profile.updatedAt = now
    }

    @MainActor
    private static func seedMeasurements(context: ModelContext) {
        // Clear existing demo measurements to avoid duplicates if re-run.
        let existing = (try? context.fetch(FetchDescriptor<BodyMeasurement>())) ?? []
        for m in existing { context.delete(m) }

        let now = Date()
        let calendar = Calendar.current

        // (type, startValue, endValue) over the same 280-day window
        let plan: [(MeasurementType, Double, Double)] = [
            (.chest,     95.0, 102.5),
            (.biceps,    35.0,  38.5),
            (.thigh,     55.0,  59.5),
            (.waist,     80.0,  82.0),
            (.shoulders, 118.0, 124.0),
            (.calf,      36.0,  38.0),
            (.forearm,   28.0,  30.0),
            (.neck,      38.0,  39.5),
        ]

        let snapshots = [280, 224, 168, 112, 56, 1]
        for (type, start, end) in plan {
            for (idx, daysAgo) in snapshots.enumerated() {
                let progress = Double(idx) / Double(snapshots.count - 1)
                let value = start + (end - start) * progress
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
                let measurement = BodyMeasurement(date: date, type: type, value: roundTo(value, decimals: 1))
                context.insert(measurement)
            }
        }
    }

    // MARK: - Program activation

    @MainActor
    private static func activateMassProgram(context: ModelContext) {
        let target = "Push Pull Legs (PPL)"
        guard let programs = try? context.fetch(FetchDescriptor<Program>()) else { return }
        for program in programs {
            program.isActive = (program.name == target)
        }
        // If the program isn't found (seeder didn't run yet), there's nothing more to do —
        // the seeder runs alongside ProgramSeeder, so by the time UI shows up it will be active.
    }

    // MARK: - Workout history

    /// PPL split mirrored from ProgramSeeder.createPushPullLegs() — six day rotation.
    private static let pplDays: [(dayName: String, exercises: [DemoExercise])] = [
        ("Push (Грудь+Плечи+Трицепс)", [
            DemoExercise(name: "Жим штанги лежа",            baseWeight: 70,  endWeight: 95,  baseReps: 6, sets: 4, kind: .barbell),
            DemoExercise(name: "Жим гантелей на наклонной",  baseWeight: 24,  endWeight: 34,  baseReps: 8, sets: 3, kind: .dumbbell),
            DemoExercise(name: "Армейский жим",              baseWeight: 40,  endWeight: 55,  baseReps: 6, sets: 3, kind: .barbell),
            DemoExercise(name: "Махи гантелями в стороны",   baseWeight: 8,   endWeight: 14,  baseReps: 12, sets: 3, kind: .dumbbell),
            DemoExercise(name: "Разгибание на трицепс на блоке", baseWeight: 25, endWeight: 40, baseReps: 10, sets: 3, kind: .cable),
            DemoExercise(name: "Французский жим",            baseWeight: 20,  endWeight: 32,  baseReps: 8, sets: 3, kind: .barbell),
        ]),
        ("Pull (Спина+Бицепс)", [
            DemoExercise(name: "Подтягивания",               baseWeight: 0,   endWeight: 0,   baseReps: 8, sets: 4, kind: .bodyweight),
            DemoExercise(name: "Тяга штанги в наклоне",      baseWeight: 55,  endWeight: 80,  baseReps: 8, sets: 4, kind: .barbell),
            DemoExercise(name: "Тяга верхнего блока",        baseWeight: 50,  endWeight: 72,  baseReps: 10, sets: 3, kind: .cable),
            DemoExercise(name: "Тяга горизонтального блока", baseWeight: 50,  endWeight: 70,  baseReps: 10, sets: 3, kind: .cable),
            DemoExercise(name: "Подъем штанги на бицепс",    baseWeight: 25,  endWeight: 40,  baseReps: 8, sets: 3, kind: .barbell),
            DemoExercise(name: "Молотки на бицепс",          baseWeight: 12,  endWeight: 20,  baseReps: 10, sets: 3, kind: .dumbbell),
        ]),
        ("Legs (Ноги+Пресс)", [
            DemoExercise(name: "Приседания со штангой",      baseWeight: 80,  endWeight: 120, baseReps: 6, sets: 4, kind: .barbell),
            DemoExercise(name: "Румынская тяга",             baseWeight: 70,  endWeight: 110, baseReps: 8, sets: 4, kind: .barbell),
            DemoExercise(name: "Жим ногами",                 baseWeight: 120, endWeight: 200, baseReps: 10, sets: 3, kind: .machine),
            DemoExercise(name: "Сгибание ног лежа",          baseWeight: 30,  endWeight: 50,  baseReps: 12, sets: 3, kind: .machine),
            DemoExercise(name: "Подъем на носки",            baseWeight: 60,  endWeight: 100, baseReps: 15, sets: 4, kind: .machine),
            DemoExercise(name: "Подъем ног в висе",          baseWeight: 0,   endWeight: 0,   baseReps: 12, sets: 3, kind: .bodyweight),
        ]),
        ("Push (вариация)", [
            DemoExercise(name: "Жим гантелей лежа",          baseWeight: 26,  endWeight: 38,  baseReps: 8, sets: 4, kind: .dumbbell),
            DemoExercise(name: "Жим лежа на наклонной",      baseWeight: 55,  endWeight: 80,  baseReps: 8, sets: 3, kind: .barbell),
            DemoExercise(name: "Жим Арнольда",               baseWeight: 14,  endWeight: 22,  baseReps: 10, sets: 3, kind: .dumbbell),
            DemoExercise(name: "Махи на блоке",              baseWeight: 8,   endWeight: 14,  baseReps: 12, sets: 3, kind: .cable),
            DemoExercise(name: "Отжимания на брусьях",       baseWeight: 0,   endWeight: 0,   baseReps: 10, sets: 3, kind: .bodyweight),
            DemoExercise(name: "Разгибание над головой",     baseWeight: 18,  endWeight: 28,  baseReps: 10, sets: 3, kind: .dumbbell),
        ]),
        ("Pull (вариация)", [
            DemoExercise(name: "Становая тяга",              baseWeight: 90,  endWeight: 140, baseReps: 5, sets: 4, kind: .barbell),
            DemoExercise(name: "Тяга Т-грифа",               baseWeight: 40,  endWeight: 65,  baseReps: 8, sets: 3, kind: .barbell),
            DemoExercise(name: "Тяга одной рукой",           baseWeight: 22,  endWeight: 34,  baseReps: 10, sets: 3, kind: .dumbbell),
            DemoExercise(name: "Лицевая тяга",               baseWeight: 18,  endWeight: 28,  baseReps: 12, sets: 3, kind: .cable),
            DemoExercise(name: "Сгибание Паук",              baseWeight: 10,  endWeight: 16,  baseReps: 10, sets: 3, kind: .dumbbell),
            DemoExercise(name: "Подъем гантелей на бицепс",  baseWeight: 12,  endWeight: 20,  baseReps: 10, sets: 3, kind: .dumbbell),
        ]),
        ("Legs (вариация)", [
            DemoExercise(name: "Фронтальные приседания",     baseWeight: 60,  endWeight: 90,  baseReps: 6, sets: 4, kind: .barbell),
            DemoExercise(name: "Болгарские выпады",          baseWeight: 14,  endWeight: 24,  baseReps: 10, sets: 3, kind: .dumbbell),
            DemoExercise(name: "Ягодичный мост",             baseWeight: 80,  endWeight: 130, baseReps: 10, sets: 4, kind: .barbell),
            DemoExercise(name: "Разгибание ног",             baseWeight: 35,  endWeight: 60,  baseReps: 12, sets: 3, kind: .machine),
            DemoExercise(name: "Сгибание ног сидя",          baseWeight: 30,  endWeight: 50,  baseReps: 12, sets: 3, kind: .machine),
            DemoExercise(name: "Подъем на носки сидя",       baseWeight: 40,  endWeight: 70,  baseReps: 15, sets: 4, kind: .machine),
        ]),
    ]

    @MainActor
    private static func seedWorkoutHistory(context: ModelContext, totalSessions: Int) {
        let calendar = Calendar.current
        let now = Date()
        // Spread totalSessions across ~280 days. Roughly 4 workouts / week.
        let totalDays = 280
        var seededDates: [Date] = []
        var rng = SeededGenerator(seed: 0xBEEF_C0DE)

        var day = totalDays
        while seededDates.count < totalSessions && day > 0 {
            // Skip 1-2 random days between workouts (avg 2.3 days gap = ~3/week).
            let gap = Int.random(in: 1...3, using: &rng)
            day -= gap
            if day <= 0 { break }
            let hour = Int.random(in: 7...20, using: &rng)
            let minute = Int.random(in: 0...59, using: &rng)
            if let base = calendar.date(byAdding: .day, value: -day, to: now),
               let withTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) {
                seededDates.append(withTime)
            }
        }

        // Trim or pad to exact totalSessions (in case loop produced slightly different count).
        if seededDates.count > totalSessions {
            seededDates = Array(seededDates.prefix(totalSessions))
        }

        // Sort oldest → newest so progressive overload makes sense across the timeline.
        seededDates.sort()

        let programName = "Push Pull Legs (PPL)"
        for (index, date) in seededDates.enumerated() {
            let dayTemplate = pplDays[index % pplDays.count]
            let progress = Double(index) / Double(max(seededDates.count - 1, 1))

            let session = WorkoutSession(
                date: date,
                workoutDayName: dayTemplate.dayName,
                programName: programName,
                notes: nil
            )
            session.isCompleted = true
            // Typical session length: 50-80 min
            let durationMin = 50 + Int.random(in: 0...30, using: &rng)
            session.endTime = calendar.date(byAdding: .minute, value: durationMin, to: date)
            // Realistic calorie & HR estimates for a hypertrophy session
            session.calories = 320 + Int.random(in: -40...80, using: &rng)
            session.averageHeartRate = 118 + Int.random(in: -6...12, using: &rng)
            session.isSynced = false // mark unsynced so SyncManager pushes them to Firestore
            context.insert(session)

            for exercise in dayTemplate.exercises {
                let topWeight = interpolate(exercise.baseWeight, exercise.endWeight, progress: progress)
                for setNumber in 1...exercise.sets {
                    let set = makeSet(
                        for: exercise,
                        setNumber: setNumber,
                        topWeight: topWeight,
                        date: date,
                        rng: &rng
                    )
                    set.session = session
                    session.sets.append(set)
                    context.insert(set)
                }
            }
        }
    }

    @MainActor
    private static func makeSet(
        for exercise: DemoExercise,
        setNumber: Int,
        topWeight: Double,
        date: Date,
        rng: inout SeededGenerator
    ) -> WorkoutSet {
        // Slight per-set variability: first set near top, drop set on last set sometimes.
        let dropFactor: Double
        switch setNumber {
        case 1: dropFactor = 1.0
        case 2: dropFactor = 0.97
        case 3: dropFactor = 0.94
        default: dropFactor = 0.90
        }

        let jitter = Double.random(in: -0.02...0.02, using: &rng)
        let rawWeight = topWeight * (dropFactor + jitter)

        let weight: Double
        let reps: Int
        let isWeighted: Bool
        switch exercise.kind {
        case .bodyweight:
            weight = 0
            reps = max(4, exercise.baseReps + Int.random(in: -2...3, using: &rng))
            isWeighted = false
        case .barbell:
            weight = roundTo(rawWeight, decimals: 0, step: 2.5)
            reps = max(3, exercise.baseReps + Int.random(in: -2...2, using: &rng))
            isWeighted = false
        case .dumbbell:
            weight = roundTo(rawWeight, decimals: 0, step: 2.0)
            reps = max(4, exercise.baseReps + Int.random(in: -2...3, using: &rng))
            isWeighted = false
        case .cable, .machine:
            weight = roundTo(rawWeight, decimals: 0, step: 2.5)
            reps = max(6, exercise.baseReps + Int.random(in: -2...3, using: &rng))
            isWeighted = false
        }

        let set = WorkoutSet(
            exerciseName: exercise.name,
            weight: weight,
            reps: reps,
            setNumber: setNumber,
            date: date,
            isWeighted: isWeighted
        )
        set.isCompleted = true
        return set
    }

    // MARK: - Helpers

    private static func interpolate(_ start: Double, _ end: Double, progress: Double) -> Double {
        let clamped = max(0, min(1, progress))
        return start + (end - start) * clamped
    }

    private static func roundTo(_ value: Double, decimals: Int, step: Double = 0) -> Double {
        if step > 0 {
            return (value / step).rounded() * step
        }
        let factor = pow(10.0, Double(decimals))
        return (value * factor).rounded() / factor
    }

    // MARK: - Types

    private enum ExerciseKind {
        case barbell, dumbbell, cable, machine, bodyweight
    }

    private struct DemoExercise {
        let name: String
        let baseWeight: Double
        let endWeight: Double
        let baseReps: Int
        let sets: Int
        let kind: ExerciseKind
    }

    /// Deterministic PRNG so the seeded history is stable across runs.
    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { self.state = seed != 0 ? seed : 0xDEAD_BEEF }
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z &>> 31)
        }
    }
}
