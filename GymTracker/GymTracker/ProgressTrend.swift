//
//  ProgressTrend.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import Foundation

// MARK: - Progress Trend Analysis
//
// Algorithm: per-exercise progressive overload tracking.
// For each exercise the user has performed often enough in the last 8 weeks,
// we score each session by its best set using estimated 1RM (Epley:
// e1RM = weight * (1 + reps/30)). For bodyweight reps-only and duration
// exercises we fall back to max reps / max duration.
// We compare the best score in the recent half (last 4 weeks) vs the prior
// half (4-8 weeks ago) and label each exercise up / flat / down. The overall
// trend aggregates the per-exercise directions.
//
// This captures real progressive overload: heavier weights AND/OR more reps
// move e1RM up. Skipping a workout, deloads, or switching rep schemes don't
// poison the score because comparison is per-exercise across windows.

enum ProgressTrend {
    case surge      // Most exercises growing
    case growth     // Steady per-exercise progression
    case maintenance // Holding ground / not enough data
    case decline    // Several exercises stalling
    case loss       // Long inactivity or widespread regression

    // MARK: - UI Properties

    var icon: String {
        switch self {
        case .surge: return "arrow.up"
        case .growth: return "arrow.up.forward"
        case .maintenance: return "arrow.forward"
        case .decline: return "arrow.down.forward"
        case .loss: return "arrow.down"
        }
    }

    var rotation: Double {
        switch self {
        case .surge: return 0
        case .growth: return -45
        case .maintenance: return 0
        case .decline: return 45
        case .loss: return 0
        }
    }

    var color: Color {
        switch self {
        case .surge: return DesignSystem.Colors.neonGreen
        case .growth: return Color.green.opacity(0.7)
        case .maintenance: return Color.white.opacity(0.6)
        case .decline: return Color.orange
        case .loss: return Color.red
        }
    }

    var title: String {
        switch self {
        case .surge: return "Мощный рост!".localized()
        case .growth: return "Стабильный прогресс".localized()
        case .maintenance: return "Удержание формы".localized()
        case .decline: return "Снижение тонуса".localized()
        case .loss: return "Критический спад".localized()
        }
    }

    var subtitle: String {
        switch self {
        case .surge: return "Большинство упражнений растут".localized()
        case .growth: return "Веса или повторения растут".localized()
        case .maintenance: return "Для роста повысьте нагрузку".localized()
        case .decline: return "Несколько упражнений просели".localized()
        case .loss: return "Начните с восстановления".localized()
        }
    }

    // MARK: - Per-Exercise Breakdown

