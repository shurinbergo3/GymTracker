//
//  ExerciseListView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct ExerciseListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
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
            List {
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    if let exercises = groupedExercises[category], !exercises.isEmpty {
                        Section {
                            ForEach(exercises) { exercise in
                                ExerciseListRow(exercise: exercise)
                            }
                        } header: {
                            Label(category.rawValue, systemImage: category.icon)
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(DesignSystem.Colors.accent)
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
            .navigationTitle("Упражнения")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExerciseListRow: View {
    let exercise: LibraryExercise
    @State private var showingTechnique = false
    
    var body: some View {
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
            
            // Info button for technique
            Button(action: { showingTechnique = true }) {
                Image(systemName: "info.circle")
                    .foregroundColor(DesignSystem.Colors.accent)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .sheet(isPresented: $showingTechnique) {
            TechniqueInfoSheet(exercise: exercise)
        }
    }
}

#Preview {
    ExerciseListView()
}
