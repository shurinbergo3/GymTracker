//
//  WorkoutManager.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import HealthKit

// MARK: - Workout State

enum WorkoutState {
    case idle       // Dashboard - ready to start
    case countdown  // 3-2-1 Countdown
    case active     // Workout in progress
    case summary    // Finished, showing results
}

// MARK: - Progress State

enum ProgressState {
    case improved   // User lifted more weight
    case declined   // User lifted less weight
    case same       // Same performance
    case new        // First time doing this exercise
    
    var icon: String {
        switch self {
        case .improved: return "arrow.up" // Green Up
        case .declined: return "arrow.down" // Red Down
        case .same: return "arrow.forward" // White Straight
        case .new: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .improved: return DesignSystem.Colors.neonGreen
        case .declined: return .red // Explicit Red
        case .same: return .white // Explicit White
        case .new: return DesignSystem.Colors.accent
        }
    }

    var description: String {
        switch self {
        case .improved: return "Ты растёшь! Только вперёд!"
        case .declined: return "Ты недостаточно усердно тренируешься"
        case .same: return "Ты в режиме поддержания формы"
        case .new: return "Первая тренировка"
        }
    }
}

// MARK: - Exercise Progress Data

struct ExerciseProgress {
    let exerciseName: String
    let progressState: ProgressState
    let currentStats: String
    let previousStats: String?
}

// MARK: - Growth Trend System

struct GrowthTrend {
    enum Direction {
        case up     // Green: Increasing load/volume
        case flat   // White: Maintenance
        case down   // Red: Decreasing
        
        var color: Color {
            switch self {
            case .up: return DesignSystem.Colors.neonGreen
            case .flat: return .white
            case .down: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.forward"
            case .flat: return "arrow.right"
            case .down: return "arrow.down.forward"
            }
        }
        
        var description: String {
            switch self {
            case .up: return "Рост показателей"
            case .flat: return "Стабильность"
            case .down: return "Спад активности"
            }
        }
    }
    
    let direction: Direction
    let dataPoints: [Double]
}

// MARK: - Workout Manager

@MainActor
class WorkoutManager: ObservableObject {
    @Published var selectedDay: WorkoutDay?
    @Published var workoutState: WorkoutState = .idle
    @Published var currentSession: WorkoutSession?
    @Published var activeProgram: Program?
    
    // Live Stats
    @Published var currentHeartRate: Int = 0
    @Published var currentActiveCalories: Int = 0
    
    private var liveActivityTimer: Timer?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadActiveProgram()
        initializeSelectedDay()
        
