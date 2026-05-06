//
//  AICoachChatSheet.swift
//  GymTracker
//
//  AI Coach modal: tab 1 = current cycle's chat (post-workout analysis +
//  follow-up Q/A with rate limit), tab 2 = the full per-day history.
//

import SwiftUI
import SwiftData

// MARK: - Sheet

struct AICoachChatSheet: View {

    enum Tab: Hashable { case chat, history }

    @ObservedObject private var store = AICoachStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var workoutManager: WorkoutManager

    @State private var tab: Tab = .chat
    @State private var draft: String = ""
    @FocusState private var inputFocused: Bool

    /// Messages for the **current** cycle only — drives the chat tab.
    @Query private var cycleMessages: [AICoachMessage]

    init() {
        // Bind the @Query to the active cycle signature persisted in UserDefaults
        // (so it survives app relaunch).
        let sig = AICoachStore.shared.lastWorkoutSignature
        let predicate = #Predicate<AICoachMessage> {
            $0.workoutSignature != nil && $0.workoutSignature == sig
        }
        _cycleMessages = Query(
            filter: predicate,
            sort: [SortDescriptor(\AICoachMessage.timestamp, order: .forward)]
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                LinearGradient(
                    colors: [
                        DesignSystem.Colors.accentPurple.opacity(0.18),
                        DesignSystem.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .frame(maxHeight: 280)
                .frame(maxHeight: .infinity, alignment: .top)

                VStack(spacing: 0) {
                    tabSwitcher
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, 6)

                    Group {
                        switch tab {
                        case .chat:    chatPane
                        case .history: AICoachHistoryView()
                        }
                    }
                }
            }
            .navigationTitle("AI Coach".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                        Text("Персональный коуч".localized())
                            .font(DesignSystem.Typography.headline())
                            .foregroundStyle(DesignSystem.Colors.primaryText)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done_button".localized()) { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                }
            }
            .onAppear { store.attach(modelContext) }
        }
        .presentationDetents([.large])
    }

    // MARK: - Tab switcher

    private var tabSwitcher: some View {
        HStack(spacing: 6) {
            tabButton("Сейчас".localized(), .chat, icon: "sparkles")
            tabButton("История".localized(), .history, icon: "clock.arrow.circlepath")
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }

    private func tabButton(_ title: String, _ value: Tab, icon: String) -> some View {
        let active = tab == value
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { tab = value }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .bold))
                Text(title).font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(active ? .black : DesignSystem.Colors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(active ? DesignSystem.Colors.neonGreen : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chat pane

    private var chatPane: some View {
        VStack(spacing: 0) {
            messagesScroll
            Divider().background(Color.white.opacity(0.05))
            inputBar
        }
    }

    private var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    heroBanner

                    if cycleMessages.isEmpty && !store.isAnalyzing {
                        emptyHint
                    }

                    ForEach(cycleMessages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }

                    if store.isAnalyzing || store.isReplying {
                        TypingIndicator()
                            .id("typing")
                    }

                    if let err = store.lastError {
                        errorBanner(err)
                    }

                    disclaimer
                        .padding(.top, 6)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.md)
                .padding(.bottom, 12)
            }
            .onChange(of: cycleMessages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    if let last = cycleMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: store.isReplying) { _, replying in
                if replying {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

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
                    .frame(width: 56, height: 56)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Анализ тренировки".localized())
                    .font(DesignSystem.Typography.title2())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text("20 лет опыта · прогрессия и здоровье".localized())
                    .font(.callout)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
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

    private var emptyHint: some View {
        Text("Начните тренировку, после чего я буду анализировать и давать рекомендации.".localized())
            .font(DesignSystem.Typography.body())
            .foregroundStyle(DesignSystem.Colors.secondaryText)
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.cardBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .foregroundStyle(DesignSystem.Colors.primaryText)
            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Spacing.md)
        .background(Color.orange.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(Color.orange.opacity(0.35), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var disclaimer: some View {
        Text("Рекомендации носят информационный характер и не заменяют консультацию врача. При боли, недомогании или хронических заболеваниях обратитесь к специалисту.".localized())
            .font(.system(size: 11))
            .foregroundStyle(DesignSystem.Colors.tertiaryText)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 6) {
            counterRow

            HStack(spacing: 10) {
                ZStack(alignment: .topLeading) {
                    if draft.isEmpty {
                        Text(placeholderText)
                            .foregroundStyle(DesignSystem.Colors.tertiaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $draft)
                        .focused($inputFocused)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .frame(minHeight: 38, maxHeight: 110)
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                        .disabled(!store.canAskQuestion(mode: .post))
                }
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )

                Button(action: send) {
                    ZStack {
                        Circle()
                            .fill(sendButtonEnabled ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.08))
                            .frame(width: 38, height: 38)
                        Image(systemName: store.isReplying ? "ellipsis" : "arrow.up")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(sendButtonEnabled ? .black : DesignSystem.Colors.tertiaryText)
                    }
                }
                .disabled(!sendButtonEnabled)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var sendButtonEnabled: Bool {
        store.canAskQuestion(mode: .post) && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var placeholderText: String {
        if !store.hasInsight(for: .post) {
            return "Дождись разбора, потом задавай вопросы…".localized()
        }
        if store.questionsRemaining(mode: .post) == 0 {
            return "Лимит вопросов исчерпан до следующей тренировки.".localized()
        }
        return "Спроси коуча…".localized()
    }

    private var counterRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 9, weight: .bold))
                Text(String(format: "%d/%d ",
                            store.questionsRemaining(mode: .post),
                            AICoachStore.maxPostQuestions) + "вопросов".localized())
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(DesignSystem.Colors.neonGreen)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DesignSystem.Colors.neonGreen.opacity(0.12))
            .clipShape(Capsule())

            if store.cooldownRemaining > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "ещё %d сек".localized(), Int(ceil(store.cooldownRemaining))))
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    // MARK: - Actions

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        inputFocused = false
        Task { await store.askFollowUp(text, mode: .post) }
    }
}

// MARK: - Message bubble

struct MessageBubble: View {
    let message: AICoachMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isAssistant {
                avatar
            } else {
                Spacer(minLength: 40)
            }

            Text(message.text)
                .font(DesignSystem.Typography.body())
                .foregroundStyle(DesignSystem.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(bubbleBg)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(strokeColor, lineWidth: 0.5)
                )
                .frame(maxWidth: .infinity, alignment: message.isAssistant ? .leading : .trailing)

            if message.isUser {
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 40)
            }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [DesignSystem.Colors.accentPurple, DesignSystem.Colors.neonGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.black)
        }
    }

    private var bubbleBg: some View {
        Group {
            if message.isAssistant {
                LinearGradient(
                    colors: [Color.white.opacity(0.07), Color.white.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.neonGreen.opacity(0.18),
                        DesignSystem.Colors.accentPurple.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var strokeColor: Color {
        message.isAssistant
            ? Color.white.opacity(0.06)
            : DesignSystem.Colors.neonGreen.opacity(0.25)
    }
}

// MARK: - Typing indicator

struct TypingIndicator: View {
    @State private var phase: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.accentPurple, DesignSystem.Colors.neonGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.black)
            }

            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(DesignSystem.Colors.neonGreen.opacity(0.7))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == Double(i) ? 1.3 : 0.8)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer(minLength: 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                phase = 2
            }
        }
    }
}
