//
//  AICoachContextBuilder.swift
//  GymTracker
//
//  Builds a compact, model-friendly context block describing the user's
//  recent training, sensor data, comments, profile, **active program**,
//  body measurements, weight trend and aggregate workout stats. The output
//  is embedded into the first user message of every cycle.
//

import Foundation
import SwiftData

/// Pure data container — no SwiftData / SwiftUI types — so it's safe to
/// pass between actors and serialise.
struct AICoachContext {
    struct ProfileSummary {
        let age: Int
        let heightCm: Double
        let weightKg: Double
    }

    struct SetSummary {
        let setNumber: Int
        let weight: Double
        let reps: Int
        let isCompleted: Bool
        let comment: String?
    }

    struct ExerciseSummary {
        let name: String
        let sets: [SetSummary]
    }

    struct WorkoutSummary {
        let date: Date
        let dayName: String
        let programName: String?
        let durationMinutes: Int?
        let calories: Int?
        let averageHeartRate: Int?
        let totalVolume: Double      // Σ weight × reps for completed sets
        let totalSets: Int
        let completedSets: Int
        let exercises: [ExerciseSummary]
        let notes: String?
    }

    struct HealthSummary {
        let restingHeartRate: Int?
        let last7DaysSteps: Int?
        let last7DaysWorkouts: Int?
        let lastNightSleepHours: Double?
        let weeklySleepAvgHours: Double?
    }

    struct ProgramExerciseSummary {
        let name: String
        let plannedSets: Int
        let workoutType: String       // "strength" / "repsOnly" / "duration"
    }

    struct ProgramDaySummary {
        let name: String
        let orderIndex: Int
        let workoutType: String
        let defaultRestSec: Int
        let exercises: [ProgramExerciseSummary]
    }

    struct ProgramSummary {
        let name: String
        let description: String?
        let startedDaysAgo: Int
        let isActive: Bool
        let isUserModified: Bool
        let days: [ProgramDaySummary]
        let currentDayName: String?   // which day is "today" in the cycle
    }

    struct MeasurementSummary {
        let typeName: String          // "Бицепс", "Грудь", ...
        let valueCm: Double
        let date: Date
    }

    struct WeightTrendSummary {
        let currentKg: Double
        let weekAgoKg: Double?
        let monthAgoKg: Double?
    }

    struct AggregateStats {
        let totalCompletedWorkouts: Int
        let workoutsThisWeek: Int
        let avgWorkoutsPerWeekLast4Weeks: Double
        let totalVolumeLast30Days: Double
        let longestStreakDays: Int    // consecutive days with at least 1 completed workout
        let currentStreakDays: Int    // active consecutive-day streak right now (back from today)
    }

    /// Detected stagnation on a specific exercise — the strongest weight×reps
    /// load hasn't improved in N weeks across at least M sessions. The model
    /// is asked to either propose a deload, a tempo/range change or a swap.
    struct PlateauHint {
        let exerciseName: String
        let topWeightKg: Double
        let topReps: Int
        let weeksStuck: Int
        let sessionsStuck: Int
    }

    let profile: ProfileSummary?
    let workouts: [WorkoutSummary]                // most recent first
    let health: HealthSummary
    let program: ProgramSummary?
    let measurements: [MeasurementSummary]
    let weightTrend: WeightTrendSummary?
    let stats: AggregateStats
    let plateaus: [PlateauHint]
    let userLocaleIdentifier: String
}

@MainActor
enum AICoachContextBuilder {

