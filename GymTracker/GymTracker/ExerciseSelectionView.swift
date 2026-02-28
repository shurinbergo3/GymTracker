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
    @Environment(\.modelContext) private var modelContext  // Added for SwiftData
    @State private var searchText = ""
    @State private var showingCustomExercise = false
    @State private var customExerciseName = ""
    @State private var expandedCategories: Set<ExerciseCategory> = Set(ExerciseCategory.allCases) // All expanded by default
    
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
                    prompt: "search_exercises_placeholder"
                )
                .navigationTitle("exercise_selection_title".localized())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("cancel_button") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingCustomExercise = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .alert("new_exercise_title", isPresented: $showingCustomExercise) {
                    TextField("exercise_name_placeholder", text: $customExerciseName)
                    Button("cancel_button", role: .cancel) {
                        customExerciseName = ""
                    }
                    Button("add_button") {
                        addCustomExercise()
                    }
                } message: {
                    Text("enter_exercise_name_message")
                }
        }
    }
    
    @ViewBuilder
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm, pinnedViews: [.sectionHeaders]) {
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    if let exercises = groupedExercises[category], !exercises.isEmpty {
                        let isExpanded = expandedCategories.contains(category)
                        
                        Section {
                            if isExpanded {
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
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        } header: {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if expandedCategories.contains(category) {
                                        expandedCategories.remove(category)
                                    } else {
                                        expandedCategories.insert(category)
                                    }
                                }
                            }) {
                                HStack {
                                    Label(category.rawValue, systemImage: category.icon)
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(DesignSystem.Colors.accent)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                                    
                                    Text("(\(exercises.count))")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .background(DesignSystem.Colors.cardBackground.opacity(0.5))
                                .cornerRadius(DesignSystem.CornerRadius.small)
                            }
                            .buttonStyle(PlainButtonStyle())
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
            category: .custom,     // User-created exercises go to custom category
            muscleGroup: .fullBody // Default muscle group for custom exercises
        )
        
        // Save to SwiftData
        let customExerciseModel = CustomExercise(from: customExercise)
        modelContext.insert(customExerciseModel)
        
        // Trigger async sync to Firestore
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
                    Text(exercise.name.localized())
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
        let localizedName = exerciseName.localized()
        let suffix = LanguageManager.shared.currentLanguageCode == "en" ? "technique" : "техника"
        let searchQuery = "\(localizedName) \(suffix)"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)")
    }
}

#Preview {
    ExerciseSelectionView { _ in }
}

