//
//  ExerciseSelectionView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingCustomExercise = false
    @State private var customExerciseName = ""
    
    let onExerciseSelected: (LibraryExercise) -> Void
    
    private var filteredExercises: [LibraryExercise] {
        if searchText.isEmpty {
            return ExerciseLibrary.allExercises
        }
        return ExerciseLibrary.search(searchText)
    }
    
    private var groupedExercises: [ExerciseCategory: [LibraryExercise]] {
        Dictionary(grouping: filteredExercises, by: { $0.category })
    }
    
    var body: some View {
        NavigationStack {
            exerciseList
                .background(DesignSystem.Colors.background)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Поиск упражнений"
                )
                .navigationTitle("Выбор упражнения")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingCustomExercise = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .alert("Новое упражнение", isPresented: $showingCustomExercise) {
                    TextField("Название упражнения", text: $customExerciseName)
                    Button("Отмена", role: .cancel) {
                        customExerciseName = ""
                    }
                    Button("Добавить") {
                        addCustomExercise()
                    }
                } message: {
                    Text("Введите название своего упражнения")
                }
        }
    }
    
    @ViewBuilder
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm, pinnedViews: [.sectionHeaders]) {
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    if let exercises = groupedExercises[category], !exercises.isEmpty {
                        Section {
                            VStack(spacing: 0) {
                                ForEach(exercises) { exercise in
                                    SelectionRow(exercise: exercise) {
                                        onExerciseSelected(exercise)
                                        dismiss()
                                    }
                                    
                                    if exercise.id != exercises.last?.id {
                                        Divider()
                                            .padding(.leading, DesignSystem.Spacing.md)
                                    }
                                }
                            }
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                        } header: {
                            HStack {
                                Label(category.rawValue, systemImage: category.icon)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .padding(.vertical, DesignSystem.Spacing.xs)
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.background)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
    }
    
    private func addCustomExercise() {
        guard !customExerciseName.isEmpty else { return }
        
        let customExercise = LibraryExercise(
            name: customExerciseName,
            category: .arms,
            muscleGroup: .biceps
        )
        onExerciseSelected(customExercise)
        customExerciseName = ""
        dismiss()
    }
}

// MARK: - Selection Row (Styled like ExerciseListRow)
struct SelectionRow: View {
    let exercise: LibraryExercise
    let onSelect: () -> Void
    @State private var showingTechnique = false
    @Environment(\.openURL) var openURL
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(exercise.name)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(exercise.muscleGroup.rawValue)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Add Button (Visual indicator)
            Button(action: onSelect) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(DesignSystem.Colors.accent)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 8)
            
            // Info Button
            Button(action: { showingTechnique = true }) {
                Image(systemName: "info.circle")
                    .foregroundColor(DesignSystem.Colors.secondaryText) // Distinct color for info
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, DesignSystem.Spacing.md) // Increased padding for touch targets
        .padding(.horizontal, DesignSystem.Spacing.md)
        .sheet(isPresented: $showingTechnique) {
            ExerciseTechniqueDetailView(exerciseName: exercise.name)
        }
    }
    
    private func youtubeSearchURL(for exerciseName: String) -> URL? {
        let searchQuery = "\(exerciseName) техника"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)")
    }
}

#Preview {
    ExerciseSelectionView { _ in }
}

