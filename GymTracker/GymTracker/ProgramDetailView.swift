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

    private var meta: ProgramMetadata {
        ProgramMetadata.metadata(for: program.name)
    }

    var body: some View {
        List {
            // HERO header
            Section {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    // Category badge + Active indicator
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        HStack(spacing: 4) {
                            Image(systemName: meta.category.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(meta.category.displayName.uppercased())
                                .font(DesignSystem.Typography.caption())
                                .fontWeight(.bold)
                                .tracking(1)
                        }
                        .foregroundColor(meta.category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(meta.category.color.opacity(0.18))
                        .clipShape(Capsule())

                        if program.isActive {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Активная".localized())
                                    .fontWeight(.bold)
                            }
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(DesignSystem.Colors.neonGreen.opacity(0.18))
                            .clipShape(Capsule())
                        }
                    }

                    if !program.desc.isEmpty {
                        Text(program.desc.localized())
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }

                    HStack(spacing: DesignSystem.Spacing.lg) {
                        statBlock(icon: meta.level.icon, value: meta.level.displayName, label: "Уровень".localized(), color: meta.level.color)
                        statBlock(icon: "calendar", value: "\(program.days.count)", label: "дней".localized(), color: meta.category.color)
                        statBlock(icon: "clock", value: "~\(meta.estimatedMinutes)", label: "мин/тр".localized(), color: DesignSystem.Colors.secondaryText)
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
            }

            // Workout days
            Section {
                ForEach(sortedDays, id: \.self) { day in
                    WorkoutDayRow(day: day)
                }
            } header: {
                Text("Дни тренировок".localized())
                    .font(DesignSystem.Typography.headline())
            } footer: {
                if program.isActive {
                    Text("Подсказка: войди в любой день, чтобы задать своё время отдыха.".localized())
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Text(program.name.localized()))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditProgram = true }) {
                        Label("Редактировать".localized(), systemImage: "pencil")
                    }

                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Удалить".localized(), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditProgram) {
            ProgramEditorView(existingProgram: program)
        }
        .alert(Text("Удалить программу?".localized()), isPresented: $showingDeleteAlert) {
            Button("Отмена".localized(), role: .cancel) { }
            Button("Удалить".localized(), role: .destructive) {
                deleteProgram()
            }
        } message: {
            Text(String(format: "program_delete_confirmation".localized(), program.name.localized()))
        }
    }

    @ViewBuilder
    private func statBlock(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(value)
                    .font(DesignSystem.Typography.headline())
                    .fontWeight(.bold)
            }
            .foregroundColor(color)
            Text(label)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }

    private func deleteProgram() {
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
                        Text(day.name.localized())
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(String(format: "%d упражнений".localized(), day.exercises.count))
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
                            
                            Text(exercise.name.localized())
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            ExerciseInfoButton(exerciseName: exercise.name)
                            
                            Spacer()
                            
                            Text(String(format: "%d × подходов".localized(), exercise.plannedSets))
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
