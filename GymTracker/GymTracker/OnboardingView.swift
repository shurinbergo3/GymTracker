//
//  OnboardingView.swift
//  GymTracker
//
//  First-launch onboarding: welcome, features, Apple Health sync, CTA.
//  Cinematic, photo-led welcome flow — each slide rides a darkened gym shot
//  with a slow Ken Burns drift, editorial bottom-anchored type and brand neon.
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            kind: .hero,
            iconSystem: nil,
            photos: ["sportbg_03", "sportbg_20", "sportbg_04"],
            title: "ТВОЯ ЛИЧНАЯ КУЗНИЦА ТЕЛА",
            subtitle: "BODY FORGE превращает каждую тренировку в данные. Программы, прогресс, ИИ-тренер — в одном месте.",
            tint: DesignSystem.Colors.neonGreen
        ),
        OnboardingPage(
            kind: .feature,
            iconSystem: "chart.line.uptrend.xyaxis",
            photos: ["sportbg_14", "sportbg_16", "sportbg_11"],
            title: "ТРЕНИРОВКИ В ЦИФРАХ",
            subtitle: "Готовые программы или свои. Фиксируем каждый подход и вес, а графики показывают рост силы, объёма и рекордов — неделя за неделей.",
            tint: DesignSystem.Colors.neonGreen
        ),
        OnboardingPage(
            kind: .coachStyle,
            iconSystem: "brain.head.profile",
            photos: ["sportbg_19", "sportbg_01"],
            title: "ВЫБЕРИ СТИЛЬ КОУЧА",
            subtitle: "ИИ-тренер анализирует прогресс, отвечает на вопросы и корректирует план. Выбери тон — поменять можно в настройках.",
            tint: Color(red: 0.6, green: 0.4, blue: 1.0)
        ),
        OnboardingPage(
            kind: .health,
            iconSystem: "heart.fill",
            photos: ["sportbg_09", "sportbg_05"],
            title: "СИНХРОНИЗАЦИЯ С APPLE HEALTH",
            subtitle: "Тренировки автоматически попадают в Apple Health. Кольца активности, пульс, калории — всё считается и хранится у тебя.",
            tint: Color(red: 1.0, green: 0.27, blue: 0.4)
        ),
        OnboardingPage(
            kind: .watchQuestion,
            iconSystem: "applewatch",
            photos: ["sportbg_15"],
            title: "ЕСТЬ APPLE WATCH?",
            subtitle: "Если есть — покажем кольца активности и пульс. Если нет — скроем эти блоки, чтобы интерфейс был чище.",
            tint: DesignSystem.Colors.neonGreen
        ),
        OnboardingPage(
            kind: .cta,
            iconSystem: nil,
            photos: ["sportbg_20", "sportbg_03", "sportbg_19"],
            title: "ПОЕХАЛИ!",
            subtitle: "Создай аккаунт за 30 секунд — и начнём ковать форму уже сегодня.",
            tint: DesignSystem.Colors.neonGreen
        )
    ]

    private var current: OnboardingPage { pages[currentPage] }
    private var isInteractive: Bool {
        current.kind == .coachStyle || current.kind == .watchQuestion
    }

    var body: some View {
        ZStack {
            OnboardingPhotoBackdrop(
                photos: current.photos,
                tint: current.tint,
                heavy: isInteractive
            )

            VStack(spacing: 0) {
                // Top bar — Skip + step indicator
                HStack {
                    StepIndicator(current: currentPage, total: pages.count)
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: skip) {
                            Text("Пропустить".localized())
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(Color.black.opacity(0.28))
                                )
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
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
                            index: index,
                            total: pages.count,
                            isActive: index == currentPage,
                            selectedCoachStyleRaw: $pickedCoachStyleRaw
                        )
                            .tag(index)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom CTA
                VStack(spacing: 14) {
                    if current.kind == .watchQuestion {
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
                            title: currentPage == pages.count - 1 ? "Начать".localized() : "Дальше".localized(),
                            icon: currentPage == pages.count - 1 ? "checkmark" : "arrow.right"
                        ) {
                            advance()
                        }
                        .padding(.horizontal, 28)
                    }

                    if currentPage > 0 {
                        Button(action: back) {
                            Text("Назад".localized())
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.55))
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                    } else {
                        Spacer().frame(height: 44)
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
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                currentPage += 1
            }
        } else {
            finish()
        }
    }

    private func back() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentPage = max(0, currentPage - 1)
        }
    }

    private func skip() {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentPage = pages.count - 1
        }
    }

    private func finish() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
    /// One or more cinematic gym shots. Slides with >1 photo slowly crossfade
    /// between them; single-photo slides (the interactive steps) stay calm.
    let photos: [String]
    let title: String
    let subtitle: String
    let tint: Color
}