    /// Pulls the last `limit` completed workouts from SwiftData + sensor data
    /// from HealthKit + active program + body data + aggregate stats and
    /// packs them into an `AICoachContext`.
    ///
    /// Rendering is tiered to keep token cost low even with `limit = 10`:
    /// • Index 0 (just-finished): full set-level detail + every comment.
    /// • Index 1+ (older): compact per-exercise grouping, headers only,
    ///   comments dropped unless they look like a pain/injury signal.
    static func build(modelContext: ModelContext,
                      healthManager: HealthManager,
                      limit: Int = 10) async -> AICoachContext {

        // --- Recent workouts ---------------------------------------------
        var workoutDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        workoutDescriptor.fetchLimit = limit
        let recentSessions = (try? modelContext.fetch(workoutDescriptor)) ?? []

        let workouts: [AICoachContext.WorkoutSummary] = recentSessions.map { session in
            workoutSummary(from: session)
        }

        // --- Profile -----------------------------------------------------
        let profile: AICoachContext.ProfileSummary?
        let profDescriptor = FetchDescriptor<UserProfile>()
        let userProfile = try? modelContext.fetch(profDescriptor).last
        if let p = userProfile {
            profile = .init(age: p.age, heightCm: p.height, weightKg: p.currentWeight)
        } else {
            profile = nil
        }

        // --- Active program ----------------------------------------------
        let activeProgramDescriptor = FetchDescriptor<Program>(
            predicate: #Predicate { $0.isActive == true }
        )
        let activeProgram = (try? modelContext.fetch(activeProgramDescriptor))?.first
        let programSummary = activeProgram.map { programSummaryFrom($0) }

        // --- Body measurements (latest per type) -------------------------
        let measurementDescriptor = FetchDescriptor<BodyMeasurement>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allMeasurements = (try? modelContext.fetch(measurementDescriptor)) ?? []
        var seen = Set<MeasurementType>()
        var latestMeasurements: [AICoachContext.MeasurementSummary] = []
        for m in allMeasurements where !seen.contains(m.type) {
            seen.insert(m.type)
            latestMeasurements.append(.init(
                typeName: m.type.rawValue,
                valueCm: m.value,
                date: m.date
            ))
        }

        // --- Weight trend ------------------------------------------------
        let weightTrend = userProfile.flatMap { weightTrendFrom($0.weightHistory) }

        // --- Aggregate stats (across ALL completed workouts) -------------
        let allCompletedDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allCompleted = (try? modelContext.fetch(allCompletedDescriptor)) ?? []
        let stats = aggregateStats(from: allCompleted)
        let plateaus = detectPlateaus(from: allCompleted)

        // --- Sensors -----------------------------------------------------
        var rhr: Int? = nil
        var weeklySteps: Int? = nil
        var weeklyWorkouts: Int? = nil
        var lastNightSleep: Double? = nil
        var weeklySleepAvg: Double? = nil

        if healthManager.isAuthorized {
            async let rhrVal = healthManager.fetchRestingHeartRate()
            async let stepsVal = healthManager.fetchWeeklyStepsTotal()
            async let workoutsVal = healthManager.fetchWorkoutsThisWeek()
            async let sleepHist = SleepService.shared.fetchSleepHistory(for: .week)

            let rhrD = await rhrVal
            if rhrD > 0 { rhr = Int(rhrD) }

            let st = await stepsVal
            if st > 0 { weeklySteps = st }

            let wk = await workoutsVal
            if wk > 0 { weeklyWorkouts = wk }

            let sleep = await sleepHist
            if !sleep.isEmpty {
                let last = sleep.max(by: { $0.date < $1.date })
                if let last, last.totalDuration > 0 {
                    lastNightSleep = last.totalDuration / 3600
                }
                let avg = sleep.map { $0.totalDuration }.reduce(0, +) / Double(sleep.count)
                if avg > 0 { weeklySleepAvg = avg / 3600 }
            }
        }

        let health = AICoachContext.HealthSummary(
            restingHeartRate: rhr,
            last7DaysSteps: weeklySteps,
            last7DaysWorkouts: weeklyWorkouts,
            lastNightSleepHours: lastNightSleep,
            weeklySleepAvgHours: weeklySleepAvg
        )

        return AICoachContext(
            profile: profile,
            workouts: workouts,
            health: health,
            program: programSummary,
            measurements: latestMeasurements,
            weightTrend: weightTrend,
            stats: stats,
            plateaus: plateaus,
            userLocaleIdentifier: LanguageManager.shared.currentLocale.identifier
        )
    }

