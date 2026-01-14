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

// MARK: - Workout State

enum WorkoutState {
    case idle       // Dashboard - ready to start
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
        
        requestHealthAccess()
    }
    
    // MARK: - Initialization
    
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
        guard let day = selectedDay else { return }
        
        // Create new session
        let session = WorkoutSession(
            date: Date(),
            workoutDayName: day.name
        )
        modelContext.insert(session)
        currentSession = session
        currentSession = session
        workoutState = .active
        
        // Start Live Activity
        let startDate = Date()
        LiveActivityManager.shared.start(workoutType: session.workoutDayName, startDate: startDate)
        startActivityUpdates(startDate: startDate)
    }
    
    func cancelWorkout() {
        Task { @MainActor in
            // Stop Live Activity
            stopActivityUpdates()
            LiveActivityManager.shared.end()
            
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
        
        Task { @MainActor in
            // Stop Live Activity
            stopActivityUpdates()
            LiveActivityManager.shared.end()
            
            // Set end time
            let endDate = Date()
            session.endTime = endDate
            
            // Fetch calories and HR if authorized
            if HealthManager.shared.isAuthorized {
                async let calories = HealthManager.shared.fetchCaloriesForWorkout(start: session.date, end: endDate)
                async let avgHeartRate = HealthManager.shared.fetchAverageHeartRate(start: session.date, end: endDate)
                
                let (calValue, hrValue) = await (calories, avgHeartRate)
                session.calories = Int(calValue)
                session.averageHeartRate = Int(hrValue)
            }
            
            session.isCompleted = true
            workoutState = .summary
        }
    }
    
    func requestHealthAccess() {
        Task {
            _ = await HealthManager.shared.requestAuthorization()
        }
    }
    
    func closeWorkout() {
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
        guard HealthManager.shared.isAuthorized else { return }
        
        let now = Date()
        async let calories = HealthManager.shared.fetchCaloriesForWorkout(start: startDate, end: now)
        async let heartRate = HealthManager.shared.fetchLatestHeartRate(since: startDate)
        
        let (calValue, hrValue) = await (calories, heartRate)
        
        LiveActivityManager.shared.update(heartRate: Int(hrValue), calories: Int(calValue))
        
        // Update local state for UI
        self.currentHeartRate = Int(hrValue)
        self.currentActiveCalories = Int(calValue)
    }
}
