//
//  ExerciseListViewModel.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import Combine

// Protocol for Data Provider (DIP)
protocol ExerciseDataProvider {
    func getExercises() -> [LibraryExercise]
}

// Default implementation wrapper
struct DefaultExerciseProvider: ExerciseDataProvider {
    func getExercises() -> [LibraryExercise] {
        return ExerciseLibrary.allExercises
    }
}

class ExerciseListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: ExerciseCategory? = nil
    @Published private(set) var groups: [ExerciseCategory: [LibraryExercise]] = [:]
    @Published private(set) var availableCategories: [ExerciseCategory] = []

    private var allExercises: [LibraryExercise] = []
    private let dataProvider: ExerciseDataProvider

    // Dependency Injection via Init
    // Init is robust and non-isolated to allow safe creation in Views
    init(dataProvider: ExerciseDataProvider = DefaultExerciseProvider()) {
        self.dataProvider = dataProvider
        let exercises = dataProvider.getExercises()
        self.allExercises = exercises
        // Initial grouping (computed directly to avoid calling MainActor-isolated updateGroups)
        let grouped = Dictionary(grouping: exercises, by: { $0.category })
        self.groups = grouped
        self.availableCategories = ExerciseCategory.allCases.filter { grouped[$0]?.isEmpty == false }
    }

    @MainActor
    func updateGroups() {
        var filtered = allExercises
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        self.groups = Dictionary(grouping: filtered, by: { $0.category })
    }

    // Call this when searchText changes
    @MainActor
    func search() {
        updateGroups()
    }

    @MainActor
    func selectCategory(_ category: ExerciseCategory?) {
        selectedCategory = category
        updateGroups()
    }
}
