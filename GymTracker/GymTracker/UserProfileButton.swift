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
                 // Background
                 Circle()
                     .fill(DesignSystem.Colors.cardBackground)
                 
                 // Content (Avatar or Initials)
                 if authManager.isLoggedIn, let user = authManager.currentUser {
                     Group {
                         if let photoURL = user.photoURL {
                             AsyncImage(url: photoURL) { image in
                                 image
                                     .resizable()
                                     .aspectRatio(contentMode: .fill)
                             } placeholder: {
                                 Text(user.avatarInitials)
                                     .font(.system(size: 14, weight: .semibold, design: .rounded))
                                     .foregroundColor(DesignSystem.Colors.primaryText)
                             }
                         } else {
                             Text(user.avatarInitials)
                                 .font(.system(size: 14, weight: .semibold, design: .rounded))
                                 .foregroundColor(DesignSystem.Colors.primaryText)
                         }
                     }
                     .clipShape(Circle())
                 } else {
                     Image(systemName: "person.fill")
                         .font(.system(size: 16))
                         .foregroundColor(DesignSystem.Colors.secondaryText)
                 }
                 
                 // Elegant Border (Apple-style + App Accent)
                 Circle()
                     .strokeBorder(DesignSystem.Colors.neonGreen.opacity(0.8), lineWidth: 2)
             }
             .frame(width: 36, height: 36)
             // Subtle shadow for depth, not glow
             .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}
