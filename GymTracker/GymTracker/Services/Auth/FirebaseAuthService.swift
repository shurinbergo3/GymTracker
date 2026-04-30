//
//  FirebaseAuthService.swift
//  GymTracker
//
//  Firebase implementation of AuthenticationService (SRP: Only authentication)
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

/// Firebase implementation of authentication
/// Single Responsibility: Handle Firebase authentication only
final class FirebaseAuthService: AuthenticationService {
    
    // MARK: - AuthenticationService Protocol
    
    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(
            withEmail: email,
            password: password
        )
        try await setDisplayName(for: result.user, from: email)
    }
    
    func signInWithGoogle() async throws {
        guard let clientID = getFirebaseClientID() else {
            throw AuthError.missingClientID
        }
        
        guard let rootViewController = getRootViewController() else {
            throw AuthError.noRootViewController
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let signInResult = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        )
        
        let credential = try createGoogleCredential(from: signInResult.user)
        _ = try await Auth.auth().signIn(with: credential)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Private Helpers (Keep methods <10 lines)
    
    private func setDisplayName(for user: FirebaseAuth.User, from email: String) async throws {
        let request = user.createProfileChangeRequest()
        request.displayName = extractUsername(from: email)
        try await request.commitChanges()
    }
    
    private func extractUsername(from email: String) -> String {
        email.components(separatedBy: "@").first ?? "User"
    }
    
    private func getFirebaseClientID() -> String? {
        FirebaseApp.app()?.options.clientID
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    private func createGoogleCredential(from user: GIDGoogleUser) throws -> AuthCredential {
        // SECURITY/STABILITY: раньше тут был fatalError(), что роняло приложение,
        // если Google вернул пользователя без idToken. Теперь возвращаем typed error.
        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.missingIDToken
        }

        return GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )
    }
}

// MARK: - Error Types

enum AuthError: Error {
    case missingClientID
    case noRootViewController
    case missingIDToken
}
