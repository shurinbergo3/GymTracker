//
//  LoginView.swift
//  GymTracker
//
//  Created by Antigravity on 14.01.2026.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xxl) {
                Spacer()
                
                // Logo / Title
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 20)
                    
                    Text("GYM TRACKER")
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .tracking(2)
                }
                
                // Fields
                VStack(spacing: DesignSystem.Spacing.lg) {
                    CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    CustomTextField(icon: "lock.fill", placeholder: "Пароль", text: $password, isSecure: true)
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(DesignSystem.Typography.caption())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Main Button
                GradientButton(title: isSignUp ? "Создать аккаунт" : "Войти", icon: isSignUp ? "person.badge.plus" : "arrow.right") {
                    handleAuth()
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                // Toggle Mode
                Button(action: {
                    withAnimation {
                        isSignUp.toggle()
                        errorMessage = nil
                    }
                }) {
                    Text(isSignUp ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Создать")
                        .font(DesignSystem.Typography.body())
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
            
            if isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .tint(DesignSystem.Colors.neonGreen)
            }
        }
    }
    
    private func handleAuth() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUpWithEmail(email: email, password: password)
                } else {
                    try await authManager.signInWithEmail(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authManager.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// Helper View for TextFields
struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
        )
        .font(DesignSystem.Typography.body())
        .foregroundColor(DesignSystem.Colors.primaryText)
    }
}

#Preview {
    LoginView()
}