// MARK: - Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let index: Int
    let total: Int
    let isActive: Bool
    @Binding var selectedCoachStyleRaw: String

    var body: some View {
        switch page.kind {
        case .coachStyle:    coachStyleLayout
        case .watchQuestion: watchQuestionLayout
        default:             narrativeLayout
        }
    }

    // Editorial, photo-led layout: brand mark for the bookend slides, then a
    // bottom-anchored headline that reads over the cinematic background.
    private var narrativeLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            if page.kind == .hero || page.kind == .cta {
                HStack {
                    Spacer()
                    BrandLogoView(
                        size: page.kind == .hero ? 96 : 80,
                        showWordmark: false,
                        animated: true
                    )
                    Spacer()
                }
                .reveal(active: isActive, order: 0, scales: true)

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 16) {
                kicker
                    .reveal(active: isActive, order: 1)

                Text(page.title.localized())
                    .font(.system(size: 31, weight: .heavy, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 4)
                    .reveal(active: isActive, order: 2)

                Text(page.subtitle.localized())
                    .font(.system(.callout, design: .rounded))
                    .foregroundColor(.white.opacity(0.82))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 2)
                    .reveal(active: isActive, order: 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
        }
    }

    // Coach style: dense (4 options), so it scrolls under a left-aligned header.
    private var coachStyleLayout: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                titleBlock
                    .reveal(active: isActive, order: 0)

                CoachStylePicker(selectedRaw: $selectedCoachStyleRaw)
                    .reveal(active: isActive, order: 1)
            }
            .padding(.top, 18)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Watch question: header + the activity-ring visual + what a watch unlocks.
    private var watchQuestionLayout: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                titleBlock
                    .reveal(active: isActive, order: 0)

                HStack {
                    Spacer()
                    WatchQuestionVisual()
                        .scaleEffect(0.66)
                        .frame(height: 188)
                    Spacer()
                }
                .reveal(active: isActive, order: 1, scales: true)

                watchBenefitsCard
                    .reveal(active: isActive, order: 2)
            }
            .padding(.top, 14)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Editorial kicker: "01 — 06" step counter with a tinted rule.
    private var kicker: some View {
        HStack(spacing: 10) {
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(page.tint)
            Rectangle()
                .fill(page.tint.opacity(0.6))
                .frame(width: 26, height: 1.5)
            Text(String(format: "%02d", total))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            kicker

            Text(page.title.localized())
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 3)

            Text(page.subtitle.localized())
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var watchBenefitsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("С Apple Watch вы получите:".localized())
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.55))

            WatchBenefitsList(spacing: 11)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
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
                    Circle().fill(Color.white.opacity(isSelected ? 0.12 : 0.06))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(style.title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                Text(style.subtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected
                      ? DesignSystem.Colors.neonGreen.opacity(0.14)
                      : Color.black.opacity(0.32))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected
                        ? DesignSystem.Colors.neonGreen.opacity(0.55)
                        : Color.white.opacity(0.1),
                        lineWidth: 1)
        )
    }
}

// MARK: - Apple Watch question visual

