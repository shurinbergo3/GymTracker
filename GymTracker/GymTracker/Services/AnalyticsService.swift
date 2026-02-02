import Foundation
import SwiftData

/// Stateless service for analytics calculations.
/// Adheres to Single Responsibility Principle (SRP).
struct AnalyticsService {
    
    // MARK: - Progress Comparison
    
    /// Compares two sessions for a specific exercise to determine progress.
    static func comparePerformance(
        exercise: ExerciseTemplate,
        currentSession: WorkoutSession,
        previousSession: WorkoutSession?
    ) -> ProgressState {
        guard let previousSession = previousSession else {
            return .new
        }
        
        let currentSets = currentSession.sets.filter { $0.exerciseName == exercise.name }
        let previousSets = previousSession.sets.filter { $0.exerciseName == exercise.name }
        
        guard !currentSets.isEmpty else { return .new }
        guard !previousSets.isEmpty else { return .new }
        
        // Calculate Total Volume for accurate "Growth" vs "Reference" comparison
        let currentVolume = currentSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        let previousVolume = previousSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        
        // Logic:
        // Green (Improved): Increased Volume OR Max Weight
        // White (Same): Roughly the same volume (within small margin/maintenance) or slightly less but acceptable
        // Red (Declined): Significantly less volume/weight (e.g. < 90% of previous)
        
        if currentVolume > previousVolume {
             return .improved // Active growth
        }
        
        // Check for slight decrease or equal (Maintenance) -> White Arrow
        // If current volume is at least 90% of previous, consider it maintenance/neutral
        if currentVolume >= (previousVolume * 0.9) {
            return .same
        }
        
        // Otherwise it's a significant drop -> Red Arrow
        return .declined
    }
    
    // MARK: - Get Progress Data
    
    static func getProgressData(
        for session: WorkoutSession,
        comparedTo previousSession: WorkoutSession?,
        workoutDay: WorkoutDay
    ) -> [ExerciseProgress] {
        
        return workoutDay.exercises.sorted { $0.orderIndex < $1.orderIndex }.compactMap { exercise in
            let currentSets = session.sets.filter { $0.exerciseName == exercise.name }
            let previousSets = previousSession?.sets.filter { $0.exerciseName == exercise.name } ?? []
            
            guard !currentSets.isEmpty else { return nil }
            
            let progressState = comparePerformance(
                exercise: exercise,
                currentSession: session,
                previousSession: previousSession
            )
            
            // Format current stats
            let maxWeight = currentSets.map { $0.weight }.max() ?? 0
            let currentStats = String(format: "%.0f кг", maxWeight)
            
            // Format previous stats
            var previousStats: String?
            if !previousSets.isEmpty {
                let prevMaxWeight = previousSets.map { $0.weight }.max() ?? 0
                previousStats = String(format: "%.0f кг", prevMaxWeight)
            }
            
            return ExerciseProgress(
                exerciseName: exercise.name,
                progressState: progressState,
                currentStats: currentStats,
                previousStats: previousStats
            )
        }
    }
    
    static func getPreviewProgressData(
        workoutDay: WorkoutDay,
        previousSession: WorkoutSession?
    ) -> [ExerciseProgress] {
        guard let previousSession = previousSession else {
            // No previous data - return empty state
            return []
        }
        
        return workoutDay.exercises.sorted { $0.orderIndex < $1.orderIndex }.compactMap { exercise in
            let previousSets = previousSession.sets.filter { $0.exerciseName == exercise.name }
            
            guard !previousSets.isEmpty else { return nil }
            
            let maxWeight = previousSets.map { $0.weight }.max() ?? 0
            let stats = String(format: "%.0f кг", maxWeight)
            
            return ExerciseProgress(
                exerciseName: exercise.name,
                progressState: .same, // No current session to compare
                currentStats: stats,
                previousStats: nil
            )
        }
    }
    
    // MARK: - Growth Analysis
    
    static func calculateGrowthTrend(history: [WorkoutSession]) -> GrowthTrend {
        // We analyze the Volume (Weight * Reps) of the last 10 workouts
        let recentSessions = history.sorted { $0.date < $1.date }.suffix(10)
        
        guard recentSessions.count >= 2 else {
            return GrowthTrend(direction: .flat, dataPoints: [])
        }
        
        let volumes = recentSessions.map { session -> Double in
            let sessionVolume = session.sets.reduce(0.0) { result, set in
                // Logic: Volume = Weight * Reps.
                // For Bodyweight (weight=0) we assume 1 "unit" of weight per rep to track reps volume.
                // For Duration, we use duration seconds / 10 as "volume" points.
                if set.weight > 0 {
                    return result + (set.weight * Double(set.reps))
                } else if set.reps > 0 {
                    return result + Double(set.reps * (set.isWeighted ? 2 : 1)) // Weighted BW counts double? Simplified.
                } else if let dur = set.duration {
                    return result + (dur / 10.0)
                }
                return result
            }
            return sessionVolume
        }
        
        // Simple Trend Analysis: Recent Avg vs Previous Avg
        let half = volumes.count / 2
        let firstHalf = volumes.prefix(half)
        let secondHalf = volumes.suffix(from: half)
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let direction: GrowthTrend.Direction
        
        if secondAvg > firstAvg * 1.05 { // > 5% growth
            direction = .up
        } else if secondAvg < firstAvg * 0.95 { // < 5% decline
            direction = .down
        } else {
            direction = .flat
        }
        
        return GrowthTrend(direction: direction, dataPoints: volumes)
    }
}
