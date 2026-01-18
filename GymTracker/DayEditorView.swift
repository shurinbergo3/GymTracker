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
                            for index in offsets.sorted(by: >) {
                                day.exercises.remove(at: index)
                            }
                            reindexExercises()
                        }
                    }
                    .onMove { source, destination in
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
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") {
                    dismiss()
                }
                .fontWeight(.semibold)
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
            orderIndex: day.exercises.count,
            type: exercise.defaultType
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
    
    private var exerciseType: WorkoutType {
        exercise.type ?? .strength
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Название и инфо
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text(exercise.name)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                ExerciseInfoButton(exerciseName: exercise.name)
                
                Spacer()
            }
            
            // Настройки: тип + подходы
            HStack(spacing: DesignSystem.Spacing.md) {
                // Тип тренировки (меню)
                Menu {
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        Button(action: { updateType(to: type) }) {
                            Label(type.rawValue, systemImage: type.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: exerciseType.icon)
                            .font(.caption)
                        Text(exerciseType.rawValue)
                            .font(DesignSystem.Typography.caption())
                    }
                    .foregroundColor(DesignSystem.Colors.accent)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(DesignSystem.Colors.accent.opacity(0.15))
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                
                Spacer()
                
                // Подходы
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("\(exercise.plannedSets) подх.")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Stepper(
                        value: Binding(
                            get: { exercise.plannedSets },
                            set: { newValue in
                                updateSets(for: exercise.id, newValue: newValue)
                            }
                        ),
                        in: 1...10
                    ) {
                        EmptyView()
                    }
                    .labelsHidden()
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    private func updateType(to newType: WorkoutType) {
        if let index = day.exercises.firstIndex(where: { $0.id == exercise.id }) {
            day.exercises[index].type = newType
        }
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
                    ExerciseDraft(name: "Жим штанги лежа", plannedSets: 4, orderIndex: 0, type: .strength),
                    ExerciseDraft(name: "Подтягивания", plannedSets: 3, orderIndex: 1, type: .repsOnly)
                ]
            )
        )
    }
}