    // MARK: - Mappers

    private static func workoutSummary(from session: WorkoutSession) -> AICoachContext.WorkoutSummary {
        let durationMin: Int?
        if let end = session.endTime {
            durationMin = max(0, Int(end.timeIntervalSince(session.date) / 60))
        } else {
            durationMin = nil
        }

        // Group sets by exercise, preserving discovery order
        var orderedNames: [String] = []
        var grouped: [String: [WorkoutSet]] = [:]
        for set in session.sets {
            if grouped[set.exerciseName] == nil {
                orderedNames.append(set.exerciseName)
                grouped[set.exerciseName] = []
            }
            grouped[set.exerciseName]?.append(set)
        }

        let exercises: [AICoachContext.ExerciseSummary] = orderedNames.map { name in
            let sets = (grouped[name] ?? []).sorted { lhs, rhs in
                if lhs.date != rhs.date { return lhs.date < rhs.date }
                return lhs.setNumber < rhs.setNumber
            }
            let setSummaries = sets.map {
                AICoachContext.SetSummary(
                    setNumber: $0.setNumber,
                    weight: $0.weight,
                    reps: $0.reps,
                    isCompleted: $0.isCompleted,
                    comment: $0.comment?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyOrNil
                )
            }
            return AICoachContext.ExerciseSummary(name: name, sets: setSummaries)
        }

        let totalVolume = session.sets
            .filter { $0.isCompleted }
            .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }

