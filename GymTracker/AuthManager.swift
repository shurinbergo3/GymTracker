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
        let uid: String
        let username: String
        let email: String
        let avatarInitials: String
        let photoURL: URL?
    }

    init() {
        // Setup Firebase Auth Listener
        _ = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let firebaseUser = firebaseUser {
                    self.updateUserState(with: firebaseUser)
                } else {
                    self.isLoggedIn = false
                    self.currentUser = nil
                    self.userDefaults.set(false, forKey: self.loggedInKey)
                }
            }
        }
    }
    
    private func updateUserState(with firebaseUser: FirebaseAuth.User) {
        let name = firebaseUser.displayName ?? "User"
        let email = firebaseUser.email ?? ""
        let initials = String(name.prefix(2)).uppercased()
        
        self.currentUser = User(
            uid: firebaseUser.uid,
            username: name,
            email: email,
            avatarInitials: initials,
            photoURL: firebaseUser.photoURL
        )
        self.isLoggedIn = true
        self.userDefaults.set(true, forKey: loggedInKey)
        self.userDefaults.set(name, forKey: usernameKey)
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
        // State listener will update UI
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        // Optionally set a default display name here if needed
        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = email.components(separatedBy: "@").first ?? "User"
        try await changeRequest.commitChanges()
        
        // State listener will update UI, but might need to wait for change request?
        // Usually listener firers on user change.
        // We manually update just in case to reflect name immediately
        updateUserState(with: authResult.user)
    }
    
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("No root view controller found")
            return
        }
        
        // Start Google Sign In flow
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = gidSignInResult.user
        guard let idToken = user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: user.accessToken.tokenString)
        
        // Sign in to Firebase
        _ = try await Auth.auth().signIn(with: credential)
        // State listener will update UI
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            // Listener will handle clearing state
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // Alias for SettingsView compatibility
    func signOut() {
        logout()
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
