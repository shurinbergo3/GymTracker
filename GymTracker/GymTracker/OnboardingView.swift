//
//  OnboardingView.swift
//  GymTracker
//
//  First-launch onboarding: welcome, features, Apple Health sync, CTA.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @AppStorage("isAppleWatchEnabled") private var isAppleWatchEnabled: Bool = true
    @AppStorage("hasAnsweredWatchQuestion") private var hasAnsweredWatchQuestion: Bool = false
    /// Stashed at onboarding time and read back the first time `AICoachStore`
    /// creates the singleton profile — keeps onboarding free of SwiftData writes
    /// that could conflict with the Login → Restore flow.
    @AppStorage("onboarding.coachStyle") private var pickedCoachStyleRaw: String = AICoachStyle.friendly.rawValue

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
            kind: .coachStyle,
            iconSystem: "person.wave.2.fill",
            title: "ВЫБЕРИ СТИЛЬ КОУЧА",
            subtitle: "Любой стиль можно поменять в настройках. Тон ответов и пушей подстроится под тебя.",
            tint: DesignSystem.Colors.neonGreen
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
            kind: .watchQuestion,
            iconSystem: "applewatch",
            title: "ЕСТЬ APPLE WATCH?",
            subtitle: "Если есть — покажем кольца активности и пульс. Если нет — скроем эти блоки, чтобы интерфейс был чище.",
            tint: DesignSystem.Colors.neonGreen
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
                        OnboardingPageView(
                            page: pages[index],
                            selectedCoachStyleRaw: $pickedCoachStyleRaw
                        )
                            .tag(index)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Bottom CTA
                VStack(spacing: 14) {
                    if pages[currentPage].kind == .watchQuestion {
                        WatchChoiceRow(
                            onYes: {
                                isAppleWatchEnabled = true
                                hasAnsweredWatchQuestion = true
                                advance()
                            },
                            onNo: {
                                isAppleWatchEnabled = false
                                hasAnsweredWatchQuestion = true
                                advance()
                            }
                        )
                        .padding(.horizontal, 24)
                    } else {
                        GradientButton(
                            title: currentPage == pages.count - 1 ? "Начать" : "Дальше",
                            icon: currentPage == pages.count - 1 ? "checkmark" : "arrow.right"
                        ) {
                            advance()
                        }
                        .padding(.horizontal, 28)
                    }

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
    enum Kind { case hero, feature, health, watchQuestion, coachStyle, cta }
    let kind: Kind
    let iconSystem: String?
    let title: String
    let subtitle: String
    let tint: Color
}

// MARK: - Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var selectedCoachStyleRaw: String

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

            if page.kind == .coachStyle {
                CoachStylePicker(selectedRaw: $selectedCoachStyleRaw)
                    .padding(.top, 4)
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

        case .watchQuestion:
            WatchQuestionVisual()

        case .coachStyle:
            FeatureIcon(system: page.iconSystem ?? "person.wave.2.fill", tint: page.tint)

        case .cta:
            BrandLogoView(size: 110, showWordmark: false, animated: true)
        }
    }
}

// MARK: - Coach style picker

private struct CoachStylePicker: View {
    @Binding var selectedRaw: String

    private var selected: AICoachStyle {
        AICoachStyle(rawValue: selectedRaw) ?? .friendly
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(AICoachStyle.allCases) { style in
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedRaw = style.rawValue
                    }
                } label: {
                    StyleRow(style: style, isSelected: style == selected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct StyleRow: View {
    let style: AICoachStyle
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(style.emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(Color.white.opacity(isSelected ? 0.10 : 0.04))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(style.titleKey)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                Text(style.subtitleKey)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected
                      ? DesignSystem.Colors.neonGreen.opacity(0.10)
                      : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected
                        ? DesignSystem.Colors.neonGreen.opacity(0.55)
                        : Color.white.opacity(0.08),
                        lineWidth: 1)
        )
    }
}

// MARK: - Apple Watch question visual

private struct WatchQuestionVisual: View {
    @State private var ringPhase: Double = 0
    @State private var pulse: Bool = false

    private let moveColor   = Color(red: 1.00, green: 0.18, blue: 0.34)
    private let exerciseColor = Color(red: 0.30, green: 0.95, blue: 0.45)
    private let standColor  = Color(red: 0.10, green: 0.78, blue: 1.00)

    var body: some View {
        ZStack {
            // Аура
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.Colors.neonGreen.opacity(0.32),
                            DesignSystem.Colors.accentPurple.opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 340, height: 340)
                .blur(radius: 30)
                .scaleEffect(pulse ? 1.06 : 0.94)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: pulse)

            // Декоративная пунктирная орбита
            Circle()
                .trim(from: 0, to: 0.82)
                .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(ringPhase))

