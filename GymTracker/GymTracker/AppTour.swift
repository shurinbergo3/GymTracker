//
//  AppTour.swift
//  GymTracker
//
//  Interactive "where is what" coach-mark tour. A dimming overlay with a
//  spotlight cut-out points at real UI elements (the stress row, the Apple
//  Health card, the tab bar) while stepping through the tabs, with a callout
//  explaining each. Runs once after onboarding and is replayable from Settings.
//
//  Robustness: in-scroll targets are reached via auto-scroll so the spotlight
//  always has an on-screen element; if an anchor can't be resolved (e.g. the
//  user has no watch and the stress row is absent) the step gracefully degrades
//  to a centered callout instead of pointing at nothing.
//

import SwiftUI
import UIKit

// MARK: - Targets the tour can point at (real, anchored views)

enum TourAnchorID: Hashable {
    case stressRow
    case appleHealth
    case aiCoach
}

/// What a step highlights.
enum TourSpot: Equatable {
    case center                 // no spotlight — a centered card
    case anchor(TourAnchorID)   // a real view, located via anchorPreference
    case tabBar                 // the whole bottom tab bar
    case tabItem(Int)           // a single tab button (0...3)
    case topTrailing            // the profile avatar in the nav bar (top-right)
}

struct TourStep: Identifiable {
    let id = UUID()
    let tab: Int?           // switch to this tab before showing (nil = keep)
    let scrollToHealth: Bool // scroll the Apple Health card into view first
    let spot: TourSpot
    let title: String       // Russian source key (localised at render)
    let text: String
}

// MARK: - Step content

enum TourSteps {
    static func make(hasWatch: Bool) -> [TourStep] {
        var steps: [TourStep] = [
            TourStep(tab: nil, scrollToHealth: false, spot: .center,
                     title: "Добро пожаловать!",
                     text: "Коротко покажу, где что находится. Это займёт 20 секунд."),
            TourStep(tab: 0, scrollToHealth: false, spot: .tabBar,
                     title: "Разделы приложения",
                     text: "Внизу четыре вкладки: Тренировка, Программа, Справочник и Статистика. Листай их слева направо."),
            TourStep(tab: 0, scrollToHealth: false, spot: .tabItem(0),
                     title: "Тренировка",
                     text: "Активная тренировка: подходы, веса, таймер отдыха и пульс в реальном времени."),
            TourStep(tab: 0, scrollToHealth: false, spot: .anchor(.aiCoach),
                     title: "ИИ-тренер",
                     text: "Разбирает каждую тренировку, отвечает на вопросы и подсказывает, что менять. Нажми на карточку, чтобы открыть диалог."),
            TourStep(tab: 1, scrollToHealth: false, spot: .tabItem(1),
                     title: "Программа",
                     text: "Готовые планы или свой. Активная программа подсказывает, что тренировать сегодня."),
            TourStep(tab: 2, scrollToHealth: false, spot: .tabItem(2),
                     title: "Справочник",
                     text: "База упражнений с техникой и видео, плюс гайды по тренировкам, сну и питанию."),
            TourStep(tab: 3, scrollToHealth: false, spot: .tabItem(3),
                     title: "Статистика",
                     text: "Прогресс, замеры тела, графики и данные здоровья.")
        ]

        if hasWatch {
            steps.append(TourStep(tab: 3, scrollToHealth: true, spot: .anchor(.stressRow),
                                  title: "Уровень стресса",
                                  text: "Новое: ежедневная оценка стресса по ВРС, пульсу покоя и сну с Apple Watch. Нажми на строку - там подробности за месяц."))
        }

        steps.append(TourStep(tab: 3, scrollToHealth: true, spot: .anchor(.appleHealth),
                              title: "Apple Health",
                              text: "Все данные в одном месте: шаги, сон, пульс покоя, ВРС и калории."))
        steps.append(TourStep(tab: 0, scrollToHealth: false, spot: .topTrailing,
                              title: "Профиль и настройки",
                              text: "Аватар сверху справа - там язык, подключение Apple Watch, стиль ИИ-коуча и управление данными."))
        steps.append(TourStep(tab: nil, scrollToHealth: false, spot: .center,
                              title: "Готово!",
                              text: "Это всё. Обзор можно пройти заново в настройках. Поехали ковать форму!"))
        return steps
    }
}

