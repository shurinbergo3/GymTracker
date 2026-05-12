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
                        statBlock(icon: "hourglass", value: meta.experienceLabel, label: "Опыт".localized(), color: meta.level.color)
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
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(sortedExercises.enumerated()), id: \.element) { index, exercise in
                        ExpandedExerciseRow(index: index + 1, exercise: exercise)

                        if index < sortedExercises.count - 1 {
                            Rectangle()
                                .fill(DesignSystem.Colors.accent.opacity(0.08))
                                .frame(height: 0.5)
                                .padding(.leading, 40)
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

// MARK: - Expanded Exercise Row

private struct ExpandedExerciseRow: View {
    let index: Int
    let exercise: ExerciseTemplate
    @State private var showingTechnique = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Numbered badge — neon orb with monospaced digit
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.accent.opacity(0.28),
                                DesignSystem.Colors.accent.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Circle()
                    .stroke(DesignSystem.Colors.accent.opacity(0.55), lineWidth: 1)
                Text("\(index)")
                    .font(.system(.footnote, design: .rounded, weight: .heavy).monospacedDigit())
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .frame(width: 28, height: 28)

            // Exercise name — wraps inside its column without disturbing trailing
            Text(exercise.name.localized())
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Trailing column — fixed-width chip + info icon
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    Image(systemName: "multiply")
                        .font(.system(size: 9, weight: .heavy))
                    Text("\(exercise.plannedSets)")
                        .font(.system(.caption, design: .rounded, weight: .heavy).monospacedDigit())
                }
                .foregroundColor(DesignSystem.Colors.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(DesignSystem.Colors.accent.opacity(0.13))
                )
                .overlay(
                    Capsule().stroke(DesignSystem.Colors.accent.opacity(0.32), lineWidth: 0.8)
                )
                .accessibilityLabel(Text(String(format: "%d × подходов".localized(), exercise.plannedSets)))

                Button {
                    showingTechnique = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showingTechnique) {
                    ExerciseTechniqueDetailView(exerciseName: exercise.name)
                }
            }
            .padding(.top, 2) // align trailing column with first text baseline
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 2)
    }
}

#Preview {
    NavigationStack {
        ProgramDetailView(program: Program(name: "Масса", desc: "Программа на набор массы"))
            .modelContainer(for: [Program.self], inMemory: true)
    }
}