            // Три «кольца активности» вокруг часов
            ringTriad

            // Корпус Apple Watch
            watchBody
        }
        .frame(height: 300)
        .onAppear {
            pulse = true
            withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) {
                ringPhase = 360
            }
        }
    }

    // MARK: Rings

    private var ringTriad: some View {
        ZStack {
            activityRing(color: moveColor,    diameter: 210, lineWidth: 14, trim: 0.92, delay: 0.0)
            activityRing(color: exerciseColor, diameter: 178, lineWidth: 14, trim: 0.78, delay: 0.15)
            activityRing(color: standColor,   diameter: 146, lineWidth: 14, trim: 0.66, delay: 0.30)
        }
    }

    private func activityRing(color: Color, diameter: CGFloat, lineWidth: CGFloat, trim: CGFloat, delay: Double) -> some View {
        ZStack {
            // фоновая дорожка
            Circle()
                .stroke(color.opacity(0.16), lineWidth: lineWidth)

            // прогресс-дуга
            Circle()
                .trim(from: 0, to: trim)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.55), color, color.opacity(0.85)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.55), radius: 10)
                .opacity(pulse ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(delay), value: pulse)
        }
        .frame(width: diameter, height: diameter)
    }

    // MARK: Watch body

    private var watchBody: some View {
        ZStack {
            // тёмная подложка-корпус
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.13), Color(white: 0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 92, height: 116)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 18, x: 0, y: 10)

            // экран
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black)
                .frame(width: 76, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(DesignSystem.Colors.neonGreen.opacity(0.25), lineWidth: 0.6)
                )

            // мини-кольца на циферблате
            ZStack {
                miniRing(color: moveColor,     diameter: 56, line: 5, trim: 0.92)
                miniRing(color: exerciseColor, diameter: 42, line: 5, trim: 0.78)
                miniRing(color: standColor,    diameter: 28, line: 5, trim: 0.66)
            }

            // боковые «выступы» корпуса часов (заводная коронка + кнопка)
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) {
                    Capsule()
                        .fill(Color(white: 0.32))
                        .frame(width: 4, height: 18)
                    Capsule()
                        .fill(Color(white: 0.22))
                        .frame(width: 3, height: 28)
                }
                .offset(x: 4)
            }
            .frame(width: 92, height: 116)
        }
    }

    private func miniRing(color: Color, diameter: CGFloat, line: CGFloat, trim: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: line)
            Circle()
                .trim(from: 0, to: trim)
                .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.7), radius: 4)
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: - Watch choice buttons (Yes / No)

private struct WatchChoiceRow: View {
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            WatchChoiceButton(
                label: "Да, есть",
                sublabel: "Покажем кольца",
                icon: "applewatch",
                accent: DesignSystem.Colors.neonGreen,
                isPrimary: true,
                action: onYes
            )

            WatchChoiceButton(
                label: "Нет",
                sublabel: "Скроем рингы",
                icon: "applewatch.slash",
                accent: DesignSystem.Colors.accentPurple,
                isPrimary: false,
                action: onNo
            )
        }
    }
}

private struct WatchChoiceButton: View {
    let label: String
    let sublabel: String
    let icon: String
    let accent: Color
    let isPrimary: Bool
    let action: () -> Void

    @State private var pressed: Bool = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.18)) { pressed = false }
                action()
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accent.opacity(0.55), .clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 30
                            )
                        )
                        .frame(width: 56, height: 56)
                        .blur(radius: 6)
                        .opacity(isPrimary ? 0.95 : 0.55)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isPrimary
                                    ? [accent, accent.opacity(0.7)]
                                    : [Color(white: 0.16), Color(white: 0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().stroke(accent.opacity(isPrimary ? 0 : 0.55), lineWidth: 1)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(isPrimary ? Color.black : accent)
                }

                Text(label.localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundColor(.white)

                Text(sublabel.localized().uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(choiceBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isPrimary
                                ? [accent.opacity(0.7), accent.opacity(0.2), .clear]
                                : [accent.opacity(0.45), Color.white.opacity(0.05), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: accent.opacity(isPrimary ? 0.35 : 0.18), radius: 18, x: 0, y: 8)
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var choiceBackground: some View {
        ZStack {
            LinearGradient(
                colors: isPrimary
                    ? [
                        accent.opacity(0.22),
                        Color(red: 0.05, green: 0.10, blue: 0.06)
                      ]
                    : [
                        Color(red: 0.10, green: 0.08, blue: 0.16),
                        Color(red: 0.05, green: 0.05, blue: 0.08)
                      ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [accent.opacity(isPrimary ? 0.20 : 0.14), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 160
            )
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
