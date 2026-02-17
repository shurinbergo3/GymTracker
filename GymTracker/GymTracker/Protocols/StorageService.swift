//
//  StorageService.swift
//  GymTracker
//
//  Protocol for cloud storage operations (DIP)
//

import Foundation

/// Abstraction for cloud storage operations (Firestore)
protocol StorageService {
    // MARK: - Workouts
    
    /// Save workout to cloud storage
    func saveWorkout(_ workout: Workout) async throws
    
    /// Fetch all workouts from cloud storage
    func fetchWorkouts() async throws -> [Workout]
    
    /// Delete all workouts from cloud storage
    func deleteAllWorkouts() async throws -> Int
    
    /// Remove duplicate workouts
    func removeDuplicateWorkouts() async throws -> (total: Int, removed: Int, kept: Int)
    
    // MARK: - Programs
    
    /// Save program to cloud storage
    func saveProgram(_ program: ProgramDTO) async throws
    
    /// Fetch all programs from cloud storage
    func fetchPrograms() async throws -> [ProgramDTO]
    
    /// Delete program from cloud storage
    func deleteProgram(id: String) async throws
    
    // MARK: - User Data
    
    /// Delete all user data from cloud storage
    func deleteUserDocument(uid: String) async throws
}
