//
//  UserProfileButton.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

struct UserProfileButton: View {
    @EnvironmentObject var authManager: AuthManager
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Neon Glow Background
                Circle()
                    .stroke(DesignSystem.Colors.accent, lineWidth: 2)
                    .background(Circle().fill(Color.black))
                    .shadow(color: DesignSystem.Colors.accent.opacity(0.8), radius: 8)
                    .frame(width: 36, height: 36)
                
                // Avatar inside
                Group {
                    if authManager.isLoggedIn, let user = authManager.currentUser {
                        if let photoURL = user.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } placeholder: {
                                Text(user.avatarInitials)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                        } else {
                            Text(user.avatarInitials)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
            }
        }
    }
}
