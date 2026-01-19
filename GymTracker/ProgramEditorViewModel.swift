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
    @Published var name: String
    @Published var workoutType: WorkoutType
    @Published var defaultRestTime: Int
    @Published var restTimerEnabled: Bool
    @Published var exercises: [ExerciseDraft]
    var orderIndex: Int
    
    init(name: String, orderIndex: Int, workoutType: WorkoutType = .strength, defaultRestTime: Int = 90, restTimerEnabled: Bool = true, exercises: [ExerciseDraft] = []) {
        self.name = name
        self.orderIndex = orderIndex
        self.workoutType = workoutType
        self.defaultRestTime = defaultRestTime
        self.restTimerEnabled = restTimerEnabled
        self.exercises = exercises
    }
}

/// Черновик упражнения для редактирования
struct ExerciseDraft: Identifiable {
    let id = UUID()
    var name: String
    var plannedSets: Int
    var orderIndex: Int
    var type: WorkoutType? // Added type override
    
    init(name: String, plannedSets: Int = 3, orderIndex: Int = 0, type: WorkoutType? = nil) {
        self.name = name
        self.plannedSets = plannedSets
        self.orderIndex = orderIndex
        self.type = type
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
            name: "День \(dayNumber)",
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
        // Перемещаем элементы
        let movedDays = source.map { workoutDays[$0] }
        var newDays = workoutDays
        for index in source.sorted(by: >) {
            newDays.remove(at: index)
        }
        let adjustedDestination = destination > source.first! ? destination - source.count : destination
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
        // Перемещаем элементы
        let movedExercises = source.map { day.exercises[$0] }
        for index in source.sorted(by: >) {
            day.exercises.remove(at: index)
        }
        let adjustedDestination = destination > source.first! ? destination - source.count : destination
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
            // Обновляем существующую программу
            program = existing
            program.name = programName.trimmingCharacters(in: .whitespaces)
            program.desc = programDescription.trimmingCharacters(in: .whitespaces)
            
            // Удаляем старые дни
            for oldDay in program.days {
                context.delete(oldDay)
            }
            program.days.removeAll()
        } else {
            // Создаем новую программу
            program = Program(
                name: programName.trimmingCharacters(in: .whitespaces),
                desc: programDescription.trimmingCharacters(in: .whitespaces)
            )
            context.insert(program)
        }
        
        // Создаем дни
        for dayDraft in workoutDays {
            let workoutDay = WorkoutDay(
                name: dayDraft.name,
                orderIndex: dayDraft.orderIndex,
                workoutType: dayDraft.workoutType,
                defaultRestTime: dayDraft.defaultRestTime,
                restTimerEnabled: dayDraft.restTimerEnabled
            )
            
            // Создаем упражнения
            for exerciseDraft in dayDraft.exercises {
                let exerciseTemplate = ExerciseTemplate(
                    name: exerciseDraft.name,
                    plannedSets: exerciseDraft.plannedSets,
                    orderIndex: exerciseDraft.orderIndex,
                    type: exerciseDraft.type
                )
                workoutDay.exercises.append(exerciseTemplate)
            }
            
            program.days.append(workoutDay)
        }
        
        try context.save()
    }
    
    // MARK: - Reset
    
    func reset() {
        programName = ""
        programDescription = ""
        workoutDays = []
    }
    
    // MARK: - Load Existing Program (для редактирования)
    
    func loadProgram(_ program: Program) {
        programName = program.name
        programDescription = program.desc
        
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
                            type: exercise._customWorkoutType // Load explicit type override if present
                        )
                    }
                
                return WorkoutDayDraft(
                    name: day.name,
                    orderIndex: day.orderIndex,
                    workoutType: day.workoutType,
                    defaultRestTime: day.defaultRestTime,
                    restTimerEnabled: day.restTimerEnabled,
                    exercises: exercises
                )
            }
    }
}
