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
                            Text(userEmail ?? "Гость")
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
                        Text("Выйти")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Аккаунт")
                }
                
                // Section 2: Integrations
                Section {
                    Toggle(isOn: $isHealthSyncEnabled) {
                        VStack(alignment: .leading) {
                            Text("Синхронизация с Apple Health")
                                .font(DesignSystem.Typography.body())
                                .foregroundStyle(DesignSystem.Colors.primaryText)
                        }
                    }
                    .tint(DesignSystem.Colors.accent)
                } header: {
                    Text("Интеграции")
                } footer: {
                    Text("Включение этой опции позволит синхронизировать ваши тренировки с Apple Health, считать калории и закрывать кольца активности.")
                }
                
                // Section 3: App Info
                Section {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                } header: {
                    Text("О приложении")
                }
                
                // Section 4: Danger Zone
                Section {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Text("Удалить аккаунт")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .alert("Удалить аккаунт?", isPresented: $showingDeleteConfirmation) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    Task {
                        try? await authManager.deleteAccount(modelContext: modelContext)
                        dismiss()
                    }
                }
            } message: {
                Text("Это действие необратимо. Все ваши данные будут удалены.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, BodyMeasurement.self], inMemory: true)
}
