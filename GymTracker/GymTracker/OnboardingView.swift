//
//  OnboardingView.swift
//  GymTracker
//
//  First-launch onboarding: welcome, features, Apple Health sync, CTA.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    @State private var currentPage: Int = 0
    @State private var appear: Bool = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            kind: .hero,
            iconSystem: nil,
            title: "ТВОЯ ЛИЧНАЯ КУЗНИЦА ТЕЛА",
            subtitle: "BODY FORGE превращает каждую тренировку в данные. Программы, прогресс, ИИ-тренер — в одном месте.",
            tint: DesignSystem.Colors.neonGreen
        ),
        OnboardingPage(
            kind: .feature,
            iconSystem: "list.bullet.rectangle.portrait.fill",
            title: "ПРОГРАММЫ И ТРЕНИРОВКИ",
            subtitle: "Готовые программы или собственные. Мы фиксируем подходы, веса, повторения и считаем объём — ты только тренируешься.",
            tint: DesignSystem.Colors.neonGreen
        ),
        OnboardingPage(
            kind: .feature,
            iconSystem: "brain.head.profile",
            title: "ИИ-ТРЕНЕР",
            subtitle: "Анализирует прогресс, отвечает на вопросы, корректирует план. Личный тренер, который всегда на связи.",
            tint: Color(red: 0.6, green: 0.4, blue: 1.0)
        ),
        OnboardingPage(
            kind: .feature,
            iconSystem: "chart.line.uptrend.xyaxis",
            title: "ПРОГРЕСС, А НЕ ИНТУИЦИЯ",
            subtitle: "Графики силы, объёма, измерения тела, личные рекорды. Видишь, как растёшь — неделя за неделей.",
            tint: DesignSystem.Colors.secondaryAccent
        ),
        OnboardingPage(
            kind: .health,
            iconSystem: "heart.fill",
            title: "СИНХРОНИЗАЦИЯ С APPLE ЗДОРОВЬЕ",
            subtitle: "Тренировки автоматически попадают в Apple Health. Кольца активности, пульс, калории — всё считается и хранится у тебя.",
            tint: Color(red: 1.0, green: 0.27, blue: 0.4)
        ),
        OnboardingPage(
            kind: .cta,
            iconSystem: nil,
            title: "ГОТОВ?",
            subtitle: "Создай аккаунт за 30 секунд — и начнём ковать форму уже сегодня.",
            tint: DesignSystem.Colors.neonGreen
        )
    ]

    var body: some View {
        ZStack {
            AtmosphericBackground()

            VStack(spacing: 0) {
                // Top bar — Skip + step indicator
                HStack {
                    StepIndicator(current: currentPage, total: pages.count)
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: skip) {
                            Text("Пропустить")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(Color.white.opacity(0.06))
                                )
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Bottom CTA
                VStack(spacing: 14) {
                    GradientButton(
                        title: currentPage == pages.count - 1 ? "Начать" : "Дальше",
                        icon: currentPage == pages.count - 1 ? "checkmark" : "arrow.right"
                    ) {
                        advance()
                    }
                    .padding(.horizontal, 28)

                    if currentPage > 0 {
                        Button(action: back) {
                            Text("Назад")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    } else {
                        Spacer().frame(height: 22)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appear = true
            }
        }
    }

    private func advance() {
        if currentPage < pages.count - 1 {
            withAnimation(.easeInOut) {
                currentPage += 1
            }
        } else {
            finish()
        }
    }

    private func back() {
        withAnimation(.easeInOut) {
            currentPage = max(0, currentPage - 1)
        }
    }

    private func skip() {
        withAnimation(.easeInOut) {
            currentPage = pages.count - 1
        }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.4)) {
            hasSeenOnboarding = true
        }
    }
}

// MARK: - Page Model

private struct OnboardingPage: Identifiable {
    let id = UUID()
    enum Kind { case hero, feature, health, cta }
    let kind: Kind
    let iconSystem: String?
    let title: String
    let subtitle: String
    let tint: Color
}

// MARK: - Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            visual

            VStack(spacing: 18) {
                Text(page.title.localized())
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(page.subtitle.localized())
                    .font(.system(.callout, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var visual: some View {
        switch page.kind {
        case .hero:
            BrandLogoView(size: 140, showWordmark: true, animated: true)

        case .feature:
            FeatureIcon(system: page.iconSystem ?? "star.fill", tint: page.tint)

        case .health:
            HealthSyncVisual(tint: page.tint)

        case .cta:
            BrandLogoView(size: 110, showWordmark: false, animated: true)
        }
    }
}

// MARK: - Feature icon (stylized)

private struct FeatureIcon: View {
    let system: String
    let tint: Color

    @State private var rotate: Bool = false

    var body: some View {
        ZStack {
            // Аура
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 28)

            // Внешнее декоративное кольцо
            Circle()
                .trim(from: 0, to: 0.78)
                .stroke(tint.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 6]))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(rotate ? 360 : 0))
                .animation(.linear(duration: 28).repeatForever(autoreverses: false), value: rotate)

            // Капсула-плашка
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.10), Color(white: 0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 160)
                .overlay(
                    Circle().stroke(tint.opacity(0.5), lineWidth: 1.2)
                )
                .shadow(color: tint.opacity(0.4), radius: 24)

            Image(systemName: system)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: tint.opacity(0.6), radius: 12)
        }
        .frame(height: 280)
        .onAppear { rotate = true }
    }
}

// MARK: - Apple Health visual

private struct HealthSyncVisual: View {
    let tint: Color
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            // Аура
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 28)

            // Левый бейдж — наш логотип
            ZStack {
                Circle()
                    .fill(Color(white: 0.08))
                    .frame(width: 110, height: 110)
                    .overlay(Circle().stroke(DesignSystem.Colors.neonGreen.opacity(0.5), lineWidth: 1.2))
                Image("BrandLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 78, height: 78)
                    .clipShape(Circle())
            }
            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 16)
            .offset(x: -68)

            // Правый бейдж — Apple Health
            ZStack {
                Circle()
                    .fill(Color(white: 0.08))
                    .frame(width: 110, height: 110)
                    .overlay(Circle().stroke(tint.opacity(0.6), lineWidth: 1.2))
                Image(systemName: "heart.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.27, blue: 0.4),
                                Color(red: 1.0, green: 0.45, blue: 0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: tint.opacity(0.5), radius: 16)
            .offset(x: 68)

            // Связь — пульсирующие точки
            HStack(spacing: 6) {
                ForEach(0..<5) { i in
                    Circle()
                        .fill(DesignSystem.Colors.neonGreen)
                        .frame(width: 6, height: 6)
                        .opacity(pulse ? 1.0 : 0.25)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                            value: pulse
                        )
                }
            }
            .frame(width: 60)
        }
        .frame(height: 280)
        .onAppear { pulse = true }
    }
}

// MARK: - Step Indicator

private struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { idx in
                Capsule()
                    .fill(idx == current ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.15))
                    .frame(width: idx == current ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
            }
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
