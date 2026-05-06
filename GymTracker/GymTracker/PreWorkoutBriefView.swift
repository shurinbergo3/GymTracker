//
//  PreWorkoutBriefView.swift
//  GymTracker
//
//  AI Pre-Workout Brief — shown between the user tapping "Start" and the
//  3-2-1 countdown. The coach generates a tight forecast for today's session
//  (readiness, target weights, technique focus). The user can fire up to
//  5 follow-up questions before kicking off the workout.
//
//  Lifecycle is driven by `WorkoutManager.workoutState`:
//      .idle → (user taps Start) → .briefing → (user taps Поехали) → .countdown
//
//  UI principles:
//  • The brief itself is the hero — input controls don't compete for space.
//  • The "Задать вопрос" pill is intentionally subdued so "Поехали" reads as
//    the primary action.
//  • The composer lives in a half-sheet so the brief stays visible while
//    typing (and so we don't waste vertical space on a permanent text field).
//

import SwiftUI
import SwiftData

struct PreWorkoutBriefView: View {

    @ObservedObject private var store = AICoachStore.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var workoutManager: WorkoutManager

    @State private var showingComposer = false

    @Query private var briefMessages: [AICoachMessage]

    init() {
        let sig = AICoachStore.shared.lastBriefSignature
        let predicate = #Predicate<AICoachMessage> {
            $0.workoutSignature != nil && $0.workoutSignature == sig
        }
        _briefMessages = Query(
            filter: predicate,
            sort: [SortDescriptor(\AICoachMessage.timestamp, order: .forward)]
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Backdrop: subtle aurora behind the sheet so the brief feels
            // calm but on-brand.
            backdrop.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                messages
                bottomActions
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { store.attach(modelContext) }
        .sheet(isPresented: $showingComposer) {
            PreBriefComposerSheet()
                .environmentObject(workoutManager)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        ZStack {
            DesignSystem.Colors.background
            LinearGradient(
                colors: [
                    DesignSystem.Colors.accentPurple.opacity(0.22),
                    DesignSystem.Colors.background.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                workoutManager.cancelBriefing()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.5))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Подготовка к тренировке".localized())
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                if let day = workoutManager.selectedDay {
                    Text(day.name)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
            }
            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                workoutManager.proceedToCountdown()
            } label: {
                Text("Пропустить".localized())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Messages scroll

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    heroBanner

                    if briefMessages.isEmpty && !store.isBriefing {
                        emptyHint
                    }

                    ForEach(briefMessages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }

                    if store.isBriefing || store.isReplying {
                        TypingIndicator().id("typing")
                    }

                    if let err = store.lastError {
                        errorBanner(err)
                    }

                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
            }
            .onChange(of: briefMessages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    if let last = briefMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: store.isReplying) { _, replying in
                if replying { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
    }

    // Compact hero — small avatar + tight title. We pulled a lot of weight out
    // of the previous version so the actual brief gets more screen.
    private var heroBanner: some View {
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
                    .frame(width: 44, height: 44)
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Брифинг от коуча".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Готовность · цели · фокус".localized())
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var emptyHint: some View {
        Text("Анализирую план и историю последних тренировок…".localized())
            .font(DesignSystem.Typography.body())
            .foregroundStyle(DesignSystem.Colors.secondaryText)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.orange.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.35), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        VStack(spacing: 10) {
            askButton
            goButton
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            // Soft material so messages don't bleed into the buttons.
            LinearGradient(
                colors: [
                    DesignSystem.Colors.background.opacity(0.0),
                    DesignSystem.Colors.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    /// Subdued "Ask question" pill — opens the composer in a half-sheet.
    /// Kept dimmer than the primary CTA so the user reads "Поехали" first.
    private var askButton: some View {
        let canAsk = store.canAskQuestion(mode: .pre)
        let remaining = store.questionsRemaining(mode: .pre)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showingComposer = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 13, weight: .heavy))
                Text(askLabel)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Spacer()
                Text("\(remaining)/\(AICoachStore.maxPreQuestions)")
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .foregroundStyle(.white.opacity(canAsk ? 0.82 : 0.35))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(canAsk ? 0.07 : 0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canAsk)
    }

    private var askLabel: String {
        if !store.hasInsight(for: .pre) {
            return "Дождись брифинга…".localized()
        }
        if store.questionsRemaining(mode: .pre) == 0 {
            return "Лимит вопросов исчерпан".localized()
        }
        if store.cooldownRemaining > 0 {
            return String(format: "Можно через %d сек".localized(),
                          Int(ceil(store.cooldownRemaining)))
        }
        return "Задать вопрос".localized()
    }

    /// Primary CTA — the bright path forward. Always neon green so it dominates.
    private var goButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            workoutManager.proceedToCountdown()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .heavy))
                Text("Поехали".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.neonGreen,
                        DesignSystem.Colors.neonGreen.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Composer sheet

/// Half-sheet composer that opens when the user taps "Задать вопрос". Sends
/// through `AICoachStore.askFollowUp(_, mode: .pre)` and dismisses on success.
private struct PreBriefComposerSheet: View {

    @ObservedObject private var store = AICoachStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    private var canSend: Bool {
        store.canAskQuestion(mode: .pre)
            && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 14) {
                header

                ZStack(alignment: .topLeading) {
                    if draft.isEmpty {
                        Text("Например: оставить ли становую сегодня, если плохо спал?".localized())
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $draft)
                        .focused($focused)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(.white)
                }
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(maxHeight: .infinity)

                if let err = store.lastError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                sendButton
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                focused = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(DesignSystem.Colors.neonGreen)
            Text("Спроси перед тренировкой".localized())
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
            Spacer()
            Text("\(store.questionsRemaining(mode: .pre))/\(AICoachStore.maxPreQuestions)")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .padding(.top, 18)
    }

    private var sendButton: some View {
        Button(action: send) {
            HStack(spacing: 8) {
                if store.isReplying {
                    ProgressView().tint(.black)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .heavy))
                }
                Text("Отправить".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(canSend ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!canSend)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let snapshot = text
        draft = ""
        focused = false
        Task {
            await store.askFollowUp(snapshot, mode: .pre)
            // Close the sheet on success so the user is back to the brief and
            // can read the answer in the main scroll.
            await MainActor.run {
                if store.lastError == nil { dismiss() }
            }
        }
    }
}
