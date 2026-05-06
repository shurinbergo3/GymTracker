//
//  AICoachWidget.swift
//  GymTracker
//
//  Post-workout AI Coach card. Reads the latest assistant message from
//  SwiftData via @Query and routes the user into a full chat sheet.
//

import SwiftUI
import SwiftData

// MARK: - Widget

struct AICoachWidget: View {

    let lastSession: WorkoutSession?
    let previousSession: WorkoutSession?  // kept for API compat (unused now)

    @ObservedObject private var store = AICoachStore.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var workoutManager: WorkoutManager

    /// Latest assistant message — the "current insight" preview.
    @Query(
        filter: #Predicate<AICoachMessage> { $0.kind == "assistant" },
        sort: \AICoachMessage.timestamp,
        order: .reverse
    )
    private var assistantMessages: [AICoachMessage]

    @State private var glowPhase: Double = 0
    @State private var showingChat = false

    init(lastSession: WorkoutSession?, previousSession: WorkoutSession? = nil) {
        self.lastSession = lastSession
        self.previousSession = previousSession
    }

    private var latestInsight: AICoachMessage? { assistantMessages.first }
    private var hasInsight: Bool { latestInsight != nil }

    // MARK: Layout

    var body: some View {
        Button {
            if lastSession != nil { showingChat = true }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                header
                bubble
                footerRow
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
        .disabled(lastSession == nil)
        .onAppear {
            store.attach(modelContext)
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
        .sheet(isPresented: $showingChat) {
            AICoachChatSheet()
                .environment(\.modelContext, modelContext)
                .environmentObject(workoutManager)
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
                    Text("AI Coach".localized())
                        .font(DesignSystem.Typography.title3())
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    Circle()
                        .fill(statusDotColor)
                        .frame(width: 7, height: 7)
                        .shadow(color: statusDotColor, radius: 6)
                }

                Text(headerSubtitle.uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.2)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }

            Spacer()

            if lastSession != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
        }
    }

    private var headerSubtitle: String {
        if lastSession == nil { return "Готов помочь".localized() }
        if store.isAnalyzing { return "Анализирую тренировку…".localized() }
        if hasInsight { return "Разбор последней тренировки".localized() }
        return "Готов к разбору".localized()
    }

    private var statusDotColor: Color {
        if store.isAnalyzing || store.isReplying { return .orange }
        if store.lastError != nil { return .red }
        return DesignSystem.Colors.neonGreen
    }

    // MARK: - Bubble

    private var bubble: some View {
        HStack(alignment: .top, spacing: 10) {
            Capsule()
                .fill(Color.white.opacity(0.06))
                .frame(width: 3, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                bubbleContent
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

    @ViewBuilder
    private var bubbleContent: some View {
        if lastSession == nil {
            Text("Начните тренировку, после чего я буду анализировать и давать рекомендации.".localized())
                .font(DesignSystem.Typography.body())
                .foregroundStyle(DesignSystem.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        } else if let err = store.lastError, !hasInsight {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(err)
                    .font(DesignSystem.Typography.body())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else if store.isAnalyzing && !hasInsight {
            HStack(spacing: 8) {
                ProgressView().tint(DesignSystem.Colors.neonGreen)
                Text("Анализирую тренировку, датчики и комментарии…".localized())
                    .font(DesignSystem.Typography.body())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
            }
        } else if let insight = latestInsight {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                Text("Разбор".localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.2)
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
            }
            Text(insight.text)
                .font(DesignSystem.Typography.body())
                .foregroundStyle(DesignSystem.Colors.primaryText)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("Открой чат, чтобы получить разбор.".localized())
                .font(DesignSystem.Typography.body())
                .foregroundStyle(DesignSystem.Colors.primaryText)
        }
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: 8) {
            if lastSession != nil, hasInsight {
                let remaining = store.questionsRemaining(mode: .post)
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%d/%d ".localized(),
                                remaining,
                                AICoachStore.maxPostQuestions) + "вопросов".localized())
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(DesignSystem.Colors.neonGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(DesignSystem.Colors.neonGreen.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()

            if lastSession != nil {
                Text("Открыть чат ›".localized())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
            }
        }
    }

    // MARK: - Background / stroke

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

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AICoachWidget(lastSession: nil)
            .padding()
    }
}
