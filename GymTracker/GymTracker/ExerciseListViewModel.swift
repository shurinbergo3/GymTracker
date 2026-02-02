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
    @Published private(set) var groups: [ExerciseCategory: [LibraryExercise]] = [:]
    
    private var allExercises: [LibraryExercise] = []
    private let dataProvider: ExerciseDataProvider
    
    // Dependency Injection via Init
    // Init is robust and non-isolated to allow safe creation in Views
    init(dataProvider: ExerciseDataProvider = DefaultExerciseProvider()) {
        self.dataProvider = dataProvider
        let exercises = dataProvider.getExercises()
        self.allExercises = exercises
        // Initial grouping (computed directly to avoid calling MainActor-isolated updateGroups)
        self.groups = Dictionary(grouping: exercises, by: { $0.category })
    }
    
    @MainActor
    func updateGroups() {
        let filtered: [LibraryExercise]
        if searchText.isEmpty {
            filtered = allExercises
        } else {
            filtered = allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        self.groups = Dictionary(grouping: filtered, by: { $0.category })
    }
    
    // Call this when searchText changes
    @MainActor
    func search() {
        updateGroups()
    }
}