    enum Direction {
        case up, flat, down

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .flat: return "arrow.right"
            case .down: return "arrow.down.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return DesignSystem.Colors.neonGreen
            case .flat: return Color.white.opacity(0.5)
            case .down: return Color.orange
            }
        }
    }

    enum ScoreUnit {
        case e1RM        // strength: kg-equivalent estimated 1RM
        case reps        // bodyweight reps-only
        case duration    // seconds

        var localizedSuffix: String {
            switch self {
            case .e1RM: return "кг".localized()
            case .reps: return "повт.".localized()
            case .duration: return "сек".localized()
            }
        }
    }

    struct ExerciseProgress: Identifiable {
        let id = UUID()
        let exerciseName: String
        let direction: Direction
        let percentChange: Double
        let recentBest: Double
        let priorBest: Double
        let unit: ScoreUnit
    }

    struct Breakdown {
        let trend: ProgressTrend
        let exercises: [ExerciseProgress]   // sorted: best growth → worst regression
        let growing: Int
        let stable: Int
        let declining: Int
        let inactiveDays: Int
        let isInsufficientData: Bool

        var totalTracked: Int { growing + stable + declining }
    }

    // MARK: - Calculation

    /// Backwards-compatible single-trend API (used by dashboard banner).
    static func calculate(from sessions: [WorkoutSession]) -> ProgressTrend {
        analyze(from: sessions).trend
    }

    /// Full breakdown with per-exercise progression details.
    static func analyze(from sessions: [WorkoutSession]) -> Breakdown {
        let now = Date()
        let calendar = Calendar.current
        let completed = sessions.filter { $0.isCompleted }

        let lastDate = completed.map { $0.date }.max() ?? .distantPast
        let daysInactive = calendar.dateComponents([.day], from: lastDate, to: now).day ?? Int.max

        if completed.isEmpty {
            return Breakdown(
                trend: .maintenance,
                exercises: [],
                growing: 0, stable: 0, declining: 0,
                inactiveDays: daysInactive,
                isInsufficientData: true
            )
        }

        // Inactivity overrides trend (preserve prior behavior).
        if daysInactive >= 50 {
            return Breakdown(
                trend: .loss,
                exercises: [],
                growing: 0, stable: 0, declining: 0,
                inactiveDays: daysInactive,
                isInsufficientData: false
            )
        }
        if daysInactive >= 21 {
            return Breakdown(
                trend: .maintenance,
                exercises: [],
                growing: 0, stable: 0, declining: 0,
                inactiveDays: daysInactive,
                isInsufficientData: false
            )
        }

        let recentCutoff = calendar.date(byAdding: .weekOfYear, value: -4, to: now) ?? now
        let priorCutoff = calendar.date(byAdding: .weekOfYear, value: -8, to: now) ?? now
        let inWindow = completed.filter { $0.date >= priorCutoff }

        // Group sets by exercise across sessions in the 8-week window.
        var perExercise: [String: [(date: Date, score: Double, unit: ScoreUnit)]] = [:]

        for session in inWindow {
            let groups = Dictionary(grouping: session.sets) { $0.exerciseName }
            for (rawName, sets) in groups {
                let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }

                let strengthSets = sets.filter { $0.weight > 0 && $0.reps > 0 }
                let repsOnlySets = sets.filter { $0.weight == 0 && $0.reps > 0 }
                let durationSets = sets.filter { ($0.duration ?? 0) > 0 }

                let unit: ScoreUnit
                let score: Double

                if !strengthSets.isEmpty {
                    unit = .e1RM
                    score = strengthSets
                        .map { $0.weight * (1.0 + Double($0.reps) / 30.0) }
                        .max() ?? 0
                } else if !repsOnlySets.isEmpty {
                    unit = .reps
                    score = Double(repsOnlySets.map { $0.reps }.max() ?? 0)
                } else if !durationSets.isEmpty {
                    unit = .duration
                    score = durationSets.compactMap { $0.duration }.max() ?? 0
                } else {
                    continue
                }

                guard score > 0 else { continue }
                perExercise[name, default: []].append((session.date, score, unit))
            }
        }

        var progresses: [ExerciseProgress] = []
        var growing = 0, stable = 0, declining = 0

        for (name, entries) in perExercise {
            // Need at least 3 sessions in the 8-week window to be a tracked exercise.
            guard entries.count >= 3 else { continue }

            let recent = entries.filter { $0.date >= recentCutoff }
            let prior = entries.filter { $0.date < recentCutoff }

            // Need data in both halves to compute a trend.
            guard !recent.isEmpty, !prior.isEmpty else { continue }

            let recentBest = recent.map { $0.score }.max() ?? 0
            let priorBest = prior.map { $0.score }.max() ?? 0
            guard priorBest > 0 else { continue }

            let pct = (recentBest - priorBest) / priorBest * 100.0
            let unit = entries.last?.unit ?? .e1RM

            let direction: Direction
            if pct > 2 {
                direction = .up; growing += 1
            } else if pct < -2 {
                direction = .down; declining += 1
            } else {
                direction = .flat; stable += 1
            }

            progresses.append(ExerciseProgress(
                exerciseName: name,
                direction: direction,
                percentChange: pct,
                recentBest: recentBest,
                priorBest: priorBest,
                unit: unit
            ))
        }

        let sorted = progresses.sorted { $0.percentChange > $1.percentChange }
        let total = growing + stable + declining

        // Not enough exercises tracked yet — show a soft "keep going" state.
        if total < 2 {
            return Breakdown(
                trend: .maintenance,
                exercises: sorted,
                growing: growing, stable: stable, declining: declining,
                inactiveDays: daysInactive,
                isInsufficientData: true
            )
        }

        let upRatio = Double(growing) / Double(total)
        let downRatio = Double(declining) / Double(total)

        let trend: ProgressTrend
        if downRatio >= 0.5 {
            trend = .loss
        } else if upRatio >= 0.6 {
            trend = .surge
        } else if downRatio >= 0.3 && upRatio < 0.3 {
            trend = .decline
        } else if upRatio >= 0.3 && downRatio < 0.3 {
            trend = .growth
        } else {
            trend = .maintenance
        }

        return Breakdown(
            trend: trend,
            exercises: sorted,
            growing: growing, stable: stable, declining: declining,
            inactiveDays: daysInactive,
            isInsufficientData: false
        )
    }
}

// MARK: - Set-level progression helpers
// Used by the active-workout card to show per-set comparison vs previous workout.

enum SetProgression {
    case better      // current set's e1RM > prior set's e1RM
    case same        // ~equal
    case worse       // current set's e1RM < prior set's e1RM
    case noBaseline  // no comparable prior set

    var icon: String {
        switch self {
        case .better: return "arrow.up.right"
        case .same: return "equal"
        case .worse: return "arrow.down.right"
        case .noBaseline: return "sparkle"
        }
    }

    var color: Color {
        switch self {
        case .better: return DesignSystem.Colors.neonGreen
        case .same: return Color.white.opacity(0.5)
        case .worse: return Color.orange
        case .noBaseline: return Color.white.opacity(0.4)
        }
    }

    /// Compare a set against an optional prior set using e1RM (or reps / duration fallback).
    static func compare(current: WorkoutSet, prior: WorkoutSet?) -> SetProgression {
        guard let prior else { return .noBaseline }
        let cur = score(for: current)
        let prv = score(for: prior)
        guard cur > 0, prv > 0 else { return .noBaseline }
        let pct = (cur - prv) / prv * 100.0
        if pct > 1 { return .better }
        if pct < -1 { return .worse }
        return .same
    }

    private static func score(for set: WorkoutSet) -> Double {
        if set.weight > 0 && set.reps > 0 {
            return set.weight * (1.0 + Double(set.reps) / 30.0)
        }
        if set.reps > 0 {
            return Double(set.reps)
        }
        return set.duration ?? 0
    }
}