private struct WatchQuestionVisual: View {
    @State private var ringPhase: Double = 0
    @State private var pulse: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            guard !reduceMotion else { return }
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
                sublabel: "Скроем кольца",
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
                    .foregroundColor(.white.opacity(0.5))
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

// MARK: - Cinematic photo backdrop

/// Full-bleed gym shot behind the whole flow. Each slide owns a photo; the
/// backdrop crossfades between them and runs a slow Ken Burns drift so the
/// background feels alive without distracting. A layered scrim (flat floor +
/// vertical shaping + brand neon) keeps text and glass cards legible over any
/// frame, and the interactive steps get an extra dim so their controls read.
private struct OnboardingPhotoBackdrop: View {
    let photos: [String]
    let tint: Color
    let heavy: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    private let cycle = Timer.publish(every: 5.5, on: .main, in: .common).autoconnect()

    private var current: String {
        photos.isEmpty ? "" : photos[index % photos.count]
    }

    var body: some View {
        ZStack {
            Color.black

            // Crossfading photo — keyed by name so a swap fades in/out. Slides
            // with several photos drift through them on the timer below.
            ZStack {
                ForEach([current], id: \.self) { name in
                    KenBurnsImage(name: name)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 1.1), value: current)

            // Flat legibility floor.
            Color.black.opacity(0.3)

            // Vertical shaping — lets the photo breathe up top, anchors copy below.
            LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.46),
                    Color.black.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Brand neon ambient, tinted per slide.
            RadialGradient(
                colors: [tint.opacity(0.22), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 520
            )
            .animation(.easeInOut(duration: 0.6), value: tint)

            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.10), .clear],
                center: .bottomLeading, startRadius: 0, endRadius: 480
            )

            // Extra dim under the interactive steps (picker / watch question).
            Color.black
                .opacity(heavy ? 0.4 : 0.0)
                .animation(.easeInOut(duration: 0.4), value: heavy)
        }
        .ignoresSafeArea()
        .onChange(of: photos) { _, _ in index = 0 }
        .onReceive(cycle) { _ in
            guard !reduceMotion, photos.count > 1 else { return }
            index += 1
        }
    }
}

/// A single photo that slowly zooms in once it appears — cinematic "Ken Burns"
/// motion. Honors Reduce Motion by holding a fixed frame.
private struct KenBurnsImage: View {
    let name: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var zoomed = false

    var body: some View {
        GeometryReader { geo in
            Image(name)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(reduceMotion ? 1.04 : (zoomed ? 1.16 : 1.03), anchor: .center)
                .clipped()
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 18)) { zoomed = true }
                }
        }
    }
}

// MARK: - Staggered reveal

/// Drives a per-element entrance: when the owning page becomes active, the element
/// blurs/slides (and optionally scales) into place, staggered by `order`. When the page
/// leaves, it resets after the slide-out completes so a return swipe re-plays the reveal.
/// Honors Reduce Motion by snapping straight to the final state.
private struct Reveal: ViewModifier {
    let active: Bool
    let order: Int
    var scales: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var resetWork: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 24)
            .scaleEffect(scales ? (shown ? 1 : 0.84) : 1, anchor: .center)
            .blur(radius: shown ? 0 : (scales ? 10 : 4))
            .onAppear { apply(active) }
            .onChange(of: active) { _, newValue in apply(newValue) }
    }

    private func apply(_ active: Bool) {
        resetWork?.cancel()

        guard !reduceMotion else { shown = active; return }

        if active {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)
                .delay(0.07 * Double(order))) {
                shown = true
            }
        } else {
            // Keep content visible while this page slides off-screen, then reset
            // so the entrance can replay if the user swipes back.
            let work = DispatchWorkItem { shown = false }
            resetWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
        }
    }
}

private extension View {
    func reveal(active: Bool, order: Int, scales: Bool = false) -> some View {
        modifier(Reveal(active: active, order: order, scales: scales))
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
                    .fill(idx == current ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.25))
                    .frame(width: idx == current ? 22 : 6, height: 6)
                    .shadow(color: idx == current ? DesignSystem.Colors.neonGreen.opacity(0.6) : .clear,
                            radius: 5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
            }
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
