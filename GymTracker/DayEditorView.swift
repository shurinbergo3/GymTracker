//
//  DayEditorView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

struct DayEditorView: View {
    @ObservedObject var day: WorkoutDayDraft
    @State private var showingExerciseSelection = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            // Секция с информацией о дне
            Section {
                TextField("Название дня", text: $day.name)
                    .font(DesignSystem.Typography.body())
            } header: {
                Text("Основная информация")
                    .font(DesignSystem.Typography.headline())
            }
            
            // Секция: Тип тренировки
            Section {
                Picker("Тип тренировки", selection: $day.workoutType) {
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.rawValue)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .font(DesignSystem.Typography.body())
            } header: {
                Text("Тип тренировки")
                    .font(DesignSystem.Typography.headline())
            }
            
            // Секция с упражнениями
            Section {
                if day.exercises.isEmpty {
                    ContentUnavailableView {
                        Label("Нет упражнений", systemImage: "figure.strengthtraining.traditional")
                            .font(DesignSystem.Typography.body())
                    } description: {
                        Text("Добавьте упражнения в этот день")
                            .font(DesignSystem.Typography.callout())
                    }
                } else {
                    ForEach(day.exercises) { exercise in
                        ExerciseEditRow(
                            exercise: exercise,
                            day: day
                        )
                    }
                    .onDelete { offsets in
                        withAnimation {
                            // Удаляем элементы по индексам
                            for index in offsets.sorted(by: >) {
                                day.exercises.remove(at: index)
                            }
                            reindexExercises()
                        }
                    }
                    .onMove { source, destination in
                        // Перемещаем элементы
                        let movedExercises = source.map { day.exercises[$0] }
                        for index in source.sorted(by: >) {
                            day.exercises.remove(at: index)
                        }
                        let adjustedDestination = destination > source.first! ? destination - source.count : destination
                        day.exercises.insert(contentsOf: movedExercises, at: adjustedDestination)
                        reindexExercises()
                    }
                }
                
                Button(action: { showingExerciseSelection = true }) {
                    Label("Добавить упражнение", systemImage: "plus.circle.fill")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            } header: {
                Text("Упражнения (\(day.exercises.count))")
                    .font(DesignSystem.Typography.headline())
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Готово") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingExerciseSelection) {
            ExerciseSelectionView { exercise in
                withAnimation {
                    addExercise(exercise)
                }
            }
        }
    }
    
    private func addExercise(_ exercise: LibraryExercise) {
        let newExercise = ExerciseDraft(
            name: exercise.name,
            plannedSets: 3,
            orderIndex: day.exercises.count
        )
        day.exercises.append(newExercise)
    }
    
    private func reindexExercises() {
        for (index, _) in day.exercises.enumerated() {
            day.exercises[index].orderIndex = index
        }
    }
}

// MARK: - Exercise Edit Row

struct ExerciseEditRow: View {
    let exercise: ExerciseDraft
    @ObservedObject var day: WorkoutDayDraft
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(exercise.name)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    ExerciseInfoButton(exerciseName: exercise.name)
                }
                
                Text("\(exercise.plannedSets) подходов")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Stepper для изменения количества подходов
            Stepper(
                value: Binding(
                    get: { exercise.plannedSets },
                    set: { newValue in
                        updateSets(for: exercise.id, newValue: newValue)
                    }
                ),
                in: 1...10
            ) {
                Text("\(exercise.plannedSets)")
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.accent)
                    .frame(width: 30)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    private func updateSets(for exerciseId: UUID, newValue: Int) {
        if let index = day.exercises.firstIndex(where: { $0.id == exerciseId }) {
            day.exercises[index].plannedSets = max(1, newValue)
        }
    }
}

#Preview {
    NavigationStack {
        DayEditorView(
            day: WorkoutDayDraft(
                name: "День груди",
                orderIndex: 0,
                exercises: [
                    ExerciseDraft(name: "Жим штанги лежа", plannedSets: 4, orderIndex: 0),
                    ExerciseDraft(name: "Разводка гантелей", plannedSets: 3, orderIndex: 1)
                ]
            )
        )
    }
}
