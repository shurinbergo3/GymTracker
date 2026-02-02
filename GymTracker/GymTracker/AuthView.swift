//
//  AuthView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext // Add modelContext environment
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var isRegistration = false
    @State private var showDeleteConfirmation = false // State for alert
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if authManager.isLoggedIn, let user = authManager.currentUser {
                    // MARK: - Profile View
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        Spacer()
                        
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(DesignSystem.Colors.accent)
                                .frame(width: 100, height: 100)
                            
                            if let photoURL = user.photoURL {
                                AsyncImage(url: photoURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Text(user.avatarInitials)
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            } else {
                                Text(user.avatarInitials)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .shadow(color: DesignSystem.Colors.accent.opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        // User Info
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Text(user.username)
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text(user.email)
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Actions
                        Button(action: {
                            authManager.logout()
                        }) {
                            Text("Выйти")
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        
                        // Delete Account Button
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Text("Удалить аккаунт из системы")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(.red)
                        }
                        .padding(.top, DesignSystem.Spacing.sm)
                        
                        // Contact Developer Link
                        Link(destination: URL(string: "https://t.me/sumotry")!) {
                            Text("Связаться с разработчиком")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .padding(.top, 4)
                        
                        Spacer()
                    }
                } else {
                    // MARK: - Login View
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Text(isRegistration ? "Регистрация" : "Вход")
                            .font(DesignSystem.Typography.largeTitle())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(.top, DesignSystem.Spacing.xxl)
                        
                        VStack(spacing: DesignSystem.Spacing.md) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(DesignSystem.Colors.cardBackground)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            SecureField("Пароль", text: $password)
                                .padding()
                                .background(DesignSystem.Colors.cardBackground)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        
                        if isLoading {
                            ProgressView()
                                .tint(DesignSystem.Colors.accent)
                        } else {
                            Button(action: performAction) {
                                Text(isRegistration ? "Зарегистрироваться" : "Войти")
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(DesignSystem.Colors.neonGreen)
                                    .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.xl)
                            .disabled(email.isEmpty || password.isEmpty)
                        }
                        
                        Button(action: { isRegistration.toggle() }) {
                            Text(isRegistration ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                                .font(DesignSystem.Typography.subheadline())
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.3))
                            Text("ИЛИ")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Rectangle().frame(height: 1).foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.3))
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        
                        // Google Button
                        Button(action: {
                            Task {
                                await signInWithGoogle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe") // Placeholder for Google Logo
                                Text("Войти через Google")
                            }
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(DesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Удаление аккаунта", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                performDeleteAccount()
            }
        } message: {
            Text("Вы точно хотите удалить аккаунт из приложения и всю историю тренировок?")
        }
    }
    
    private func performDeleteAccount() {
        isLoading = true
        Task {
            do {
                try await authManager.deleteAccount(modelContext: modelContext)
            } catch {
                #if DEBUG
                print("Delete Account Error: \(error.localizedDescription)")
                #endif
            }
            isLoading = false
        }
    }
    
    private func performAction() {
        isLoading = true
        Task {
            do {
                if isRegistration {
                    try await authManager.signUpWithEmail(email: email, password: password)
                } else {
                    try await authManager.signInWithEmail(email: email, password: password)
                }
            } catch {
                #if DEBUG
                print("Auth Error: \(error.localizedDescription)")
                #endif
            }
            isLoading = false
        }
    }
    
    private func signInWithGoogle() async {
        isLoading = true
        // errorMessage = nil // If you had an error message state
        
        do {
            try await authManager.signInWithGoogle()
        } catch {
            #if DEBUG
            print("Google Auth Error: \(error.localizedDescription)")
            #endif
        }
        isLoading = false
    }
}