        // Listen for active program changes
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ActiveProgramChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.refreshActiveProgram()
            }
        }
        
        
        restoreActiveSession()
        
        requestHealthAccess()
    }
    
    // MARK: - Initialization
    
    func restoreActiveSession() {
        // Look for incomplete session
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == false },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let session = try? modelContext.fetch(descriptor).first {
            // Check for stale session (older than 24 hours)
            let timeSinceStart = Date().timeIntervalSince(session.date)
            if timeSinceStart > 86400 { // 24 hours in seconds
                print("Found stale session from \(session.date). Deleting.")
                modelContext.delete(session)
                try? modelContext.save()
                return 
            }
            
            // Restore state if valid
            currentSession = session
            workoutState = .active
            
            // Try to match selectedDay if possible (active program)
            if let program = activeProgram {
                 selectedDay = program.days.first(where: { $0.name == session.workoutDayName })
            }
            
            // Resume live data fetch
            startActivityUpdates(startDate: session.date)
        }
    }
    
    func loadActiveProgram() {
        let descriptor = FetchDescriptor<Program>(
            predicate: #Predicate { $0.isActive == true }
        )
        activeProgram = try? modelContext.fetch(descriptor).first
    }
    
    func refreshActiveProgram() {
        loadActiveProgram()
        initializeSelectedDay()
    }
    
    func initializeSelectedDay() {
        selectedDay = activeProgram?.currentWorkoutDay()
    }
    
    // MARK: - Day Selection
    
    func selectDay(_ day: WorkoutDay) {
        selectedDay = day
    }
    
    // MARK: - Workflow Methods
    
    func startWorkout() {
        guard selectedDay != nil else { return }
        workoutState = .countdown
    }
    
    func beginActiveSession() {
        guard let day = selectedDay else { return }
        
        // 1. Refresh object to ensure it is valid and attached to context
        var activeDay = day
        if let freshDay = modelContext.model(for: day.persistentModelID) as? WorkoutDay {
            activeDay = freshDay
            self.selectedDay = freshDay
        }
        
        // 2. Force load exercises relationship before starting
        // This ensures SwiftData faults it in
        let _ = activeDay.exercises.count
        let _ = activeDay.exercises.map { $0.name }
        
        // Create new session
        let session = WorkoutSession(
            date: Date(),
            workoutDayName: day.name,
            programName: activeProgram?.name
        )
        modelContext.insert(session)
        currentSession = session
        workoutState = .active
        
        // Start Live Activity
        let startDate = Date()
        LiveActivityManager.shared.start(workoutType: session.workoutDayName, startDate: startDate)
        startActivityUpdates(startDate: startDate)
        
            // Start HealthKit Session
        let shouldSync = UserDefaults.standard.object(forKey: "isHealthSyncEnabled") as? Bool ?? true
        if shouldSync {
            Task {
                var type: HKWorkoutActivityType = .traditionalStrengthTraining
                
                if let dayType = self.selectedDay?.workoutType {
                    switch dayType {
                    case .strength:
                        type = .traditionalStrengthTraining
                    case .repsOnly:
                        type = .functionalStrengthTraining
                    case .duration:
                        let name = session.workoutDayName.lowercased()
                        if name.contains("run") || name.contains("бег") {
                            type = .running
                        } else if name.contains("walk") || name.contains("ходьба") {
                            type = .walking
                        } else {
                            type = .mixedCardio
                        }
                    }
                }
                
                await HealthManager.shared.startWorkout(workoutType: type)
            }
            
            
            // Subscribe to real-time updates
            HealthManager.shared.onHeartRateUpdate = { [weak self] hr in
                self?.currentHeartRate = hr
                Task {
                    await self?.updateLiveActivity(startDate: startDate)
                }
            }
            
            HealthManager.shared.onCalorieUpdate = { [weak self] cals in
                self?.currentActiveCalories = cals
                Task {
                    await self?.updateLiveActivity(startDate: startDate)
                }
            }
        }
    }
    
    func cancelWorkout() {
        Task { @MainActor in
            // Stop Live Activity
            stopActivityUpdates()
            LiveActivityManager.shared.end()
            
            // Discard HealthKit Session
            await HealthManager.shared.discardWorkout()
            
            // Delete current session without saving
            if let session = currentSession {
                modelContext.delete(session)
                try? modelContext.save()
            }
            
            currentSession = nil
            workoutState = .idle
        }
    }
    
    func finishWorkout() {
        guard let session = currentSession else { return }
        
        // 1. Immediate UI Transition & Cleanup
        // We set summary state FIRST so the UI feels responsive
        stopActivityUpdates() // Stop timer immediately
        HealthManager.shared.onHeartRateUpdate = nil
        HealthManager.shared.onCalorieUpdate = nil
        LiveActivityManager.shared.end()
        
        // Set end time and completion status locally
        let endDate = Date()
        session.endTime = endDate
        session.isCompleted = true
        
        // Optimistically set values if we have them
        if currentActiveCalories > 0 { session.calories = currentActiveCalories }
        if currentHeartRate > 0 { session.averageHeartRate = currentHeartRate }
        
        // Transition to summary
        self.workoutState = .summary
        
        // 2. Background Operations (HealthKit & Save)
        Task {
            await HealthManager.shared.endWorkout()
            
            // Fetch accurate data
            if HealthManager.shared.isAuthorized {
                let calories = await HealthManager.shared.fetchCaloriesForWorkout(start: session.date, end: endDate)
                let avgHeartRate = await HealthManager.shared.fetchAverageHeartRate(start: session.date, end: endDate)
                
                await MainActor.run {
                    // Update valid session only
                    guard self.currentSession?.id == session.id else { return }
                    
                    if calories > 0 { session.calories = Int(calories) }
                    if avgHeartRate > 0 { session.averageHeartRate = Int(avgHeartRate) }
                    
                    try? modelContext.save()
                    print("Workout Completed & Secured. HR: \(session.averageHeartRate ?? 0)")
                }
            } else {
                 await MainActor.run {
                     try? modelContext.save()
                 }
            }
        }
    }
    
    func requestHealthAccess() {
        Task {
            _ = await HealthManager.shared.requestAuthorization()
        }
    }
    
    func closeWorkout() {
        // Final save just in case
        try? modelContext.save()
        currentSession = nil
        workoutState = .idle
    }
    
    // MARK: - Previous Session
    
    func getPreviousSession(for day: WorkoutDay) -> WorkoutSession? {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let allSessions = (try? modelContext.fetch(descriptor)) ?? []
        
        // Filter for this workout day, completed, and not current session
        return allSessions.first { session in
            session.workoutDayName == day.name &&
            session.isCompleted &&
            session != currentSession
        }
    }
    
    // MARK: - Progress Comparison
    
    func comparePerformance(
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
    
    func getProgressData(for session: WorkoutSession, comparedTo previousSession: WorkoutSession?) -> [ExerciseProgress] {
        guard let day = selectedDay else { return [] }
        
        return day.exercises.sorted { $0.orderIndex < $1.orderIndex }.compactMap { exercise in
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
    
    func getPreviewProgressData() -> [ExerciseProgress] {
        guard let day = selectedDay else { return [] }
        let previousSession = getPreviousSession(for: day)
        
        guard let previousSession = previousSession else {
            // No previous data - return empty state
            return []
        }
        
        return day.exercises.sorted { $0.orderIndex < $1.orderIndex }.compactMap { exercise in
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
    
    func calculateGrowthTrend(history: [WorkoutSession]) -> GrowthTrend {
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
    
    // MARK: - Live Activity Updates
    
    private func startActivityUpdates(startDate: Date) {
        liveActivityTimer?.invalidate()
        liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateLiveActivity(startDate: startDate)
            }
        }
    }
    
    private func stopActivityUpdates() {
        liveActivityTimer?.invalidate()
        liveActivityTimer = nil
    }
    
    private func updateLiveActivity(startDate: Date) async {
        // We attempt to fetch data regardless of cached 'isAuthorized' state.
        // HealthManager handles errors gracefully and returns 0 if access is denied/unavailable.
        
        let now = Date()
        async let calories = HealthManager.shared.fetchCaloriesForWorkout(start: startDate, end: now)
        async let heartRate = HealthManager.shared.fetchLatestHeartRate(since: nil)
        
        let (calValue, hrValue) = await (calories, heartRate)
        
        LiveActivityManager.shared.update(heartRate: Int(hrValue), calories: Int(calValue))
        
        // Update local state for UI
        self.currentHeartRate = Int(hrValue)
        self.currentActiveCalories = Int(calValue)
    }
}