// MARK: - Manager

@MainActor
final class TourManager: ObservableObject {
    static let shared = TourManager()
    private init() {}

    /// Bump this to re-show the tour to EVERYONE after a release. Users store
    /// the last version they completed; anyone whose stored value is lower sees
    /// the tour again. New installs default to 0, so a value ≥ 1 shows it.
    static let version = 3

    @Published private(set) var isActive = false
    @Published private(set) var index = 0
    private(set) var steps: [TourStep] = []

    /// Called when the tour ends (finished or skipped) so the host can persist
    /// "seen" and stop auto-starting it.
    var onFinish: (() -> Void)?

    var current: TourStep? { steps.indices.contains(index) ? steps[index] : nil }
    var isLast: Bool { index >= steps.count - 1 }

    func start(_ steps: [TourStep]) {
        guard !steps.isEmpty else { return }
        self.steps = steps
        index = 0
        withAnimation(.easeInOut(duration: 0.3)) { isActive = true }
    }

    func next() {
        if isLast { finish() }
        else { withAnimation(.easeInOut(duration: 0.3)) { index += 1 } }
    }

    func back() {
        guard index > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) { index -= 1 }
    }

    func finish() {
        withAnimation(.easeInOut(duration: 0.3)) { isActive = false }
        index = 0
        steps = []
        onFinish?()
    }
}

// MARK: - Anchor plumbing

struct TourAnchorsKey: PreferenceKey {
    static let defaultValue: [TourAnchorID: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TourAnchorID: Anchor<CGRect>],
                       nextValue: () -> [TourAnchorID: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Tags a view as a tour target so the overlay can spotlight it.
    func tourAnchor(_ id: TourAnchorID) -> some View {
        anchorPreference(key: TourAnchorsKey.self, value: .bounds) { [id: $0] }
    }
}

// MARK: - Spotlight shape (dim with an animatable rounded hole)

private struct SpotlightShape: Shape {
    var hole: CGRect
    var radius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(hole.origin.x, hole.origin.y),
                             AnimatablePair(hole.size.width, hole.size.height)) }
        set {
            hole.origin.x = newValue.first.first
            hole.origin.y = newValue.first.second
            hole.size.width = newValue.second.first
            hole.size.height = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect)
        if hole.width > 0 && hole.height > 0 {
            p.addRoundedRect(in: hole, cornerSize: CGSize(width: radius, height: radius))
        }
        return p
    }
}

// MARK: - Overlay

struct TourOverlay: View {
    @ObservedObject var tour: TourManager
    let anchors: [TourAnchorID: Anchor<CGRect>]
    let proxy: GeometryProxy

    private var step: TourStep? { tour.current }

    private static let tabCount = 4
    private static let tabBarContentHeight: CGFloat = 49

