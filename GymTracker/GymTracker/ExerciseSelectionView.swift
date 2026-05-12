//
//  ExerciseSelectionView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var showingCustomExercise = false
    @State private var customExerciseName = ""

    let onExerciseSelected: (LibraryExercise) -> Void

    private var filteredExercises: [LibraryExercise] {
        var exercises = ExerciseLibrary.allExercises
        if !searchText.isEmpty {
            exercises = exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category }
        }
        return exercises
    }

    private var groupedExercises: [ExerciseCategory: [LibraryExercise]] {
        Dictionary(grouping: filteredExercises, by: { $0.category })
    }

    private var availableCategories: [ExerciseCategory] {
        let all = Dictionary(grouping: ExerciseLibrary.allExercises, by: { $0.category })
        return ExerciseCategory.allCases.filter { all[$0]?.isEmpty == false }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                exerciseList
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "search_exercises_placeholder"
            )
            .navigationTitle("exercise_selection_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel_button".localized()) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCustomExercise = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("new_exercise_title".localized(), isPresented: $showingCustomExercise) {
                TextField("exercise_name_placeholder".localized(), text: $customExerciseName)
                Button("cancel_button".localized(), role: .cancel) {
                    customExerciseName = ""
                }
                Button("add_button".localized()) {
                    addCustomExercise()
                }
            } message: {
                Text("enter_exercise_name_message".localized())
            }
        }
    }

    @ViewBuilder
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                CategoryCarousel(
                    categories: availableCategories,
                    selectedCategory: selectedCategory,
                    onSelect: { newValue in
                        selectedCategory = newValue
                    }
                )
                .padding(.horizontal, -DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.xs)

                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    section(for: category)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }

    @ViewBuilder
    private func section(for category: ExerciseCategory) -> some View {
        if let exercises = groupedExercises[category], !exercises.isEmpty {
            Section {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(exercises) { exercise in
                        SelectionRow(exercise: exercise, accent: category.accentColor) {
                            onExerciseSelected(exercise)
                            dismiss()
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.xs)
            } header: {
                CategorySectionHeader(category: category, count: exercises.count)
            }
        }
    }

    private func addCustomExercise() {
        guard !customExerciseName.isEmpty else { return }

        let customExercise = LibraryExercise(
            name: customExerciseName,
            category: .custom,
            muscleGroup: .fullBody
        )

        let customExerciseModel = CustomExercise(from: customExercise)
        modelContext.insert(customExerciseModel)

        Task {
            do {
                let dto = CustomExerciseDTO(from: customExerciseModel)
                try await FirestoreManager.shared.saveCustomExercise(dto)
                #if DEBUG
                print("✅ Custom exercise '\(customExercise.name)' saved and synced")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Failed to sync custom exercise: \(error)")
                #endif
            }
        }

        onExerciseSelected(customExercise)
        customExerciseName = ""
        dismiss()
    }
}

// MARK: - Colorful Selection Row (mirrors ExerciseListRow with "+" instead of YouTube)

struct SelectionRow: View {
    let exercise: LibraryExercise
    let accent: Color
    let onAdd: () -> Void
    @State private var showingTechnique = false

    var body: some View {
        HStack(spacing: 14) {
            // Vertical accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: 44)

            // Title + muscle chip
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name.localized())
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5, weight: .bold))
                        .foregroundColor(accent)
                    Text(exercise.muscleGroup.rawValue)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundColor(accent)
                        .tracking(0.4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(accent.opacity(0.15))
                )
                .overlay(
                    Capsule().stroke(accent.opacity(0.3), lineWidth: 0.7)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onAdd() }

            // Add button (neon "+")
            Button(action: onAdd) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.accent,
                                    DesignSystem.Colors.accent.opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 32)
                        .shadow(color: DesignSystem.Colors.accent.opacity(0.45), radius: 6, x: 0, y: 3)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Info chevron → opens technique sheet
            Button {
                showingTechnique = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(accent.opacity(0.85))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, DesignSystem.Spacing.sm + 2)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.10),
                            DesignSystem.Colors.cardBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.15), radius: 8, x: 0, y: 3)
        .sheet(isPresented: $showingTechnique) {
            ExerciseTechniqueDetailView(exerciseName: exercise.name)
        }
    }
}

#Preview {
    ExerciseSelectionView { _ in }
}