        return AICoachContext.WorkoutSummary(
            date: session.date,
            dayName: session.workoutDayName,
            programName: session.programName,
            durationMinutes: durationMin,
            calories: session.calories,
            averageHeartRate: session.averageHeartRate,
            totalVolume: totalVolume,
            totalSets: session.sets.count,
            completedSets: session.sets.filter { $0.isCompleted }.count,
            exercises: exercises,
            notes: session.notes?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyOrNil
        )
    }

    private static func programSummaryFrom(_ program: Program) -> AICoachContext.ProgramSummary {
        let cal = Calendar.current
        let started = cal.dateComponents([.day], from: program.startDate, to: Date()).day ?? 0
        let sortedDays = program.days.sorted { $0.orderIndex < $1.orderIndex }

        let days: [AICoachContext.ProgramDaySummary] = sortedDays.map { day in
            let exs = day.exercises.sorted { $0.orderIndex < $1.orderIndex }
            let exerciseSummaries = exs.map { ex in
                AICoachContext.ProgramExerciseSummary(
                    name: ex.name,
                    plannedSets: ex.plannedSets,
                    workoutType: ex.resolvedWorkoutType.rawValue
                )
            }
            return AICoachContext.ProgramDaySummary(
                name: day.name,
                orderIndex: day.orderIndex,
                workoutType: day.workoutType.rawValue,
                defaultRestSec: day.defaultRestTime,
                exercises: exerciseSummaries
            )
        }

        return AICoachContext.ProgramSummary(
            name: program.name,
            description: program.desc.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyOrNil,
            startedDaysAgo: max(0, started),
            isActive: program.isActive,
            isUserModified: program.isUserModified,
            days: days,
            currentDayName: program.currentWorkoutDay()?.name
        )
    }

    private static func weightTrendFrom(_ history: [WeightRecord]) -> AICoachContext.WeightTrendSummary? {
        let sorted = history.sorted { $0.date < $1.date }
        guard let latest = sorted.last, latest.weight > 0 else { return nil }

        let now = Date()
        let weekAgo = now.addingTimeInterval(-7 * 24 * 3600)
        let monthAgo = now.addingTimeInterval(-30 * 24 * 3600)

        // Pick the record closest to (and ≤) the target date
        func closest(to target: Date) -> Double? {
            let candidates = sorted.filter { $0.date <= target }
            return candidates.last?.weight
        }

        return .init(
            currentKg: latest.weight,
            weekAgoKg: closest(to: weekAgo),
            monthAgoKg: closest(to: monthAgo)
        )
    }

    private static func aggregateStats(from completed: [WorkoutSession]) -> AICoachContext.AggregateStats {
        let total = completed.count

        let cal = Calendar.current
        let now = Date()

        // This week (Mon-anchored, matching dashboard)
        var weekCal = Calendar(identifier: .gregorian)
        weekCal.firstWeekday = 2
        let today = weekCal.startOfDay(for: now)
        let weekday = weekCal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let monday = weekCal.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        let thisWeek = completed.filter { $0.date >= monday }.count

        // Last 4 weeks average
        let fourWeeksAgo = now.addingTimeInterval(-28 * 24 * 3600)
        let last4w = completed.filter { $0.date >= fourWeeksAgo }.count
        let avgPerWeek = Double(last4w) / 4.0

        // Total volume in last 30 days
        let thirtyAgo = now.addingTimeInterval(-30 * 24 * 3600)
        let recent = completed.filter { $0.date >= thirtyAgo }
        let totalVolume30 = recent.reduce(0.0) { acc, session in
            acc + session.sets
                .filter { $0.isCompleted }
                .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        }

        // Longest streak of consecutive workout days (historical max).
        let uniqueDays = Set(completed.map { cal.startOfDay(for: $0.date) })
        let sortedDays = uniqueDays.sorted()
        var longest = 0
        var current = 0
        var prev: Date?
        for day in sortedDays {
            if let p = prev,
               let next = cal.date(byAdding: .day, value: 1, to: p),
               cal.isDate(next, inSameDayAs: day) {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            prev = day
        }

        // Current active streak — counts back from today (or yesterday if not
        // yet trained today), matching `WeeklyStreakStrip.streak`.
        var currentStreak = 0
        var cursor = cal.startOfDay(for: now)
        if !uniqueDays.contains(cursor) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while uniqueDays.contains(cursor) {
            currentStreak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        return .init(
            totalCompletedWorkouts: total,
            workoutsThisWeek: thisWeek,
            avgWorkoutsPerWeekLast4Weeks: avgPerWeek,
            totalVolumeLast30Days: totalVolume30,
            longestStreakDays: longest,
            currentStreakDays: currentStreak
        )
    }

    // MARK: - Plateau detection

    /// Walks every (exercise, session) pair to flag named exercises whose
    /// best top-set load (weight × reps) hasn't been beaten in a meaningful
    /// stretch. Heuristic: "stuck" means
    ///   • the exercise has been trained at least 3 separate sessions, AND
    ///   • the top weight×reps observed in the last 4 weeks is ≤ the best
    ///     observed in the prior 4 weeks, AND
    ///   • the most recent best happened ≥ 14 days ago.
    /// Returns at most the top 3 stuck exercises (by recency of last session)
    /// to keep the prompt short.
    private static func detectPlateaus(from completed: [WorkoutSession]) -> [AICoachContext.PlateauHint] {
        let now = Date()
        let fourWeeks: TimeInterval = 28 * 24 * 3600
        let recentCutoff = now.addingTimeInterval(-fourWeeks)
        let priorCutoff = now.addingTimeInterval(-2 * fourWeeks)

        // Group: exercise name → [(date, score, weight, reps)] across all weighted sets.
        struct Entry { let date: Date; let score: Double; let weight: Double; let reps: Int }
        var byExercise: [String: [Entry]] = [:]

        for session in completed where session.date >= priorCutoff {
            let bestPerExercise = session.sets
                .filter { $0.isCompleted && $0.weight > 0 && $0.reps > 0 }
                .reduce(into: [String: Entry]()) { acc, set in
                    let score = set.weight * Double(set.reps)
                    let entry = Entry(date: session.date, score: score, weight: set.weight, reps: set.reps)
                    if let prev = acc[set.exerciseName], prev.score >= score { return }
                    acc[set.exerciseName] = entry
                }
            for (name, entry) in bestPerExercise {
                byExercise[name, default: []].append(entry)
            }
        }

        var hints: [AICoachContext.PlateauHint] = []
        for (name, entries) in byExercise {
            guard entries.count >= 3 else { continue }

            let recent = entries.filter { $0.date >= recentCutoff }
            let prior  = entries.filter { $0.date <  recentCutoff }
            guard let bestPrior = prior.max(by: { $0.score < $1.score }),
                  let bestRecent = recent.max(by: { $0.score < $1.score }) else { continue }

            // Recent must not exceed prior best — otherwise progression is fine.
            guard bestRecent.score <= bestPrior.score else { continue }

            // Best result must be at least two weeks old.
            let mostRecentBest = (recent + prior).max(by: { $0.score < $1.score })?.date ?? bestPrior.date
            guard now.timeIntervalSince(mostRecentBest) >= 14 * 24 * 3600 else { continue }

            let weeksStuck = Int(now.timeIntervalSince(mostRecentBest) / (7 * 24 * 3600))
            hints.append(.init(
                exerciseName: name,
                topWeightKg: bestPrior.weight,
                topReps: bestPrior.reps,
                weeksStuck: weeksStuck,
                sessionsStuck: recent.count
            ))
        }

        // Sort by recency of any session in last 4 weeks (most-active plateaus first).
        hints.sort { lhs, rhs in
            let lhsDate = byExercise[lhs.exerciseName]?.map(\.date).max() ?? .distantPast
            let rhsDate = byExercise[rhs.exerciseName]?.map(\.date).max() ?? .distantPast
            return lhsDate > rhsDate
        }
        return Array(hints.prefix(3))
    }

    // MARK: - Rendering to plain text for the model

    /// Compact, deterministic string the model can read at a glance.
    static func renderForPrompt(_ ctx: AICoachContext) -> String {
        var out: [String] = []
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        let dfDay = DateFormatter()
        dfDay.dateFormat = "yyyy-MM-dd"

        // Profile
        if let p = ctx.profile {
            out.append("USER: age \(p.age), height \(Int(p.heightCm)) cm, weight \(String(format: "%.1f", p.weightKg)) kg.")
        }

        // Weight trend
        if let w = ctx.weightTrend {
            var bits = ["current \(String(format: "%.1f", w.currentKg)) kg"]
            if let week = w.weekAgoKg {
                let delta = w.currentKg - week
                bits.append(String(format: "Δ7d %+.1f", delta))
            }
            if let month = w.monthAgoKg {
                let delta = w.currentKg - month
                bits.append(String(format: "Δ30d %+.1f", delta))
            }
            out.append("WEIGHT: " + bits.joined(separator: ", ") + ".")
        }

        // Body measurements
        if !ctx.measurements.isEmpty {
            let bits = ctx.measurements.map { "\($0.typeName) \(String(format: "%.1f", $0.valueCm))cm" }
            out.append("MEASUREMENTS (latest): " + bits.joined(separator: "; ") + ".")
        }

        // Aggregate stats
        let s = ctx.stats
        var statBits: [String] = []
        statBits.append("total \(s.totalCompletedWorkouts) workouts")
        statBits.append("this week \(s.workoutsThisWeek)")
        statBits.append(String(format: "avg %.1f/wk (4w)", s.avgWorkoutsPerWeekLast4Weeks))
        statBits.append("vol30d \(Int(s.totalVolumeLast30Days)) kg·rep")
        statBits.append("longest streak \(s.longestStreakDays)d")
        statBits.append("current streak \(s.currentStreakDays)d")
        out.append("STATS: " + statBits.joined(separator: "; ") + ".")

        // Streak commentary hint — only when the streak is actually meaningful.
        // The model is told to weave this into its tone naturally (celebrate
        // milestones, use the streak as motivation, etc.).
        if s.currentStreakDays >= 3 {
            let near: String
            switch s.currentStreakDays {
            case 4:           near = "one day from a 5-day streak"
            case 6:           near = "one day from a week-long streak"
            case 9, 13:       near = "close to the next milestone (\(s.currentStreakDays + 1))"
            default:          near = ""
            }
            out.append("STREAK NOTE: user has a live \(s.currentStreakDays)-day streak\(near.isEmpty ? "" : " — \(near)"). Acknowledge it briefly without making it the whole reply.")
        }

        // Plateau hints — drive deload / variation suggestions.
        if !ctx.plateaus.isEmpty {
            let lines = ctx.plateaus.map { p -> String in
                "• \(p.exerciseName): stuck \(p.weeksStuck)w (\(p.sessionsStuck) sessions); top \(String(format: "%.1f", p.topWeightKg))kg × \(p.topReps)"
            }
            out.append("PLATEAU SIGNALS — propose a concrete deload, tempo change, range tweak or accessory swap for these:\n" + lines.joined(separator: "\n"))
        }

        // Sensors
        var healthBits: [String] = []
        if let r = ctx.health.restingHeartRate { healthBits.append("resting HR \(r) bpm") }
        if let s = ctx.health.last7DaysSteps { healthBits.append("steps 7d: \(s)") }
        if let w = ctx.health.last7DaysWorkouts { healthBits.append("workouts 7d (HK): \(w)") }
        if let n = ctx.health.lastNightSleepHours { healthBits.append(String(format: "sleep last night: %.1f h", n)) }
        if let a = ctx.health.weeklySleepAvgHours { healthBits.append(String(format: "sleep avg 7d: %.1f h", a)) }
        if !healthBits.isEmpty {
            out.append("SENSORS: " + healthBits.joined(separator: "; ") + ".")
        }

        // Active program (the planned routine)
        if let p = ctx.program {
            var head = "ACTIVE PROGRAM: \"\(p.name)\""
            if let desc = p.description { head += " — \(desc)" }
            head += " · started \(p.startedDaysAgo) days ago"
            if p.isUserModified { head += " · user-modified" }
            if let cur = p.currentDayName { head += " · today's day: \(cur)" }
            out.append(head)

            for day in p.days {
                let typeTag = day.workoutType
                let exTexts = day.exercises.map { e -> String in
                    if e.workoutType != typeTag {
                        return "\(e.name) ×\(e.plannedSets) [\(e.workoutType)]"
                    } else {
                        return "\(e.name) ×\(e.plannedSets)"
                    }
                }.joined(separator: ", ")
                out.append("  · Day \(day.orderIndex + 1) \"\(day.name)\" [\(typeTag), rest \(day.defaultRestSec)s]: \(exTexts.isEmpty ? "—" : exTexts)")
            }
        } else {
            out.append("ACTIVE PROGRAM: none.")
        }

        // Recent workouts (most recent first; first one is the just-finished session)
        if ctx.workouts.isEmpty {
            out.append("RECENT WORKOUTS: empty (this is the first session).")
        } else {
            out.append("RECENT WORKOUTS (newest → oldest, up to \(ctx.workouts.count)):")
            for (idx, w) in ctx.workouts.enumerated() {
                if idx == 0 {
                    renderFullWorkout(w, label: "T0", df: dfDay, into: &out)
                } else {
                    renderCompactWorkout(w, label: "T-\(idx)", df: dfDay, into: &out)
                }
            }
        }

        return out.joined(separator: "\n")
    }

    // MARK: - Workout rendering tiers

    /// Full detail — set-by-set, every comment preserved. Used for the
    /// just-finished session that we're actively analysing.
    private static func renderFullWorkout(_ w: AICoachContext.WorkoutSummary,
                                          label: String,
                                          df: DateFormatter,
                                          into out: inout [String]) {
        var head = "[\(label) JUST_NOW] \(df.string(from: w.date)) — \(w.dayName)"
        if let d = w.durationMinutes { head += " · \(d)m" }
        if let hr = w.averageHeartRate { head += " · HR \(hr)" }
        if let c = w.calories { head += " · \(c)kcal" }
        head += " · vol \(Int(w.totalVolume)) · \(w.completedSets)/\(w.totalSets)"
        out.append(head)

        for ex in w.exercises {
            let setStrs = ex.sets.map { s -> String in
                var base = "\(s.setNumber):\(formatWeight(s.weight))×\(s.reps)"
                if !s.isCompleted { base += "✗" }
                if let c = s.comment { base += " «\(c)»" }
                return base
            }
            out.append("  • \(ex.name): " + setStrs.joined(separator: ", "))
        }
        if let n = w.notes {
            out.append("  note: «\(n)»")
        }
    }

    /// Compact format — exercises collapsed to grouped weight×reps notation,
    /// comments dropped unless they look like a pain/injury signal.
    /// Designed so each older workout fits in ~5 lines / ~120 tokens.
    private static func renderCompactWorkout(_ w: AICoachContext.WorkoutSummary,
                                             label: String,
                                             df: DateFormatter,
                                             into out: inout [String]) {
        var head = "[\(label)] \(df.string(from: w.date)) \(w.dayName)"
        if let d = w.durationMinutes { head += " \(d)m" }
        head += " vol \(Int(w.totalVolume)) \(w.completedSets)/\(w.totalSets)"
        out.append(head)

        for ex in w.exercises {
            let body = compactSets(ex.sets)
            // Pull only pain-signal comments; everything else is dropped to save tokens.
            let painSignals = ex.sets.compactMap { $0.comment }.filter { containsPainSignal($0) }
            if painSignals.isEmpty {
                out.append("  \(ex.name): \(body)")
            } else {
                let cmt = painSignals.joined(separator: " | ")
                out.append("  \(ex.name): \(body) ⚠«\(cmt)»")
            }
        }
        if let n = w.notes, containsPainSignal(n) {
            out.append("  ⚠note: «\(n)»")
        }
    }

    /// Groups consecutive same-weight sets into "weight×r1/r2/r3" notation
    /// and joins with commas. Skips incomplete sets entirely (they bloat
    /// the prompt and the just-finished session already shows them in full).
    private static func compactSets(_ sets: [AICoachContext.SetSummary]) -> String {
        let done = sets.filter { $0.isCompleted }
        guard !done.isEmpty else { return "—" }

        // Walk in order, batch contiguous runs of identical weight.
        var groups: [(weight: Double, reps: [Int])] = []
        for s in done {
            if let last = groups.last, last.weight == s.weight {
                groups[groups.count - 1].reps.append(s.reps)
            } else {
                groups.append((weight: s.weight, reps: [s.reps]))
            }
        }
        return groups.map { g -> String in
            "\(formatWeight(g.weight))×\(g.reps.map(String.init).joined(separator: "/"))"
        }.joined(separator: ", ")
    }

    /// Keyword check — keeps it cheap; the goal is "don't lose pain context",
    /// false positives are tolerable.
    private static func containsPainSignal(_ text: String) -> Bool {
        let lc = text.lowercased()
        let needles = [
            // RU
            "боль", "болит", "болит ", "ноет", "защем", "прострел",
            "щёлк", "щелк", "хруст", "тянет", "травм", "болезн",
            "температур", "плохо себя",
            // EN
            "pain", "hurt", "ache", "sore", "tight", "sharp",
            "pinched", "injur", "ill", "fever"
        ]
        return needles.contains { lc.contains($0) }
    }

    private static func formatWeight(_ w: Double) -> String {
        if w == 0 { return "bw" }  // "bodyweight"
        if w.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(w))" }
        return String(format: "%.1f", w)
    }
}

private extension String {
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}
