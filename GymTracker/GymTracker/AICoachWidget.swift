//
//  AICoachWidget.swift
//  GymTracker
//
//  Post-workout AI Coach card. Currently renders mock insights based on
//  the last session metrics; the recommendation pipeline (LLM/Claude API)
//  will plug into `AICoachInsightBuilder.makeInsights(...)` later.
//

import SwiftUI

// MARK: - Insight Model

struct AICoachInsight: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let tint: Color
    let title: String
    let body: String
}

// MARK: - Builder (mock — replace with LLM later)

enum AICoachInsightBuilder {
    static func makeInsights(for session: WorkoutSession?, previous: WorkoutSession? = nil) -> [AICoachInsight] {
        guard let session = session else {
            return [AICoachInsight(
                icon: "sparkles",
                tint: DesignSystem.Colors.neonGreen,
                title: "Готов к старту?".localized(),
                body: "Заверши первую тренировку — и я подготовлю персональный разбор.".localized()
            )]
        }

        var insights: [AICoachInsight] = []

        // Duration insight
        if let end = session.endTime {
            let mins = Int(end.timeIntervalSince(session.date) / 60)
            if mins > 0 {
                insights.append(AICoachInsight(
                    icon: "clock.fill",
                    tint: .cyan,
                    title: "Темп".localized(),
                    body: durationCaption(mins: mins)
                ))
            }
        }

        // Volume / sets insight
        let setsCount = session.sets.count
        if setsCount > 0 {
            let prevSets = previous?.sets.count ?? 0
            let delta = setsCount - prevSets
            let body: String
            if previous == nil {
                body = "\(setsCount) " + "подходов выполнено. Базовая отметка зафиксирована.".localized()
            } else if delta > 0 {
                body = "+\(delta) " + "подходов к прошлому разу — прогресс налицо.".localized()
            } else if delta < 0 {
                body = String(format: "Подходов меньше на %d. Подумай, что мешало — восстановление?".localized(), abs(delta))
            } else {
                body = "Объём стабилен. Время на следующей добавить вес или повторы.".localized()
            }
            insights.append(AICoachInsight(
                icon: "chart.bar.fill",
                tint: DesignSystem.Colors.neonGreen,
                title: "Объём".localized(),
                body: body
            ))
        }

        // Heart rate
        if let avgHR = session.averageHeartRate, avgHR > 0 {
            insights.append(AICoachInsight(
                icon: "heart.fill",
                tint: Color(red: 1.0, green: 0.35, blue: 0.45),
                title: "Пульс".localized(),
                body: "Средний \(avgHR) уд/мин — " + heartRateZoneCaption(avgHR)
            ))
        }

        // Recommendation for next session
        insights.append(AICoachInsight(
            icon: "lightbulb.fill",
            tint: Color(red: 1.0, green: 0.75, blue: 0.2),
            title: "На следующую".localized(),
            body: nextRecommendation(for: session, previous: previous)
        ))

        return insights
    }

    private static func durationCaption(mins: Int) -> String {
        switch mins {
        case 0..<25:
            return "\(mins) " + "мин — короткая, но плотная сессия.".localized()
        case 25..<55:
            return "\(mins) " + "мин — отличный темп, держим планку.".localized()
        case 55..<90:
            return "\(mins) " + "мин — длинная сессия, следи за восстановлением.".localized()
        default:
            return "\(mins) " + "мин — очень длинная, не пережимай.".localized()
        }
    }

    private static func heartRateZoneCaption(_ hr: Int) -> String {
        switch hr {
        case 0..<110:  return "лёгкая зона, можно ускоряться.".localized()
        case 110..<140: return "жиросжигающая зона.".localized()
        case 140..<165: return "аэробная зона, отличный режим.".localized()
        default:        return "интенсивная зона — держись осторожнее.".localized()
        }
    }

    private static func nextRecommendation(for session: WorkoutSession, previous: WorkoutSession?) -> String {
        let calories = session.calories ?? 0
        if calories > 350 {
            return "Добавь +5% к рабочему весу в базовых упражнениях.".localized()
        } else if calories > 150 {
            return "Сделай суперсет в последнем упражнении — поднимешь интенсивность.".localized()
        } else {
            return "Сфокусируйся на технике и доведи рабочие подходы до отказа.".localized()
        }
    }
}

// MARK: - Widget

struct AICoachWidget: View {
    let lastSession: WorkoutSession?
    let previousSession: WorkoutSession?

    @State private var glowPhase: Double = 0
    @State private var showingDetail = false

