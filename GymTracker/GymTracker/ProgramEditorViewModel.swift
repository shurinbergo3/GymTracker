//
//  ProgramEditorViewModel.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import Foundation
import SwiftData
import Combine

// MARK: - Draft Models (не SwiftData)

/// Черновик дня тренировки для редактирования
class WorkoutDayDraft: Identifiable, ObservableObject {
    let id = UUID()
    var originalID: PersistentIdentifier? // Track existing persistent object
    @Published var name: String
    @Published var workoutType: WorkoutType
    @Published var defaultRestTime: Int
    @Published var restTimerEnabled: Bool
    @Published var exercises: [ExerciseDraft]
    var orderIndex: Int
    
    init(name: String, orderIndex: Int, workoutType: WorkoutType = .strength, defaultRestTime: Int = 90, restTimerEnabled: Bool = true, exercises: [ExerciseDraft] = [], originalID: PersistentIdentifier? = nil) {
        self.name = name
        self.orderIndex = orderIndex
        self.workoutType = workoutType
        self.defaultRestTime = defaultRestTime
        self.restTimerEnabled = restTimerEnabled
        self.exercises = exercises
        self.originalID = originalID
    }
}

/// Черновик упражнения для редактирования
struct ExerciseDraft: Identifiable {
    let id = UUID()
    var originalID: UUID? // Track existing persistent object (ExerciseTemplate has UUID)
    var name: String
    var plannedSets: Int
    var orderIndex: Int
    var type: WorkoutType? // Added type override
    
    init(name: String, plannedSets: Int = 3, orderIndex: Int = 0, type: WorkoutType? = nil, originalID: UUID? = nil) {
        self.name = name
        self.plannedSets = plannedSets
        self.orderIndex = orderIndex
        self.type = type
        self.originalID = originalID
    }
}

// MARK: - Program Editor ViewModel

@MainActor
class ProgramEditorViewModel: ObservableObject {
    @Published var programName: String = ""
    @Published var programDescription: String = ""
    @Published var workoutDays: [WorkoutDayDraft] = []
    
    var isValid: Bool {
        !programName.trimmingCharacters(in: .whitespaces).isEmpty && !workoutDays.isEmpty
    }
    
    // MARK: - Day Management
    
    func addDay() {
        let dayNumber = workoutDays.count + 1
        let newDay = WorkoutDayDraft(
            name: String(format: "День %d".localized(), dayNumber),
            orderIndex: workoutDays.count
        )
        workoutDays.append(newDay)
    }
    
    func deleteDay(at offsets: IndexSet) {
        // Удаляем элементы по индексам
        for index in offsets.sorted(by: >) {
            workoutDays.remove(at: index)
        }
        // Пересчитываем orderIndex
        for (index, day) in workoutDays.enumerated() {
            day.orderIndex = index
        }
    }
    
    func moveDay(from source: IndexSet, to destination: Int) {
        guard let firstSource = source.first else { return }
        // Перемещаем элементы
        let movedDays = source.map { workoutDays[$0] }
        var newDays = workoutDays
        for index in source.sorted(by: >) {
            newDays.remove(at: index)
        }
        let adjustedDestination = destination > firstSource ? destination - source.count : destination
        newDays.insert(contentsOf: movedDays, at: adjustedDestination)
        workoutDays = newDays

        // Пересчитываем orderIndex
        for (index, day) in workoutDays.enumerated() {
            day.orderIndex = index
        }
    }
    
    // MARK: - Exercise Management
    
    func addExercise(to day: WorkoutDayDraft, exercise: LibraryExercise) {
        let newExercise = ExerciseDraft(
            name: exercise.name,
            plannedSets: 3,
            orderIndex: day.exercises.count,
            type: exercise.defaultType
        )
        day.exercises.append(newExercise)
    }
    
    func removeExercise(from day: WorkoutDayDraft, at offsets: IndexSet) {
        // Удаляем элементы по индексам
        for index in offsets.sorted(by: >) {
            day.exercises.remove(at: index)
        }
        // Пересчитываем orderIndex
        for index in day.exercises.indices {
            day.exercises[index].orderIndex = index
        }
    }
    
    func moveExercise(in day: WorkoutDayDraft, from source: IndexSet, to destination: Int) {
        guard let firstSource = source.first else { return }
        // Перемещаем элементы
        let movedExercises = source.map { day.exercises[$0] }
        for index in source.sorted(by: >) {
            day.exercises.remove(at: index)
        }
        let adjustedDestination = destination > firstSource ? destination - source.count : destination
        day.exercises.insert(contentsOf: movedExercises, at: adjustedDestination)

        // Пересчитываем orderIndex
        for index in day.exercises.indices {
            day.exercises[index].orderIndex = index
        }
    }
    
    func updatePlannedSets(for exerciseId: UUID, in day: WorkoutDayDraft, sets: Int) {
        if let index = day.exercises.firstIndex(where: { $0.id == exerciseId }) {
            day.exercises[index].plannedSets = max(1, sets)
        }
    }
    
    // MARK: - Save to SwiftData
    
