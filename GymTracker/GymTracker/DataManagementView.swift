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
    @State private var restoreProgress = ""
    

    
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
                // Sync from cloud (Full Restore)
                Button {
                    isRestoring = true
                    restoreProgress = "Загрузка..."
                    Task.detached(priority: .userInitiated) {
                        // Run in detached task to avoid blocking
                        let message = await SyncManager.shared.restoreAllData(container: modelContext.container)
                        
                        await MainActor.run {
                            isRestoring = false
                            restoreProgress = ""
                            restoreMessage = message
                            showingRestoreAlert = true
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if isRestoring {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "icloud.and.arrow.down")
                                    .foregroundStyle(DesignSystem.Colors.accent)
                            }
                            Text("Полная синхронизация (Всё)")
                                .foregroundStyle(isRestoring ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primaryText)
                        }
                        
                        if isRestoring && !restoreProgress.isEmpty {
                            Text(restoreProgress)
                                .font(.caption2)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
                .disabled(isRestoring)
                

                
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
                Text("⬆️ 'Выгрузить в облако' ЗАМЕНИТ всё в облаке вашими текущими локальными тренировками.\n⚠️ Красная кнопка удалит вообще ВСЁ.")
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
    

}

#Preview {
    NavigationStack {
        DataManagementView()
            .modelContainer(for: [UserProfile.self, WorkoutSession.self, BodyMeasurement.self], inMemory: true)
    }
}
