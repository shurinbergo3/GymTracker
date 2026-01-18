//
//  ExerciseListView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct ExerciseListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExerciseListViewModel()
    
    var body: some View {
        NavigationStack {
            exerciseList
                .background(DesignSystem.Colors.background)
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Поиск упражнений"
                )
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.search()
                }
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
    
    @ViewBuilder
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm, pinnedViews: [.sectionHeaders]) {
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    exerciseSection(for: category)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
    }
    
    @ViewBuilder
    private func exerciseSection(for category: ExerciseCategory) -> some View {
        if let exercises = viewModel.groups[category], !exercises.isEmpty {
            Section {
                VStack(spacing: 0) {
                    ForEach(exercises) { exercise in
                        ExerciseListRow(exercise: exercise)
                        
                        if exercise.id != exercises.last?.id {
                            Divider()
                                .padding(.leading, DesignSystem.Spacing.md)
                        }
                    }
                }
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            } header: {
                sectionHeader(for: category)
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader(for category: ExerciseCategory) -> some View {
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
            
            Button(action: { showingTechnique = true }) {
                Image(systemName: "info.circle")
                    .foregroundColor(DesignSystem.Colors.accent)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .sheet(isPresented: $showingTechnique) {
            ExerciseTechniqueDetailView(exerciseName: exercise.name)
        }
    }
}

#Preview {
    ExerciseListView()
}
