//
//  PersonalRecordsService.swift
//  GymTracker
//
//  Detects per-exercise personal records using "best weight at each rep count" rule
//  and suggests an achievable next PR target.
//

import Foundation

struct PersonalRecord: Identifiable, Hashable {
    let id: UUID
    let exerciseName: String
    let weight: Double
    let reps: Int
    let date: Date
    /// Previous best weight at the SAME rep count (0 if this is the first set ever at that rep count).
    let previousBestWeight: Double

    init(exerciseName: String, weight: Double, reps: Int, date: Date, previousBestWeight: Double) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.date = date
        self.previousBestWeight = previousBestWeight
    }

    /// True when no previous set existed at this rep count (treat as a fresh PR, not "improvement").
    var isFirstAtReps: Bool { previousBestWeight == 0 }

    /// Improvement in kg over the previous best at the same rep count. 0 if first.
    var improvementKg: Double {
        max(0, weight - previousBestWeight)
    }
}

struct PRTarget: Hashable {
    let exerciseName: String
    let baseWeight: Double
    let baseReps: Int
    let targetReps: Int
}

enum PersonalRecordsService {

    /// Walks all sets in chronological order and records a PR every time a (weight, reps)
    /// combo strictly beats the prior best weight at that rep count for that exercise.
    /// Returns newest PRs first, capped at `limit`.
    static func recentPRs(from sessions: [WorkoutSession], limit: Int = 10) -> [PersonalRecord] {
        let completed = sessions.filter { $0.isCompleted }.sorted { $0.date < $1.date }
        var bestAtReps: [String: [Int: Double]] = [:]
        var prs: [PersonalRecord] = []

        for session in completed {
            let sortedSets = session.sets.sorted { $0.setNumber < $1.setNumber }
            for set in sortedSets where set.weight > 0 && set.reps > 0 {
                let name = set.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                let prev = bestAtReps[name]?[set.reps] ?? 0
                if set.weight > prev {
                    prs.append(PersonalRecord(
                        exerciseName: name,
                        weight: set.weight,
                        reps: set.reps,
                        date: session.date,
                        previousBestWeight: prev
                    ))
                    bestAtReps[name, default: [:]][set.reps] = set.weight
                }
            }
        }

        return Array(prs.reversed().prefix(limit))
    }

    /// Picks the user's heaviest set from the most recent session in the last 4 weeks
    /// and suggests "+1 rep at the same weight" as the next target.
    /// Returns nil if no suitable target exists (e.g. no recent strength sets, or target already beaten).
    static func nextTarget(from sessions: [WorkoutSession]) -> PRTarget? {
        let now = Date()
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .weekOfYear, value: -4, to: now) else { return nil }

        let allCompleted = sessions.filter { $0.isCompleted }
        var bestAtReps: [String: [Int: Double]] = [:]
        for session in allCompleted {
            for set in session.sets where set.weight > 0 && set.reps > 0 {
                let name = set.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                let prev = bestAtReps[name]?[set.reps] ?? 0
                if set.weight > prev {
                    bestAtReps[name, default: [:]][set.reps] = set.weight
                }
            }
        }

        let recentSessions = allCompleted
            .filter { $0.date >= cutoff }
            .sorted { $0.date > $1.date }

        for session in recentSessions {
            let strengthSets = session.sets.filter { $0.weight > 0 && $0.reps > 0 }
            guard let heaviest = strengthSets.max(by: { lhs, rhs in
                if lhs.weight != rhs.weight { return lhs.weight < rhs.weight }
                return lhs.reps < rhs.reps
            }) else { continue }

            let name = heaviest.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            let targetReps = heaviest.reps + 1
            let prevBestAtTarget = bestAtReps[name]?[targetReps] ?? 0
            // Suggest only when current weight beats the prior best at target reps.
            if heaviest.weight > prevBestAtTarget {
                return PRTarget(
                    exerciseName: name,
                    baseWeight: heaviest.weight,
                    baseReps: heaviest.reps,
                    targetReps: targetReps
                )
            }
        }
        return nil
    }
}
