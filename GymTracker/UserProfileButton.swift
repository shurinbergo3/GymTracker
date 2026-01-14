//
//  UserProfileButton.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

struct UserProfileButton: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAuth = false
    
    var body: some View {
        Button(action: { showingAuth = true }) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(DesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                    )
                
                if authManager.isLoggedIn, let user = authManager.currentUser {
                    Text(user.avatarInitials)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.accent)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
        .sheet(isPresented: $showingAuth) {
            AuthView()
        }
    }
}
