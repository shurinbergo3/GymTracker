//
//  DataManagementView.swift
//  GymTracker
//
//  Created by Antigravity on 02.02.2026.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    
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
    
    // Force Upload states
    @State private var isUploading = false
    @State private var showingUploadConfirm = false
    @State private var showingUploadAlert = false
    @State private var uploadMessage = ""
    
    var body: some View {
        Form {
            Section {
                // Sync from cloud
                Button {
                    isRestoring = true
                    Task {
                        let result = await SyncManager.shared.restoreWorkoutsFromFirestore(container: modelContext.container)
                        await MainActor.run {
                            isRestoring = false
                            switch result {
                            case .success(let count):
                                if count == 0 {
                                    restoreMessage = "В облаке нет тренировок для загрузки или все уже синхронизировано"
                                } else {
                                    restoreMessage = "Загружено \(count) тренировок из облака"
                                }
                            case .failure(let error):
                                restoreMessage = error.localizedDescription
                            }
                            showingRestoreAlert = true
                        }
                    }
                } label: {
                    HStack {
                        if isRestoring {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundStyle(DesignSystem.Colors.accent)
                        }
                        Text("Синхронизировать из облака")
                            .foregroundStyle(isRestoring ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primaryText)
                    }
                }
                .disabled(isRestoring)
                
                // Load profile
                Button {
                    isRestoringProfile = true
                    Task {
                        await SyncManager.shared.restoreUserProfileFromFirestore(container: modelContext.container)
                        await MainActor.run {
                            isRestoringProfile = false
                            profileRestoreMessage = "Профиль успешно восстановлен из облака"
                            showingProfileRestoreAlert = true
                        }
                    }
                } label: {
                    HStack {
                        if isRestoringProfile {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "person.crop.circle.badge.clock")
                                .foregroundStyle(DesignSystem.Colors.accent)
                        }
                        Text("Загрузить профиль из базы")
                            .foregroundStyle(isRestoringProfile ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primaryText)
                    }
                }
                .disabled(isRestoringProfile)
                
                // Remove duplicates
                Button {
                    isDeduplicating = true
                    Task {
                        await performDeduplication()
                    }
                } label: {
                    HStack {
                        if isDeduplicating {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "trash.slash")
                                .foregroundStyle(.yellow)
                        }
                        Text("Удалить дубликаты из облака")
                            .foregroundStyle(isDeduplicating ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primaryText)
                    }
                }
                .disabled(isDeduplicating)
                
                // Force Upload (Local -> Cloud)
                Button {
                    showingUploadConfirm = true
                } label: {
                    HStack {
                        if isUploading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundStyle(.orange)
                        }
                        Text("Выгрузить в облако (Заменить)")
                            .foregroundStyle(isUploading ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primaryText)
                    }
                }
                .disabled(isUploading)
                
                // Delete all workouts (Destructive)
                Button(role: .destructive) {
                    showingDeleteWorkoutsConfirm = true
                } label: {
                    HStack {
                        if isDeletingWorkouts {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "trash")
                        }
                        Text("Удалить ВСЕ тренировки из облака")
                    }
                }
                .disabled(isDeletingWorkouts)
                
            } footer: {
                Text("🧹 'Удалить дубликаты' чистит копии в облаке.\n⬆️ 'Выгрузить в облако' ЗАМЕНИТ всё в облаке вашими текущими локальными тренировками.\n⚠️ Красная кнопка удалит вообще ВСЁ.")
                    .font(.caption2)
            }
        }
        .navigationTitle("Управление данными")
        .navigationBarTitleDisplayMode(.inline)
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
        .alert("Выгрузить в облако?", isPresented: $showingUploadConfirm) {
            Button("Отмена", role: .cancel) { }
            Button("Заменить облако", role: .destructive) {
                performForceUpload()
            }
        } message: {
            Text("ВНИМАНИЕ: Это действие удалит ВСЕ тренировки в облаке и заменит их вашими текущими локальными тренировками.\n\nИспользуйте это, если вы почистили историю на телефоне и хотите, чтобы в облаке стало так же.")
        }
        .alert("Результат выгрузки", isPresented: $showingUploadAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(uploadMessage)
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
    
    // MARK: - Helper Methods
    
    private func performForceUpload() {
        isUploading = true
        Task {
            let result = await SyncManager.shared.forceUploadToFirestore(container: modelContext.container)
            await MainActor.run {
                isUploading = false
                switch result {
                case .success(let count):
                    uploadMessage = "Успешно выгружено \(count) тренировок. Облако теперь совпадает с телефоном."
                case .failure(let error):
                    uploadMessage = error.localizedDescription
                }
                showingUploadAlert = true
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
            
            await MainActor.run {
                isDeduplicating = false
                dedupMessage = """
                Firestore: \(firestoreResult.removed) дубликатов удалено (\(firestoreResult.kept) уникальных сохранено)
                Локальная база: очищена
                """
                showingDedupAlert = true
            }
        } catch {
            await MainActor.run {
                isDeduplicating = false
                dedupMessage = "Ошибка: \(error.localizedDescription)"
                showingDedupAlert = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        DataManagementView()
            .modelContainer(for: [UserProfile.self, WorkoutSession.self, BodyMeasurement.self], inMemory: true)
    }
}
