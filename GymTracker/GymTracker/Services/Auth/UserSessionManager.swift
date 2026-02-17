//
//  UserSessionManager.swift
//  GymTracker
//
//  Manages user session state (SRP: Only state management)
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

/// Manages user session state
/// Single Responsibility: Track and publish user state
@MainActor
final class UserSessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    private let storage: UserDefaults
    private let loggedInKey = "isLoggedIn"
    private let usernameKey = "username"
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    struct User {
        let uid: String
        let username: String
        let email: String
        let avatarInitials: String
        let photoURL: URL?
    }
    
    init(storage: UserDefaults = .standard) {
        self.storage = storage
        setupAuthListener()
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                self?.handleAuthChange(firebaseUser)
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func handleAuthChange(_ firebaseUser: FirebaseAuth.User?) {
        guard let firebaseUser = firebaseUser else {
            clearUserState()
            return
        }
        updateUserState(with: firebaseUser)
    }
    
    private func updateUserState(with firebaseUser: FirebaseAuth.User) {
        let name = firebaseUser.displayName ?? "User"
        let email = firebaseUser.email ?? ""
        
        currentUser = User(
            uid: firebaseUser.uid,
            username: name,
            email: email,
            avatarInitials: createInitials(from: name),
            photoURL: firebaseUser.photoURL
        )
        
        isLoggedIn = true
        storage.set(true, forKey: loggedInKey)
        storage.set(name, forKey: usernameKey)
    }
    
    private func clearUserState() {
        isLoggedIn = false
        currentUser = nil
        storage.set(false, forKey: loggedInKey)
    }
    
    private func createInitials(from name: String) -> String {
        String(name.prefix(2)).uppercased()
    }
}
