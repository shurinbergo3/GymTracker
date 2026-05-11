//
//  LoginView.swift
//  GymTracker
//
//  Created by Antigravity on 14.01.2026.
//  Redesigned with custom brand mark and atmospheric login UI.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var appear: Bool = false

    @FocusState private var focusedField: Field?
    enum Field { case email, password }

    var body: some View {
        ZStack {
            AtmosphericBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)

                    // Brand mark
                    BrandLogoView(size: 116, showWordmark: true, animated: true)
                        .scaleEffect(appear ? 1 : 0.9)
                        .opacity(appear ? 1 : 0)

                    Spacer().frame(height: 44)

                    // Mode title
                    VStack(spacing: 6) {
                        Text(isSignUp ? "Создай аккаунт".localized() : "С возвращением".localized())
                            .font(.system(.title2, design: .rounded, weight: .heavy))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .tracking(0.5)

                        Text(isSignUp
                             ? "Начни ковать форму уже сегодня".localized()
                             : "Войди, чтобы продолжить тренировки".localized())
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 8)

                    Spacer().frame(height: 32)

                    // Form fields
                    VStack(spacing: 14) {
                        ForgeTextField(
                            icon: "envelope.fill",
                            placeholder: "Эл. почта".localized(),
                            text: $email,
                            isFocused: focusedField == .email
                        )
                        .focused($focusedField, equals: .email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)

                        ForgeTextField(
                            icon: "lock.fill",
                            placeholder: "Пароль".localized(),
                            text: $password,
                            isSecure: true,
                            isFocused: focusedField == .password
                        )
                        .focused($focusedField, equals: .password)
                        .textContentType(isSignUp ? .newPassword : .password)
                    }
                    .padding(.horizontal, 28)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 12)

                    if !isSignUp {
                        HStack {
                            Spacer()
                            Button(action: { Task { await sendPasswordReset() } }) {
                                Text("Забыли пароль?".localized())
                                    .font(.system(.footnote, design: .rounded, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                    .underline()
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 10)
                        .opacity(appear ? 1 : 0)
                    }

                    if let infoMessage = infoMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text(infoMessage)
                                .font(.system(.caption, design: .rounded))
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DesignSystem.Colors.neonGreen.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.Colors.neonGreen.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 28)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(errorMessage)
                                .font(.system(.caption, design: .rounded))
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.45))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 1.0, green: 0.2, blue: 0.2).opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 28)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer().frame(height: 22)

                    // Primary button
                    GradientButton(
                        title: isSignUp ? "Создать аккаунт".localized() : "Войти".localized(),
                        icon: isSignUp ? "person.badge.plus" : "arrow.right"
                    ) {
                        handleAuth()
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.55 : 1)
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 16)

                    // Toggle sign-in/sign-up
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isSignUp.toggle()
                            errorMessage = nil
                            infoMessage = nil
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(isSignUp ? "Уже есть аккаунт?".localized() : "Нет аккаунта?".localized())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Text(isSignUp ? "Войти".localized() : "Создать".localized())
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                                .underline()
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                    }

                    Spacer().frame(height: 26)

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.10))
                        Text("ИЛИ".localized())
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .tracking(2)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.10))
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 18)

                    // Social buttons
                    VStack(spacing: 12) {
                        SocialButton(
                            iconSystem: "applelogo",
                            title: "Войти через Apple".localized(),
                            foreground: .white,
                            background: Color.white.opacity(0.06),
                            border: .white.opacity(0.18)
                        ) {
                            Task { await signInWithApple() }
                        }

                        SocialButton(
                            iconSystem: nil,
                            iconView: AnyView(GoogleGlyph()),
                            title: "Войти через Google".localized(),
                            foreground: .white,
                            background: Color.white.opacity(0.06),
                            border: .white.opacity(0.18)
                        ) {
                            Task { await signInWithGoogle() }
                        }
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 24)

                    // Footer
                    Text("Продолжая, ты соглашаешься с правилами и политикой конфиденциальности".localized())
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)

                    Spacer().frame(height: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            if isLoading {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(DesignSystem.Colors.neonGreen)
                        .scaleEffect(1.4)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appear = true
            }
        }
    }

    // MARK: - Actions

    private func handleAuth() {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanedEmail.isEmpty, !password.isEmpty else { return }
        email = cleanedEmail
        focusedField = nil
        isLoading = true
        errorMessage = nil
        infoMessage = nil

        Task {
            do {
                if isSignUp {
                    try await authManager.signUpWithEmail(email: cleanedEmail, password: password)
                } else {
                    try await authManager.signInWithEmail(email: cleanedEmail, password: password)
                }
            } catch {
                withAnimation { errorMessage = friendlyAuthError(error) }
            }
            isLoading = false
        }
    }

    private func sendPasswordReset() async {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanedEmail.isEmpty else {
            withAnimation {
                errorMessage = "Введи e-mail, чтобы получить ссылку для сброса пароля".localized()
            }
            return
        }
        email = cleanedEmail
        focusedField = nil
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        do {
            try await authManager.sendPasswordReset(email: cleanedEmail)
            withAnimation {
                infoMessage = "Ссылка для сброса пароля отправлена на \(cleanedEmail). Проверь почту (и папку «Спам»).".localized()
            }
        } catch {
            withAnimation { errorMessage = friendlyAuthError(error) }
        }
        isLoading = false
    }

    private func signInWithGoogle() async {
        focusedField = nil
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        do {
            try await authManager.signInWithGoogle()
        } catch {
            withAnimation { errorMessage = friendlyAuthError(error) }
        }
        isLoading = false
    }

    private func signInWithApple() async {
        focusedField = nil
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        do {
            try await authManager.signInWithApple()
        } catch {
            withAnimation { errorMessage = friendlyAuthError(error) }
        }
        isLoading = false
    }

    /// Map Firebase Auth error codes to short, actionable Russian messages.
    private func friendlyAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        let code = AuthErrorCode(rawValue: nsError.code)
        switch code {
        case .wrongPassword, .invalidCredential:
            return "Неверный e-mail или пароль. Если уверен в пароле — попробуй «Забыли пароль?» или вход через Apple/Google.".localized()
        case .userNotFound:
            return "Пользователь с таким e-mail не найден. Нажми «Создать», чтобы зарегистрироваться.".localized()
        case .invalidEmail:
            return "E-mail указан в неверном формате.".localized()
        case .emailAlreadyInUse:
            return "Этот e-mail уже зарегистрирован. Войди или сбрось пароль.".localized()
        case .weakPassword:
            return "Пароль слишком простой — минимум 6 символов.".localized()
        case .userDisabled:
            return "Аккаунт отключён. Свяжись с поддержкой.".localized()
        case .networkError:
            return "Проблемы с сетью. Проверь подключение и повтори.".localized()
        case .tooManyRequests:
            return "Слишком много попыток. Подожди немного и попробуй снова.".localized()
        case .accountExistsWithDifferentCredential:
            return "Этот e-mail привязан к другому способу входа (Apple/Google). Войди через него.".localized()
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Forge Text Field

struct ForgeTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var isFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isFocused ? DesignSystem.Colors.neonGreen : DesignSystem.Colors.tertiaryText)
                .frame(width: 18)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(.body, design: .rounded))
            .foregroundColor(DesignSystem.Colors.primaryText)
            .tint(DesignSystem.Colors.neonGreen)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isFocused ? DesignSystem.Colors.neonGreen.opacity(0.85) : Color.white.opacity(0.08),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .shadow(
            color: isFocused ? DesignSystem.Colors.neonGreen.opacity(0.25) : .clear,
            radius: 12,
            x: 0,
            y: 0
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Social Button

struct SocialButton: View {
    var iconSystem: String?
    var iconView: AnyView? = nil
    let title: String
    let foreground: Color
    let background: Color
    let border: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = iconSystem {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                } else if let iconView {
                    iconView
                }
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
            }
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(background)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Google glyph (multi-color G drawn with shapes)

private struct GoogleGlyph: View {
    private static let blue   = Color(red: 0.26, green: 0.52, blue: 0.96)
    private static let red    = Color(red: 0.92, green: 0.26, blue: 0.21)
    private static let yellow = Color(red: 0.98, green: 0.74, blue: 0.02)
    private static let green  = Color(red: 0.20, green: 0.66, blue: 0.33)

    var body: some View {
        let ringSize: CGFloat = 20
        let lineWidth: CGFloat = 3.4
        let style = StrokeStyle(lineWidth: lineWidth, lineCap: .butt)

        return ZStack {
            // Red: top-left arc (~9 → 12 o'clock)
            Circle()
                .trim(from: 0.75, to: 1.00)
                .stroke(Self.red, style: style)
            // Blue: top-right arc (~12 → ~3 o'clock), terminates where the bar begins
            Circle()
                .trim(from: 0.00, to: 0.21)
                .stroke(Self.blue, style: style)
            // Green: right-down arc (~3 → 6 o'clock), starts past the bar opening
            Circle()
                .trim(from: 0.30, to: 0.50)
                .stroke(Self.green, style: style)
            // Yellow: bottom-left arc (6 → 9 o'clock)
            Circle()
                .trim(from: 0.50, to: 0.75)
                .stroke(Self.yellow, style: style)

            // Horizontal blue bar extending inward from the right opening
            Rectangle()
                .fill(Self.blue)
                .frame(width: ringSize * 0.34, height: lineWidth)
                .offset(x: ringSize * 0.20, y: ringSize * 0.04)
        }
        .frame(width: ringSize, height: ringSize)
    }
}

#Preview {
    LoginView()
}
