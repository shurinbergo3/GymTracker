//
//  AICoachStore.swift
//  GymTracker
//
//  Observable façade for the Groq-backed AI coach. Owns the chat state for
//  the current "cycle" (one workout → next workout), enforces:
//    • 15 follow-up questions max per cycle
//    • 30-second cooldown between user questions
//  Persists messages and counters in UserDefaults so the user can close the
//  app and pick up the conversation later.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Chat message (Codable wrapper around GroqMessage with extras)

struct AICoachChatMessage: Identifiable, Codable, Hashable {
    enum Kind: String, Codable {
        case user, assistant
    }
    let id: UUID
    let kind: Kind
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), kind: Kind, text: String, timestamp: Date = Date()) {
        self.id = id
        self.kind = kind
        self.text = text
        self.timestamp = timestamp
    }
}

// MARK: - Persisted state

private struct AICoachPersistedState: Codable {
    var cycleStartedAt: Date
    var lastWorkoutSignature: String?  // "<sessionDate.timeIntervalSince1970>" or nil
    var messages: [AICoachChatMessage]
    var followUpQuestionsUsed: Int
    var lastQuestionAt: Date?
    /// Hidden conversation history kept for the model (system + user + assistant).
    /// Stored separately because it includes the bulky context block.
    var conversation: [GroqMessage]
}

// MARK: - Store

@MainActor
final class AICoachStore: ObservableObject {

    static let shared = AICoachStore()

    // Tunables
    static let maxFollowUpQuestions = 15
    static let questionCooldown: TimeInterval = 30

    // Public state
    @Published private(set) var messages: [AICoachChatMessage] = []
    @Published private(set) var isAnalyzing = false
    @Published private(set) var isReplying = false
    @Published private(set) var followUpQuestionsUsed: Int = 0
    @Published private(set) var lastError: String?
    @Published private(set) var lastWorkoutSignature: String?
    @Published private(set) var lastQuestionAt: Date?

    // Drives the cooldown countdown UI
    @Published private(set) var nowTick: Date = Date()

    private var conversation: [GroqMessage] = []
    private var cycleStartedAt: Date = Date()
    private var tickTimer: Timer?

    private let defaults = UserDefaults.standard
    private static let storageKey = "AICoachStore.persistedState.v1"

    // MARK: - Lifecycle

    private init() {
        loadFromDisk()
        startTick()
    }

