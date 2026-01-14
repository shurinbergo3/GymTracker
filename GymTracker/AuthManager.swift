//
//  AuthManager.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let loggedInKey = "isLoggedIn"
    private let usernameKey = "username"
    
    struct User {
        let username: String
        let email: String
        let avatarInitials: String
    }
    
    init() {
        // Load state
        self.isLoggedIn = userDefaults.bool(forKey: loggedInKey)
        if let savedName = userDefaults.string(forKey: usernameKey), isLoggedIn {
            self.currentUser = User(
                username: savedName,
                email: "\(savedName.lowercased())@example.com",
                avatarInitials: String(savedName.prefix(2)).uppercased()
            )
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        // Imitate network delay
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        let username = email.components(separatedBy: "@").first ?? "User"
        
        self.currentUser = User(
            username: username,
            email: email,
            avatarInitials: String(username.prefix(2)).uppercased()
        )
        self.isLoggedIn = true
        
        userDefaults.set(true, forKey: loggedInKey)
        userDefaults.set(username, forKey: usernameKey)
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
         // Same logic for now, just a mock
        try await signInWithEmail(email: email, password: password)
    }
    
    func signInWithGoogle() async throws {
        // Mock Google Sign In
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        let username = "GoogleUser"
        let email = "google@example.com"
        
        self.currentUser = User(
            username: username,
            email: email,
            avatarInitials: "GU"
        )
        self.isLoggedIn = true
        
        userDefaults.set(true, forKey: loggedInKey)
        userDefaults.set(username, forKey: usernameKey)
    }
    
    func logout() {
        self.isLoggedIn = false
        self.currentUser = nil
        userDefaults.set(false, forKey: loggedInKey)
        userDefaults.removeObject(forKey: usernameKey)
    }
}
