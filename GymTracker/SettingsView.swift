//
//  SettingsView.swift
//  GymTracker
//
//  Created by Antigravity on 1/16/26.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isHealthSyncEnabled") private var isHealthSyncEnabled = true
    
    // Use EnvironmentObject provided by WorkoutTrackerApp
    @EnvironmentObject var authManager: AuthManager
    
    // User info
    private var userEmail: String? {
        Auth.auth().currentUser?.email
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Account
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(DesignSystem.Colors.primaryText)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userEmail ?? "Guest User")
                                .font(DesignSystem.Typography.headline())
                                .foregroundStyle(DesignSystem.Colors.primaryText)
                            
                            if let uid = Auth.auth().currentUser?.uid {
                                Text("ID: \(uid.prefix(6))...")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Button(action: {
                        authManager.signOut()
                        dismiss()
                    }) {
                        Text("Log Out")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Account")
                }
                
                // Section 2: Integrations
                Section {
                    Toggle(isOn: $isHealthSyncEnabled) {
                        VStack(alignment: .leading) {
                            Text("Sync with Apple Health")
                                .font(DesignSystem.Typography.body())
                                .foregroundStyle(DesignSystem.Colors.primaryText)
                        }
                    }
                    .tint(DesignSystem.Colors.accent)
                } header: {
                    Text("Integrations")
                } footer: {
                    Text("Enabling this will identify your workouts to Apple Health, counting calories and closing your Activity Rings. Note: Rings may not update *during* the session if the app is active.")
                }
                
                // Section 3: App Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
}
