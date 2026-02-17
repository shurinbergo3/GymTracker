//
//  AuthenticationService.swift
//  GymTracker
//
//  Protocol for authentication operations (DIP)
//

import Foundation

/// Abstraction for authentication operations
/// Enables testing and multiple implementations (Firebase, Mock, etc.)
protocol AuthenticationService {
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws
    
    /// Create new account with email and password
    func signUp(email: String, password: String) async throws
    
    /// Sign in with Google OAuth
    func signInWithGoogle() async throws
    
    /// Sign out current user
    func signOut() throws
    
    /// Get current user ID
    var currentUserId: String? { get }
}
