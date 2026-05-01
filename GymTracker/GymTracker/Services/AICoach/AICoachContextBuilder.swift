//
//  AICoachContextBuilder.swift
//  GymTracker
//
//  Builds a compact, model-friendly context block describing the user's
//  recent training, sensor data, comments and profile. The output is
//  embedded into the first user message of every cycle.
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

    let profile: ProfileSummary?
    let workouts: [WorkoutSummary]   // most recent first
    let health: HealthSummary
    let userLocaleIdentifier: String
}

@MainActor
enum AICoachContextBuilder {

    /// Pulls the last `limit` completed workouts from SwiftData + sensor data
    /// from HealthKit and packs them into an `AICoachContext`.
    static func build(modelContext: ModelContext,
                      healthManager: HealthManager,
                      limit: Int = 4) async -> AICoachContext {

        // --- Workouts ----------------------------------------------------
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let sessions = (try? modelContext.fetch(descriptor)) ?? []

        let workouts: [AICoachContext.WorkoutSummary] = sessions.map { session in
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

        // --- Profile -----------------------------------------------------
        let profile: AICoachContext.ProfileSummary?
        let profDescriptor = FetchDescriptor<UserProfile>()
        if let p = try? modelContext.fetch(profDescriptor).last {
            profile = .init(age: p.age, heightCm: p.height, weightKg: p.currentWeight)
        } else {
            profile = nil
        }

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
            userLocaleIdentifier: LanguageManager.shared.currentLocale.identifier
        )
    }

    // MARK: - Rendering to plain text for the model

    /// Compact, deterministic string the model can read at a glance.
    static func renderForPrompt(_ ctx: AICoachContext) -> String {
        var out: [String] = []
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"

        // Profile
        if let p = ctx.profile {
            out.append("ПОЛЬЗОВАТЕЛЬ: возраст \(p.age) лет, рост \(Int(p.heightCm)) см, вес \(String(format: "%.1f", p.weightKg)) кг.")
        }

        // Health
        var healthBits: [String] = []
        if let r = ctx.health.restingHeartRate { healthBits.append("ЧСС покоя \(r) уд/мин") }
        if let s = ctx.health.last7DaysSteps { healthBits.append("шагов за 7 дней: \(s)") }
        if let w = ctx.health.last7DaysWorkouts { healthBits.append("тренировок за 7 дней: \(w)") }
        if let n = ctx.health.lastNightSleepHours { healthBits.append("сон прошлой ночью: \(String(format: "%.1f", n)) ч") }
        if let a = ctx.health.weeklySleepAvgHours { healthBits.append("средний сон за 7 дней: \(String(format: "%.1f", a)) ч") }
        if !healthBits.isEmpty {
            out.append("ДАТЧИКИ: " + healthBits.joined(separator: "; ") + ".")
        }

        // Workouts (most recent first; first one is the just-finished session)
        if ctx.workouts.isEmpty {
            out.append("ИСТОРИЯ ТРЕНИРОВОК: пусто (это первая тренировка).")
        } else {
            out.append("ПОСЛЕДНИЕ ТРЕНИРОВКИ (от свежей к старой, до 4 шт.):")
            for (idx, w) in ctx.workouts.enumerated() {
                let label = idx == 0 ? "ТОЛЬКО ЧТО" : "T-\(idx)"
                var head = "[\(label)] \(df.string(from: w.date)) — \(w.dayName)"
                if let prog = w.programName { head += " · \(prog)" }
                if let d = w.durationMinutes { head += " · \(d) мин" }
                if let c = w.calories { head += " · \(c) ккал" }
                if let hr = w.averageHeartRate { head += " · ЧСС ср. \(hr)" }
                head += " · объём \(Int(w.totalVolume)) кг·повт · подходов \(w.completedSets)/\(w.totalSets)"
                out.append(head)

                for ex in w.exercises {
                    let setStrs = ex.sets.map { s -> String in
                        var base = "\(s.setNumber): \(formatWeight(s.weight))×\(s.reps)"
                        if !s.isCompleted { base += " (не завершён)" }
                        if let c = s.comment { base += " «\(c)»" }
                        return base
                    }
                    out.append("  • \(ex.name) — " + setStrs.joined(separator: "; "))
                }
                if let n = w.notes {
                    out.append("  Комментарий к тренировке: «\(n)»")
                }
            }
        }

        return out.joined(separator: "\n")
    }

    private static func formatWeight(_ w: Double) -> String {
        if w == 0 { return "0" }
        if w.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(w))" }
        return String(format: "%.1f", w)
    }
}

private extension String {
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}
