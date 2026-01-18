//
//  ExerciseListViewModel.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import Combine

@MainActor
class ExerciseListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var groups: [ExerciseCategory: [LibraryExercise]] = [:]
    
    private var allExercises: [LibraryExercise] = []
    
    init() {
        self.allExercises = ExerciseLibrary.allExercises
        // Initial grouping
        updateGroups()
    }
    
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
    func search() {
        updateGroups()
    }
}
