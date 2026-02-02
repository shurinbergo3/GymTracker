//
//  SettingsView.swift
//  GymTracker
//
//  Created by Antigravity on 1/16/26.
//

import SwiftUI
import FirebaseAuth
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isHealthSyncEnabled") private var isHealthSyncEnabled = true
    
    // Use EnvironmentObject provided by WorkoutTrackerApp
    @EnvironmentObject var authManager: AuthManager
    
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var requiresReauth = false
    

    
    // User info
    private var userEmail: String? {
        Auth.auth().currentUser?.email
    }
    
    var body: some View {
        NavigationStack {
            Form {
                accountSection
                integrationsSection
                appInfoSection
                supportSection
                dataManagementSection
                dangerZoneSection
            }
            .navigationTitle("settings_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done_button") {
                        dismiss()
                    }
                }
            }
            .alert("delete_account_alert_title", isPresented: $showingDeleteConfirmation) {
                Button("cancel_button", role: .cancel) { }
                Button("delete_button", role: .destructive) {
                    Task {
                        await handleAccountDeletion()
                    }
                }
            } message: {
                Text("delete_account_message")
            }
            .alert("delete_error_title", isPresented: $showingDeleteError) {
                if requiresReauth {
                    Button("relogin_button") {
                        authManager.signOut()
                        dismiss()
                    }
                    Button("cancel_button", role: .cancel) {
                        requiresReauth = false
                    }
                } else {
                    Button("ok_button", role: .cancel) { }
                }
            } message: {
                Text(deleteErrorMessage)
            }

        }
    }
    
    // MARK: - Sections
    
    private var accountSection: some View {
        Section {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userEmail ?? String(localized: "guest_user"))
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
                Text("sign_out_button")
                    .foregroundStyle(.red)
            }
        } header: {
            Text("account_section")
        }
    }
    
    private var integrationsSection: some View {
        Section {
            Toggle(isOn: $isHealthSyncEnabled) {
                VStack(alignment: .leading) {
                    Text("apple_health_sync_toggle")
                        .font(DesignSystem.Typography.body())
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                }
            }
            .tint(Color.purple.opacity(0.8))
        } header: {
            Text("integrations_section")
        } footer: {
            Text("health_sync_footer")
        }
    }
    
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("version_label")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        } header: {
            Text("about_section")
        }
    }
    
    private var supportSection: some View {
        Section {
            Link(destination: URL(string: "https://t.me/sumotry")!) {
                HStack {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(DesignSystem.Colors.accent)
                    Text("contact_developer")
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
            }
        } header: {
            Text("support_section")
        } footer: {
            Text("telegram_contact_footer")
        }
    }
    
    private var dataManagementSection: some View {
        Section {
            NavigationLink(destination: DataManagementView()) {
                HStack {
                    Image(systemName: "externaldrive.badge.icloud")
                        .foregroundStyle(DesignSystem.Colors.accent)
                    Text("Управление данными")
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                }
            }
        } header: {
            Text("Облако и Данные")
        }
    }
    
    
    private var dangerZoneSection: some View {
        Section {
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Text("delete_account_button")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
    

    
    private func handleAccountDeletion() async {
        do {
            try await authManager.deleteAccount(modelContext: modelContext)
            // Success - user will be automatically logged out
            await MainActor.run {
                dismiss()
            }
        } catch let error as NSError {
            await MainActor.run {
                // Check if reauthentication is required
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    requiresReauth = true
                    deleteErrorMessage = error.localizedRecoverySuggestion ?? String(localized: "relogin_message")
                } else {
                    requiresReauth = false
                    deleteErrorMessage = "\(String(localized: "delete_failed_prefix")): \(error.localizedDescription)"
                }
                showingDeleteError = true
            }
        }
    }
    
    // MARK: - Data Management Helpers
    
    // Data Management Helpers have been moved to DataManagementView.swift
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, BodyMeasurement.self], inMemory: true)
}