    /// Real device safe-area insets read from the key window. The overlay's
    /// GeometryReader ignores the safe area (so `proxy.size` is the true full
    /// screen), which means `proxy.safeAreaInsets` is no longer reliable — the
    /// home indicator / status bar insets have to come from the window instead.
    private var insets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.safeAreaInsets ?? .zero
    }

    /// Vertical bounds of the system tab bar (content area, above the home
    /// indicator) within the overlay's full-screen coordinate space.
    private var tabBarTop: CGFloat {
        proxy.size.height - insets.bottom - Self.tabBarContentHeight
    }

    /// Resolved spotlight frame in the overlay's coordinate space, or nil for a
    /// centered card.
    private var spotRect: CGRect? {
        guard let step else { return nil }
        switch step.spot {
        case .center:
            return nil
        case .anchor(let id):
            guard let a = anchors[id] else { return nil }   // graceful: centered
            // Clamp to the visible area so a tall card never produces a ring
            // that runs off-screen.
            let raw = proxy[a].insetBy(dx: -10, dy: -10)
            let topLimit = insets.top + 8
            let bottomLimit = tabBarTop - 8
            let top = max(raw.minY, topLimit)
            let bottom = min(raw.maxY, bottomLimit)
            return CGRect(x: raw.minX, y: top, width: raw.width, height: max(0, bottom - top))
        case .tabBar:
            // The whole bar down to the bottom edge (including the home indicator).
            let top = tabBarTop - 4
            return CGRect(x: 6, y: top,
                          width: proxy.size.width - 12,
                          height: proxy.size.height - top)
        case .tabItem(let i):
            let tabWidth = proxy.size.width / CGFloat(Self.tabCount)
            let centerX = tabWidth * (CGFloat(i) + 0.5)
            let centerY = tabBarTop + Self.tabBarContentHeight / 2
            let w = min(tabWidth - 8, 78)
            let h: CGFloat = 54
            return CGRect(x: centerX - w / 2, y: centerY - h / 2, width: w, height: h)
        case .topTrailing:
            // The profile avatar sits in the nav bar trailing slot, top-right.
            let size: CGFloat = 54
            let centerX = proxy.size.width - 38
            let centerY = insets.top + 22
            return CGRect(x: centerX - size / 2, y: centerY - size / 2, width: size, height: size)
        }
    }

    private var holeRadius: CGFloat {
        guard let spot = step?.spot else { return 16 }
        switch spot {
        case .topTrailing: return 27
        case .tabBar:      return 22
        case .anchor, .tabItem: return 18
        case .center:      return 16
        }
    }

    var body: some View {
        if tour.isActive, let step {
            ZStack {
                // Dim + spotlight, tap anywhere to advance.
                SpotlightShape(hole: spotRect ?? .zero, radius: holeRadius)
                    .fill(Color.black.opacity(0.84), style: FillStyle(eoFill: true))
                    .contentShape(Rectangle())
                    .onTapGesture { tour.next() }
                    .animation(.easeInOut(duration: 0.32), value: spotRect)

                // Glowing ring around the spotlight.
                if let rect = spotRect {
                    RoundedRectangle(cornerRadius: holeRadius, style: .continuous)
                        .stroke(DesignSystem.Colors.neonGreen.opacity(0.9), lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.6), radius: 10)
                        .position(x: rect.midX, y: rect.midY)
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.32), value: rect)
                }

                calloutLayer(step: step, spot: spotRect)
            }
            .ignoresSafeArea()
            .transition(.opacity)
        }
    }

    // Places the callout in the half opposite the spotlight so it never covers it.
    @ViewBuilder
    private func calloutLayer(step: TourStep, spot: CGRect?) -> some View {
        let placeAtBottom: Bool = {
            guard let spot else { return false }            // centered → card centered
            return spot.midY < proxy.size.height * 0.5      // spotlight up top → card down
        }()
        let centered = (spot == nil)

        VStack(spacing: 0) {
            if centered {
                Spacer()
                callout(step)
                Spacer()
            } else if placeAtBottom {
                Spacer()
                callout(step).padding(.bottom, 40)
            } else {
                callout(step).padding(.top, max(insets.top + 8, 60))
                Spacer()
            }
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func callout(_ step: TourStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                progressDots
                Spacer()
                Button("Пропустить".localized()) { tour.finish() }
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }

            Text(step.title.localized())
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)

            Text(step.text.localized())
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                if tour.index > 0 {
                    Button("Назад".localized()) { tour.back() }
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .frame(minHeight: 44)
                }
                Spacer()
                Button {
                    tour.next()
                } label: {
                    Text(tour.isLast ? "Поехали".localized() : "Далее".localized())
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(DesignSystem.Colors.neonGreen))
                }
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.05))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.08), Color.white.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 22, x: 0, y: 12)
        .frame(maxWidth: 380)
    }

    private var progressDots: some View {
        HStack(spacing: 5) {
            ForEach(tour.steps.indices, id: \.self) { i in
                Capsule()
                    .fill(i == tour.index
                          ? DesignSystem.Colors.neonGreen
                          : Color.white.opacity(0.2))
                    .frame(width: i == tour.index ? 18 : 6, height: 6)
            }
        }
    }
}