    private func startTick() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.nowTick = Date() }
        }
        // Don't keep the device awake just for a counter
        if let t = tickTimer { RunLoop.main.add(t, forMode: .common) }
    }

    // MARK: - Derived

    var hasInsight: Bool { !messages.isEmpty }

    var latestAssistantInsight: AICoachChatMessage? {
        messages.last { $0.kind == .assistant }
    }

    /// Time remaining on the cooldown, or 0 if a question can be sent now.
    var cooldownRemaining: TimeInterval {
        guard let last = lastQuestionAt else { return 0 }
        let elapsed = nowTick.timeIntervalSince(last)
        return max(0, Self.questionCooldown - elapsed)
    }

    var canAskQuestion: Bool {
        !isAnalyzing
        && !isReplying
        && followUpQuestionsUsed < Self.maxFollowUpQuestions
        && cooldownRemaining <= 0
        && hasInsight  // need an analysis first
    }

    var questionsRemaining: Int {
        max(0, Self.maxFollowUpQuestions - followUpQuestionsUsed)
    }

    // MARK: - Public API

    /// Called from `WorkoutManager.finishWorkout()` after a session is saved.
    /// Resets the cycle, builds a fresh context and asks the model for an
    /// analysis. Idempotent if the same session is passed in twice.
    func analyzeFinishedWorkout(session: WorkoutSession,
                                modelContext: ModelContext,
                                healthManager: HealthManager) async {

        let signature = signature(for: session)
        if signature == lastWorkoutSignature, hasInsight {
            // Already analysed — don't burn tokens.
            return
        }

        // Reset cycle
        messages = []
        conversation = []
        followUpQuestionsUsed = 0
        lastQuestionAt = nil
        cycleStartedAt = Date()
        lastWorkoutSignature = signature
        lastError = nil
        isAnalyzing = true
        persist()

        let ctx = await AICoachContextBuilder.build(
            modelContext: modelContext,
            healthManager: healthManager,
            limit: 4
        )
        let contextBlock = AICoachContextBuilder.renderForPrompt(ctx)

        let systemPrompt = Self.systemPrompt
        let firstUserPrompt = """
        Проанализируй мою только что завершённую тренировку с учётом последних 4 сессий и данных датчиков. \
        Выдай разбор по структуре:
        1) Краткая оценка (1–2 предложения).
        2) Что сработало хорошо.
        3) Что улучшить (форма, объём, темп, восстановление).
        4) План на следующую тренировку с конкретными цифрами (вес/повторы/подходы) — мягкая прогрессия нагрузок, если нет жалоб на здоровье.
        Если в комментариях встречаются жалобы (боль, дискомфорт, болезнь) — отдельно отметь это и предложи альтернативы или паузу.
        Будь конкретным, без воды. Максимум 220 слов.

        ДАННЫЕ:
        \(contextBlock)
        """

        let initialMessages: [GroqMessage] = [
            .init(role: .system, content: systemPrompt),
            .init(role: .user, content: firstUserPrompt)
        ]

        do {
            let reply = try await GroqClient.shared.complete(
                messages: initialMessages,
                temperature: 0.4,
                maxTokens: 700
            )
            conversation = initialMessages + [.init(role: .assistant, content: reply)]
            messages = [AICoachChatMessage(kind: .assistant, text: reply)]
            isAnalyzing = false
            lastError = nil
            persist()
        } catch {
            isAnalyzing = false
            lastError = (error as? GroqError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// User's free-form follow-up question. Enforces the 15/cycle and 30 s
    /// cooldown limits — call sites should also disable the input when
    /// `canAskQuestion == false`, but this is a hard guard.
    func askFollowUp(_ rawText: String) async {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard canAskQuestion else { return }

        followUpQuestionsUsed += 1
        lastQuestionAt = Date()
        let userMsg = AICoachChatMessage(kind: .user, text: text)
        messages.append(userMsg)
        conversation.append(.init(role: .user, content: text))
        isReplying = true
        lastError = nil
        persist()

        do {
            let reply = try await GroqClient.shared.complete(
                messages: conversation,
                temperature: 0.5,
                maxTokens: 600
            )
            conversation.append(.init(role: .assistant, content: reply))
            messages.append(AICoachChatMessage(kind: .assistant, text: reply))
            isReplying = false
            persist()
        } catch {
            isReplying = false
            lastError = (error as? GroqError)?.errorDescription ?? error.localizedDescription
            // Refund the question on hard failure so users aren't punished for network issues.
            followUpQuestionsUsed = max(0, followUpQuestionsUsed - 1)
            persist()
        }
    }

    /// Manually wipe state — useful for "Очистить чат" / settings.
    func resetCycle() {
        messages = []
        conversation = []
        followUpQuestionsUsed = 0
        lastQuestionAt = nil
        lastWorkoutSignature = nil
        lastError = nil
        cycleStartedAt = Date()
        persist()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = defaults.data(forKey: Self.storageKey) else { return }
        guard let decoded = try? JSONDecoder().decode(AICoachPersistedState.self, from: data) else { return }
        self.cycleStartedAt = decoded.cycleStartedAt
        self.lastWorkoutSignature = decoded.lastWorkoutSignature
        self.messages = decoded.messages
        self.followUpQuestionsUsed = decoded.followUpQuestionsUsed
        self.lastQuestionAt = decoded.lastQuestionAt
        self.conversation = decoded.conversation
    }

    private func persist() {
        let state = AICoachPersistedState(
            cycleStartedAt: cycleStartedAt,
            lastWorkoutSignature: lastWorkoutSignature,
            messages: messages,
            followUpQuestionsUsed: followUpQuestionsUsed,
            lastQuestionAt: lastQuestionAt,
            conversation: conversation
        )
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    private func signature(for session: WorkoutSession) -> String {
        // Workout sessions don't expose a stable id, but date + workoutDayName
        // is unique enough — two sessions can't start at the exact same instant.
        return "\(session.date.timeIntervalSince1970)|\(session.workoutDayName)"
    }

    // MARK: - System prompt

    private static let systemPrompt: String = """
    Ты — персональный фитнес-коуч с 20-летним стажем работы с любителями и спортсменами. \
    Твои сильные стороны: построение тела, силовой тренинг, прогрессия нагрузок, \
    восстановление и сохранение здоровья суставов и сердечно-сосудистой системы.

    Принципы общения:
    • Отвечай кратко и по делу. Маркированные списки — приветствуются.
    • Опирайся ТОЛЬКО на данные, которые тебе передали (тренировки, комментарии, датчики, профиль). \
      Не выдумывай цифры, которых нет.
    • Подталкивай к прогрессии нагрузок (вес/повторы/объём), но всегда соотноси её с восстановлением, сном, пульсом покоя и комментариями к подходам.
    • Если в комментариях есть упоминания боли, травмы или болезни — НЕ настаивай на нагрузке. Предложи альтернативное упражнение, регресс по нагрузке или отдых, и порекомендуй обратиться к врачу.
    • Никогда не ставь диагнозы и не назначай лечение. Ты не врач.
    • Если данных недостаточно для уверенного вывода — так и скажи и попроси уточнения.
    • Отвечай на языке пользователя (по умолчанию — русский).
    • Не используй markdown заголовки (#, ##) — только короткие пункты и абзацы.
    """
}
