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
    
    private var addCustomExerciseButton: some View {
        Section {
            Button(action: { showingCustomExercise = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    Text("Добавить своё упражнение")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
        }
    }
    
    private var exerciseList: some View {
        List {
            addCustomExerciseButton
            
            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                if let exercises = groupedExercises[category], !exercises.isEmpty {
                    Section {
                        ForEach(exercises) { exercise in
                            ExerciseRow(exercise: exercise) {
                                onExerciseSelected(exercise)
                                dismiss()
                            }
                        }
                    } header: {
                        Label(category.rawValue, systemImage: category.icon)
                            .font(DesignSystem.Typography.headline())
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Поиск упражнений"
        )
    }
    
    var body: some View {
        NavigationStack {
            exerciseList
                .navigationTitle("Выбор упражнения")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            dismiss()
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

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: LibraryExercise
    let onSelect: () -> Void
    @State private var showingTechnique = false
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(exercise.name)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(exercise.muscleGroup.rawValue)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(DesignSystem.Colors.accent)
                        .font(.title3)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Info button for technique
            Button(action: { showingTechnique = true }) {
                Image(systemName: "info.circle")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .font(.body)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .sheet(isPresented: $showingTechnique) {
            TechniqueInfoSheet(exercise: exercise)
        }
    }
}

// MARK: - Technique Info Sheet

struct TechniqueInfoSheet: View {
    let exercise: LibraryExercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                        // Exercise name
                        Text(exercise.name)
                            .font(DesignSystem.Typography.largeTitle())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        // Category and muscle group
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: exercise.category.icon)
                            Text(exercise.muscleGroup.rawValue)
                        }
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        Divider()
                            .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        // Technique description in CardView
                        if let technique = exercise.technique {
                            CardView {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(DesignSystem.Colors.neonGreen)
                                            .font(.title2)
                                        Text("Техника выполнения")
                                            .font(DesignSystem.Typography.title3())
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                    }
                                    
                                    Text(technique)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(Color.white.opacity(0.85))
                                        .lineSpacing(4)
                                }
                                .padding(DesignSystem.Spacing.xl)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                        
                        // YouTube button - always show
                        Button(action: openYouTubeSearch) {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                
                                Text("Посмотреть технику на YouTube")
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            .padding(DesignSystem.Spacing.lg)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.large)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Информация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openYouTubeSearch() {
        let searchQuery = "\(exercise.name) техника выполнения"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let youtubeURL = URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)") {
            UIApplication.shared.open(youtubeURL)
        }
    }
}

#Preview {
    ExerciseSelectionView { exercise in
        print("Selected: \(exercise.name)")
    }
}