    init(lastSession: WorkoutSession?, previousSession: WorkoutSession? = nil) {
        self.lastSession = lastSession
        self.previousSession = previousSession
    }

    private var insights: [AICoachInsight] {
        AICoachInsightBuilder.makeInsights(for: lastSession, previous: previousSession)
    }

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                header
                bubble
                ctaRow
            }
            .padding(DesignSystem.Spacing.lg)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(neonStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .shadow(color: DesignSystem.Colors.accentPurple.opacity(0.25), radius: 20, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
        .sheet(isPresented: $showingDetail) {
            AICoachDetailSheet(insights: insights, lastSession: lastSession)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DesignSystem.Colors.accentPurple.opacity(0.55), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 32
                        )
                    )
                    .frame(width: 64, height: 64)
                    .blur(radius: 8)
                    .opacity(0.55 + glowPhase * 0.45)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.accentPurple, DesignSystem.Colors.neonGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.black)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("AI Coach")
                        .font(DesignSystem.Typography.title3())
                        .foregroundStyle(DesignSystem.Colors.primaryText)

                    Circle()
                        .fill(DesignSystem.Colors.neonGreen)
                        .frame(width: 7, height: 7)
                        .shadow(color: DesignSystem.Colors.neonGreen, radius: 6)
                }

                Text(headerSubtitle.uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.2)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
    }

    private var headerSubtitle: String {
        if lastSession == nil {
            return "Готов помочь".localized()
        } else {
            return "Разбор последней тренировки".localized()
        }
    }

    // MARK: - Bubble (primary insight)
    private var bubble: some View {
        let primary = insights.first
        return HStack(alignment: .top, spacing: 10) {
            // Tail
            Capsule()
                .fill(Color.white.opacity(0.06))
                .frame(width: 3, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                if let primary = primary {
                    HStack(spacing: 6) {
                        Image(systemName: primary.icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(primary.tint)
                        Text(primary.title.uppercased())
                            .font(DesignSystem.Typography.sectionHeader())
                            .tracking(1.2)
                            .foregroundStyle(primary.tint)
                    }
                    Text(primary.body)
                        .font(DesignSystem.Typography.body())
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
        }
    }

    // MARK: - CTA row (secondary insights count)
    private var ctaRow: some View {
        let extra = max(0, insights.count - 1)
        return HStack(spacing: 8) {
            // Mini chips for extra insights
            ForEach(insights.dropFirst().prefix(3)) { ins in
                HStack(spacing: 4) {
                    Image(systemName: ins.icon)
                        .font(.system(size: 9, weight: .bold))
                    Text(ins.title)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(ins.tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(ins.tint.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()

            if extra > 0 {
                Text("ещё \(extra) ›".localized())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
            }
        }
    }

    // MARK: - Background
    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.08, blue: 0.16),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial accent
            RadialGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 220
            )
            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 4,
                endRadius: 240
            )
        }
    }

    private var neonStroke: LinearGradient {
        LinearGradient(
            colors: [
                DesignSystem.Colors.accentPurple.opacity(0.55),
                DesignSystem.Colors.neonGreen.opacity(0.35),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Detail Sheet

private struct AICoachDetailSheet: View {
    let insights: [AICoachInsight]
    let lastSession: WorkoutSession?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero

                    ForEach(insights) { insight in
                        insightCard(insight)
                    }

                    disclaimer
                }
                .padding(DesignSystem.Spacing.lg)
                .padding(.bottom, 40)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done_button".localized()) { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.accentPurple, DesignSystem.Colors.neonGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Анализ тренировки".localized())
                        .font(DesignSystem.Typography.title2())
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    if let session = lastSession {
                        Text(formatSessionDate(session.date))
                            .font(.callout)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    } else {
                        Text("Начни первую тренировку".localized())
                            .font(.callout)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                }
                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            LinearGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.20), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.accentPurple.opacity(0.35), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private func insightCard(_ insight: AICoachInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(insight.tint.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: insight.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(insight.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title.uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.2)
                    .foregroundStyle(insight.tint)
                Text(insight.body)
                    .font(DesignSystem.Typography.body())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var disclaimer: some View {
        Text("Скоро здесь будет персональный AI-разбор на основе всех твоих тренировок и здоровья.".localized())
            .font(.caption)
            .foregroundStyle(DesignSystem.Colors.tertiaryText)
            .padding(.top, 8)
    }

    private func formatSessionDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.dateFormat = "d MMM, HH:mm"
        return f.string(from: date)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AICoachWidget(lastSession: nil)
            .padding()
    }
}
