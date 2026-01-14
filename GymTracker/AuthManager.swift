//
//  AuthManager.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import SwiftData

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
        guard FirebaseApp.app()?.options.clientID != nil else { return }
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("No root view controller found")
            return
        }
        
        // Start Google Sign In flow
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = gidSignInResult.user
        guard let idToken = user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: user.accessToken.tokenString)
        
        // Sign in to Firebase
        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user
        
        // Update local state
        self.currentUser = User(
            username: firebaseUser.displayName ?? "User",
            email: firebaseUser.email ?? "",
            avatarInitials: String((firebaseUser.displayName ?? "U").prefix(2)).uppercased()
        )
        self.isLoggedIn = true
        
        userDefaults.set(true, forKey: loggedInKey)
        if let name = firebaseUser.displayName {
            userDefaults.set(name, forKey: usernameKey)
        }
    }
    
    func logout() {
        self.isLoggedIn = false
        self.currentUser = nil
        userDefaults.set(false, forKey: loggedInKey)
        userDefaults.removeObject(forKey: usernameKey)
    }
    
    func deleteAccount(modelContext: ModelContext) async throws {
        // 1. Delete user from Firebase
        if let user = Auth.auth().currentUser {
            try await user.delete()
        }
        
        // 2. Clear SwiftData
        // Delete all persistent models
        try? modelContext.delete(model: WorkoutSession.self)
        try? modelContext.delete(model: UserProfile.self)
        try? modelContext.delete(model: BodyMeasurement.self)
        
        // 3. Clear Local State
        self.logout()
    }
}
