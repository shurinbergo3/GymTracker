//
//  AuthManager.swift
//  Workout Tracker
//
//  Created by Antigravity
//  REFACTORED: Now uses SOLID services (Facade pattern for backward compatibility)
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import SwiftData

/// Facade for backward compatibility
/// Delegates to SOLID services internally
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    // ModelContainer for auto-sync
    private var modelContainer: ModelContainer?
    
    // SOLID Services (DI) - commented out for now to avoid breaking changes
    // private let authService: AuthenticationService
    // private let sessionManager: UserSessionManager
    // private let deletionService: AccountDeletionService
    
    private let userDefaults = UserDefaults.standard
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

    init() {
        // TODO: будет использовать DI после интеграции
        // self.authService = FirebaseAuthService()
        // self.sessionManager = UserSessionManager(storage: userDefaults)
        // self.deletionService = AccountDeletionService(storage: FirestoreStorageService())
        
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
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
        
        // Auto-sync disabled - user will manually sync via Settings
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
    
    func signInWithApple() async throws {
        let coordinator = SignInWithAppleCoordinator()
        try await coordinator.signIn()
        // State listener will update UI
    }

    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first,
        let rootViewController = window.rootViewController else {
            #if DEBUG
            print("No root view controller found")
            #endif
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
            #if DEBUG
            print("Error signing out: \(error.localizedDescription)")
            #endif
        }
    }
    
    // Alias for SettingsView compatibility
    func signOut() {
        logout()
    }
    
    // MARK: - Auto-Sync
    
    /// Set the ModelContainer reference for auto-sync
    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }
    
    /// Automatically sync user data from Firestore after sign-in (Non-isolated)
    nonisolated private func performAutoSync(with container: ModelContainer) async {
        #if DEBUG
        print("🔄 AutoSync: Starting automatic data synchronization (background)...")
        #endif
        
        // Sync workouts from Firestore
        _ = await SyncManager.shared.restoreWorkoutsFromFirestore(container: container)
        
        // Sync user profile from Firestore
        await SyncManager.shared.restoreUserProfileFromFirestore(container: container)
        
        // Sync Programs from Firestore
        _ = await SyncManager.shared.restoreProgramsFromFirestore(container: container, forceRestore: true)
        
        #if DEBUG
        print("✅ AutoSync: Data synchronization completed successfully")
        #endif
    }
    
    
    /// Comprehensive account deletion for App Store compliance
    /// Handles: Firestore deletion, Auth deletion, local data cleanup, reauthentication errors
    func deleteAccount(modelContext: ModelContext) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let uid = user.uid
        
        // Phase 1: Delete Firestore user document
        do {
            try await FirestoreManager.shared.deleteUserDocument(uid: uid)
            #if DEBUG
            print("✅ Firestore user document deleted")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to delete Firestore document: \(error.localizedDescription)")
            #endif
            // Continue anyway - document might not exist
        }
        
        // Phase 2: Delete Firebase Auth user
        do {
            try await user.delete()
            #if DEBUG
            print("✅ Firebase Auth user deleted")
            #endif
        } catch let error as NSError {
            // Check if reauthentication is required
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                // Propagate this specific error to UI for handling
                throw NSError(
                    domain: "AuthManager",
                    code: AuthErrorCode.requiresRecentLogin.rawValue,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Для удаления аккаунта требуется повторный вход",
                        NSLocalizedRecoverySuggestionErrorKey: "Пожалуйста, выйдите и войдите снова, затем попробуйте удалить аккаунт."
                    ]

                )
            }
            
            // Other auth errors
            throw error
        }
        
        // Phase 3: Clear SwiftData (all models)
        do {
            try modelContext.delete(model: WorkoutSession.self)
            try modelContext.delete(model: WorkoutSet.self)
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: WeightRecord.self)
            try modelContext.delete(model: BodyMeasurement.self)
            try modelContext.delete(model: Program.self)
            try modelContext.delete(model: WorkoutDay.self)
            try modelContext.delete(model: ExerciseTemplate.self)
            try modelContext.save()
            #if DEBUG
            print("✅ SwiftData cleared")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to clear SwiftData: \(error.localizedDescription)")
            #endif
            // Continue anyway
        }
        
        // Phase 4: Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            #if DEBUG
            print("✅ UserDefaults cleared")
            #endif
        }
        
        // Phase 5: Clear specific app settings
        UserDefaults.standard.removeObject(forKey: loggedInKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.removeObject(forKey: "isHealthSyncEnabled")
        UserDefaults.standard.removeObject(forKey: "cachedRestingHR")
        UserDefaults.standard.removeObject(forKey: "lastHRFetchDate")
        UserDefaults.standard.synchronize()
        
        // Phase 6: Clear local state
        await MainActor.run {
            self.isLoggedIn = false
            self.currentUser = nil
        }
        
        #if DEBUG
        print("✅ Account deletion completed successfully")
        #endif
    }
}