    func saveProgram(context: ModelContext, existingProgram: Program? = nil) throws {
        let program: Program
        
        if let existing = existingProgram {
            // SAFE UPDATE: Update in-place to allow active workouts to continue
            program = existing
            program.name = programName.trimmingCharacters(in: .whitespaces)
            program.desc = programDescription.trimmingCharacters(in: .whitespaces)
            program.isUserModified = true // Mark as user-modified
            
            // Capture IDs of days currently in the database to identify deletions later
            // We use PersistentIdentifier which is stable for saved objects
            // Note: Creating a separate array to iterate safely
            let originalDays = existing.days
            var processedDayIDs: Set<PersistentIdentifier> = []
            
            // 1. Process Drafts (Update or Insert)
            for dayDraft in workoutDays {
                if let id = dayDraft.originalID,
                   let existingDay = originalDays.first(where: { $0.persistentModelID == id }) {
                    // UPDATE Existing Day
                    existingDay.name = dayDraft.name
                    existingDay.orderIndex = dayDraft.orderIndex
                    existingDay.workoutType = dayDraft.workoutType
                    existingDay.defaultRestTime = dayDraft.defaultRestTime
                    existingDay.restTimerEnabled = dayDraft.restTimerEnabled
                    
                    processedDayIDs.insert(id)
                    
                    // Update Exercises for this Day
                    updateExercises(for: existingDay, from: dayDraft, context: context)
                } else {
                    // INSERT New Day
                    let newDay = WorkoutDay(
                        name: dayDraft.name,
                        orderIndex: dayDraft.orderIndex,
                        workoutType: dayDraft.workoutType,
                        defaultRestTime: dayDraft.defaultRestTime,
                        restTimerEnabled: dayDraft.restTimerEnabled
                    )
                    // Add exercises to new day
                    for exerciseDraft in dayDraft.exercises {
                        let newEx = ExerciseTemplate(
                            name: exerciseDraft.name,
                            plannedSets: exerciseDraft.plannedSets,
                            orderIndex: exerciseDraft.orderIndex,
                            type: exerciseDraft.type
                        )
                        newDay.exercises.append(newEx)
                    }
                    
                    program.days.append(newDay)
                }
            }
            
            // 2. Delete Orphaned Days — remove from relationship first to avoid SwiftData crash
            for day in originalDays {
                if !processedDayIDs.contains(day.persistentModelID) {
                    program.days.removeAll { $0.persistentModelID == day.persistentModelID }
                    context.delete(day)
                }
            }
            
        } else {
            // CREATE NEW PROGRAM
            program = Program(
                name: programName.trimmingCharacters(in: .whitespaces),
                desc: programDescription.trimmingCharacters(in: .whitespaces)
            )
            program.isUserModified = true // New programs are user-created
            context.insert(program)
            
            // Just add everything new
            for dayDraft in workoutDays {
                let workoutDay = WorkoutDay(
                    name: dayDraft.name,
                    orderIndex: dayDraft.orderIndex,
                    workoutType: dayDraft.workoutType,
                    defaultRestTime: dayDraft.defaultRestTime,
                    restTimerEnabled: dayDraft.restTimerEnabled
                )
                for exerciseDraft in dayDraft.exercises {
                    let ex = ExerciseTemplate(
                        name: exerciseDraft.name,
                        plannedSets: exerciseDraft.plannedSets,
                        orderIndex: exerciseDraft.orderIndex,
                        type: exerciseDraft.type
                    )
                    workoutDay.exercises.append(ex)
                }
                program.days.append(workoutDay)
            }
        }
        
        try context.save()
        
        // Trigger Cloud Sync
        Task {
            await SyncManager.shared.syncAllPrograms(context: context)
        }
    }
    
    // Helper to update exercises safely
    private func updateExercises(for day: WorkoutDay, from draft: WorkoutDayDraft, context: ModelContext) {
        let originalExercises = day.exercises
        var processedExerciseIDs: Set<UUID> = []
        
        for exDraft in draft.exercises {
            if let originalUUID = exDraft.originalID,
               let existingEx = originalExercises.first(where: { $0.id == originalUUID }) {
                // UPDATE
                existingEx.name = exDraft.name
                existingEx.plannedSets = exDraft.plannedSets
                existingEx.orderIndex = exDraft.orderIndex
                existingEx._customWorkoutType = exDraft.type
                processedExerciseIDs.insert(originalUUID)
            } else {
                // INSERT — must explicitly insert into context so SwiftData tracks it
                let newEx = ExerciseTemplate(
                    name: exDraft.name,
                    plannedSets: exDraft.plannedSets,
                    orderIndex: exDraft.orderIndex,
                    type: exDraft.type
                )
                context.insert(newEx)
                day.exercises.append(newEx)
            }
        }
        
        // Delete orphans — MUST remove from relationship array first,
        // otherwise SwiftData save() encounters deleted objects in the array → crash
        for ex in originalExercises {
            if !processedExerciseIDs.contains(ex.id) {
                day.exercises.removeAll { $0.id == ex.id }
                context.delete(ex)
            }
        }
    }

    
    // MARK: - Reset
    
    func reset() {
        programName = ""
        programDescription = ""
        workoutDays = []
    }
    
    // MARK: - Load Existing Program (для редактирования)
    
    func loadProgram(_ program: Program) {
        programName = program.name.localized()
        programDescription = program.desc.localized()
        
        workoutDays = program.days
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { day in
                let exercises = day.exercises
                    .sorted { $0.orderIndex < $1.orderIndex }
                    .map { exercise in
                        ExerciseDraft(
                            name: exercise.name,
                            plannedSets: exercise.plannedSets,
                            orderIndex: exercise.orderIndex,
                            type: exercise._customWorkoutType,
                            originalID: exercise.id // Store stable UUID
                        )
                    }
                
                return WorkoutDayDraft(
                    name: day.name.localized(),
                    orderIndex: day.orderIndex,
                    workoutType: day.workoutType,
                    defaultRestTime: day.defaultRestTime,
                    restTimerEnabled: day.restTimerEnabled,
                    exercises: exercises,
                    originalID: day.persistentModelID // Store persistent ID
                )
            }
    }
}
