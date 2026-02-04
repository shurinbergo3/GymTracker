//
//  ProgramDetailView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let program: Program
    
    @State private var showingEditProgram = false
    @State private var showingDeleteAlert = false
    
    private var sortedDays: [WorkoutDay] {
        program.days.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        List {
            // Информация о программе
            Section {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    if !program.desc.isEmpty {
                        Text(program.desc)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    HStack {
                        Label("\(program.days.count) дней", systemImage: "calendar")
                        Spacer()
                        if program.isActive {
                            Text("Активная")
                                .font(DesignSystem.Typography.caption())
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(DesignSystem.Colors.accent.opacity(0.2))
                                .foregroundColor(DesignSystem.Colors.accent)
                                .cornerRadius(DesignSystem.CornerRadius.small)
                        }
                    }
                    .font(DesignSystem.Typography.callout())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            // Дни тренировок
            Section("Дни тренировок") {
                ForEach(sortedDays, id: \.self) { day in
                    WorkoutDayRow(day: day)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditProgram = true }) {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditProgram) {
            ProgramEditorView(existingProgram: program)
        }
        .alert("Удалить программу?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                deleteProgram()
            }
        } message: {
            Text("Программа \"\(program.name)\" будет удалена без возможности восстановления.")
        }
    }
    
    private func deleteProgram() {
        // Trigger Cloud Sync (Delete)
        // We must do this BEFORE deleting from context, or at least capture the data
        // But SyncManager needs the object properties.
        // It's safe to start the Task with the object, even if context deletes it locally.
        let programToDelete = program
        Task {
            await SyncManager.shared.syncProgramDeletion(program: programToDelete)
        }
        
        modelContext.delete(program)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Workout Day Row

struct WorkoutDayRow: View {
    let day: WorkoutDay
    
    @State private var isExpanded = false
    
    private var sortedExercises: [ExerciseTemplate] {
        day.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(day.name)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("\(day.exercises.count) упражнений")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(Array(sortedExercises.enumerated()), id: \.element) { index, exercise in
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text("\(index + 1).")
                                .font(DesignSystem.Typography.callout())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .frame(width: 25, alignment: .leading)
                            
                            Text(exercise.name)
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            ExerciseInfoButton(exerciseName: exercise.name)
                            
                            Spacer()
                            
                            Text("\(exercise.plannedSets) × подходов")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.leading, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        ProgramDetailView(program: Program(name: "Масса", desc: "Программа на набор массы"))
            .modelContainer(for: [Program.self], inMemory: true)
    }
}
