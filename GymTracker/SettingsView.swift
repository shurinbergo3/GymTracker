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
    
    // Restore states
    @State private var isRestoring = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    
    // Profile restore states
    @State private var isRestoringProfile = false
    @State private var showingProfileRestoreAlert = false
    @State private var profileRestoreMessage = ""
    
    // Deduplication states
    @State private var isDeduplicating = false
    @State private var showingDedupAlert = false
    @State private var dedupMessage = ""
    
    // Delete all workouts states
    @State private var isDeletingWorkouts = false
    @State private var showingDeleteWorkoutsConfirm = false
    @State private var showingDeleteWorkoutsAlert = false
    @State private var deleteWorkoutsMessage = ""
    
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
            .alert("sync_complete_title", isPresented: $showingRestoreAlert) {
                Button("ok_button", role: .cancel) { }
            } message: {
                Text(restoreMessage)
            }
            .alert("Профиль восстановлен", isPresented: $showingProfileRestoreAlert) {
                Button("ok_button", role: .cancel) { }
            } message: {
                Text(profileRestoreMessage)
            }
            .alert("Очистка завершена", isPresented: $showingDedupAlert) {
                Button("ok_button", role: .cancel) { }
            } message: {
                Text(dedupMessage)
            }
            .alert("Удалить ВСЕ тренировки?", isPresented: $showingDeleteWorkoutsConfirm) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    handleDeleteAllWorkouts()
                }
            } message: {
                Text("Это действие удалит ВСЕ тренировки из Firestore и локальной базы. Это нельзя отменить!")
            }
            .alert("Результат", isPresented: $showingDeleteWorkoutsAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteWorkoutsMessage)
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
            Button(action: {
                isRestoring = true
                Task {
                    await SyncManager.shared.restoreWorkoutsFromFirestore(container: modelContext.container)
                    await MainActor.run {
                        isRestoring = false
                        restoreMessage = "data_restore_complete_message"
                        showingRestoreAlert = true
                    }
                }
            }) {
                HStack {
                    if isRestoring {
                        ProgressView()
                            .padding(.trailing, 5)
                    }
                    Text("force_sync_button")
                }
            }
            .disabled(isRestoring)
            
            Button(action: {
                isRestoringProfile = true
                Task {
                    await SyncManager.shared.restoreUserProfileFromFirestore(container: modelContext.container)
                    await MainActor.run {
                        isRestoringProfile = false
                        profileRestoreMessage = "Профиль восстановлен (вес, рост, замеры)"
                        showingProfileRestoreAlert = true
                    }
                }
            }) {
                HStack {
                    if isRestoringProfile {
                        ProgressView()
                            .padding(.trailing, 5)
                    }
                    Text("Загрузить профиль из базы")
                }
            }
            .disabled(isRestoringProfile)
            
            Button(action: {
                isDeduplicating = true
                Task {
                    await performDeduplication()
                }
            }) {
                HStack {
                    if isDeduplicating {
                        ProgressView()
                            .padding(.trailing, 5)
                    }
                    Text("🧹 Удалить дубликаты из облака")
                }
            }
            .disabled(isDeduplicating)
            
            Button(role: .destructive, action: {
                showingDeleteWorkoutsConfirm = true
            }) {
                HStack {
                    if isDeletingWorkouts {
                        ProgressView()
                            .padding(.trailing, 5)
                    }
                    Text("🗑️ Удалить ВСЕ тренировки из облака")
                        .foregroundColor(.red)
                }
            }
            .disabled(isDeletingWorkouts)
        } header: {
            Text("data_management_section")
        } footer: {
            Text("🧹 Кнопка выше удаляет только дубликаты, оставляя уникальные тренировки\n⚠️ Красная кнопка ниже удалит ВСЕ тренировки безвозвратно!")
                .font(.caption2)
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
    
    private func handleDeleteAllWorkouts() {
        isDeletingWorkouts = true
        Task {
            do {
                let count = try await FirestoreManager.shared.deleteAllWorkouts()
                
                // Also delete local workouts
                let descriptor = FetchDescriptor<WorkoutSession>()
                let sessions = try modelContext.fetch(descriptor)
                for session in sessions {
                    modelContext.delete(session)
                }
                try modelContext.save()
                
                await MainActor.run {
                    isDeletingWorkouts = false
                    deleteWorkoutsMessage = "Удалено \(count) тренировок из облака и локальной базы"
                    showingDeleteWorkoutsAlert = true
                }
            } catch {
                await MainActor.run {
                    isDeletingWorkouts = false
                    deleteWorkoutsMessage = "Ошибка: \(error.localizedDescription)"
                    showingDeleteWorkoutsAlert = true
                }
            }
        }
    }
    
    private func performDeduplication() async {
        do {
            // First remove duplicates from Firestore
            let firestoreResult = try await FirestoreManager.shared.removeDuplicateWorkoutsFromFirestore()
            
            // Then remove local duplicates
            await SyncManager.shared.removeDuplicateWorkouts(container: modelContext.container)
            
            let removedCount: Int = firestoreResult.removed
            let totalCount: Int = firestoreResult.total
            let keptCount: Int = firestoreResult.kept
            
            await MainActor.run {
                isDeduplicating = false
                dedupMessage = "Облако: удалено \(removedCount) дублей из \(totalCount) тренировок\nОставлено уникальных: \(keptCount)\nЛокальные дубликаты также удалены"
                showingDedupAlert = true
            }
        } catch {
            let errorMsg: String = error.localizedDescription
            await MainActor.run {
                isDeduplicating = false
                dedupMessage = "Ошибка: \(errorMsg)"
                showingDedupAlert = true
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
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, BodyMeasurement.self], inMemory: true)
}
