//
//  AICoachStore.swift
//  GymTracker
//
//  Observable façade for the Groq-backed AI coach.
//
//  Storage split:
//  • Messages and the cached weekly summary live in **SwiftData** so users get
//    a permanent, day-by-day history they can browse.
//  • Each insert is fire-and-forget pushed to **Firestore** for cross-device
//    history, with the same `isSynced`-flag pattern used for WorkoutSession.
//  • Ephemeral counters (current cycle's question count, last-question
//    timestamp, current workout signature) live in **UserDefaults** — they're
//    small, churn fast, and don't belong in the persistent DB.
//
//  Token economy: before every new analysis we take the last 7 days of
//  conversation, ask Groq for a tight digest, and feed that digest (≤ 100 words)
//  into the new prompt instead of the raw transcript.
//
//  Language: the model is told to mirror the user's language. The kickoff
//  prompt is rendered in whichever language the app is currently configured to
//  (see `LanguageManager.shared.currentLocale`), so the very first reply
//  greets the user in their UI language.
//

import Foundation
import SwiftUI
import SwiftData
import FirebaseAuth

// MARK: - Store

@MainActor
final class AICoachStore: ObservableObject {

    static let shared = AICoachStore()

    // Tunables
    static let maxFollowUpQuestions = 15
    static let questionCooldown: TimeInterval = 30
    /// Regenerate the weekly digest if it's older than this.
    static let summaryStaleAfter: TimeInterval = 24 * 3600
    /// Or if this many new messages have appeared since the cached digest.
    static let summaryStaleAfterMessages = 5

    // MARK: Public observable state

    @Published private(set) var isAnalyzing = false
    @Published private(set) var isReplying = false
    @Published private(set) var followUpQuestionsUsed: Int = 0
    @Published private(set) var lastError: String?
    @Published private(set) var lastWorkoutSignature: String?
    @Published private(set) var lastQuestionAt: Date?
    /// Drives the cooldown countdown UI. Updated by a 1 Hz timer.
    @Published private(set) var nowTick: Date = Date()

    // MARK: Private

    private weak var modelContext: ModelContext?
    private var tickTimer: Timer?
    private var didPullCloudThisSession = false

    private let defaults = UserDefaults.standard
    private static let kCounters = "AICoachStore.counters.v2"

    // MARK: Lifecycle

    private init() {
        loadCountersFromDisk()
        startTick()
    }

    /// Call once from a long-lived view (e.g. AICoachWidget.onAppear) so the
    /// store can talk to SwiftData without every callsite passing context.
    /// Also triggers a one-shot cloud history pull per app session.
    func attach(_ context: ModelContext) {
        self.modelContext = context
        if !didPullCloudThisSession {
            didPullCloudThisSession = true
            Task { await pullCloudHistory() }
        }
    }

    private func startTick() {
        tickTimer?.invalidate()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.nowTick = Date() }
        }
        RunLoop.main.add(t, forMode: .common)
        tickTimer = t
    }

    // MARK: Derived

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
        && hasInsightForCurrentCycle
    }

    var questionsRemaining: Int {
        max(0, Self.maxFollowUpQuestions - followUpQuestionsUsed)
    }

    /// True iff we've recorded at least one assistant analysis for the
    /// current workout cycle.
    var hasInsightForCurrentCycle: Bool {
        guard let sig = lastWorkoutSignature, let ctx = modelContext else { return false }
        var d = FetchDescriptor<AICoachMessage>(
            predicate: #Predicate { $0.workoutSignature == sig && $0.kind == "assistant" }
        )
        d.fetchLimit = 1
        return ((try? ctx.fetch(d).first) != nil)
    }

    // MARK: - Public actions

    /// Called from `WorkoutManager.finishWorkout()` after a session is saved.
    func analyzeFinishedWorkout(session: WorkoutSession,
                                modelContext: ModelContext,
                                healthManager: HealthManager) async {

        attach(modelContext)
        let signature = signature(for: session)

        if signature == lastWorkoutSignature, hasInsightForCurrentCycle {
            return  // already analysed
        }

        // Reset cycle
        followUpQuestionsUsed = 0
        lastQuestionAt = nil
        lastWorkoutSignature = signature
        lastError = nil
        isAnalyzing = true
        persistCounters()

        // Build raw context (last 4 workouts + sensors + profile)
        let ctx = await AICoachContextBuilder.build(
            modelContext: modelContext,
            healthManager: healthManager,
            limit: 4
        )
        let contextBlock = AICoachContextBuilder.renderForPrompt(ctx)

        // Refresh weekly digest if needed (best-effort; on failure we just skip it)
        await refreshWeeklySummaryIfNeeded()

        let weeklyDigest = currentWeeklySummaryText()

        // Compose first prompt — language pinned to current app language.
        var initialMessages: [GroqMessage] = [
            .init(role: .system, content: Self.systemPrompt())
        ]
        if let digest = weeklyDigest, !digest.isEmpty {
            initialMessages.append(.init(role: .system, content: Self.weeklyDigestSystemPrefix() + "\n" + digest))
        }
        initialMessages.append(.init(role: .user, content: Self.firstUserPrompt(contextBlock: contextBlock)))

        do {
            let reply = try await GroqClient.shared.complete(
                messages: initialMessages,
                temperature: 0.4,
                maxTokens: 700
            )
            insertAssistantMessage(reply, signature: signature, isCycleAnalysis: true)
            isAnalyzing = false
            lastError = nil
        } catch {
            isAnalyzing = false
            lastError = (error as? GroqError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// User's free-form follow-up question. Hard guards: 15/cycle and 30 s cooldown.
    /// Rebuilds the conversation from DB so we don't keep a parallel in-memory copy.
    func askFollowUp(_ rawText: String) async {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard canAskQuestion else { return }
        guard modelContext != nil, let sig = lastWorkoutSignature else { return }

        followUpQuestionsUsed += 1
        lastQuestionAt = Date()
        isReplying = true
        lastError = nil
        persistCounters()

        // Persist the user's question right away — even if Groq fails, we want
        // the chat to show what they typed.
        insertUserMessage(text, signature: sig)

        // Reconstruct the conversation: system + (optional weekly digest) +
        // every message in the current cycle, oldest first.
        var convo: [GroqMessage] = [
            .init(role: .system, content: Self.systemPrompt())
        ]
        if let digest = currentWeeklySummaryText(), !digest.isEmpty {
            convo.append(.init(role: .system, content: Self.weeklyDigestSystemPrefix() + "\n" + digest))
        }
        let cycleMsgs = fetchMessages(forSignature: sig, ascending: true)
        for m in cycleMsgs {
            convo.append(.init(
                role: m.isUser ? .user : .assistant,
                content: m.text
            ))
        }

        do {
            let reply = try await GroqClient.shared.complete(
                messages: convo,
                temperature: 0.5,
                maxTokens: 600
            )
            insertAssistantMessage(reply, signature: sig, isCycleAnalysis: false)
            isReplying = false
        } catch {
            isReplying = false
            lastError = (error as? GroqError)?.errorDescription ?? error.localizedDescription
            // Refund the question on hard failure so users aren't punished for network issues.
            followUpQuestionsUsed = max(0, followUpQuestionsUsed - 1)
            persistCounters()
        }
    }

    /// Manually wipe everything (counters + every persisted message + summaries),
    /// locally **and** in Firestore. Used by Settings → "Очистить историю".
    func wipeAll() async {
        followUpQuestionsUsed = 0
        lastQuestionAt = nil
        lastWorkoutSignature = nil
        lastError = nil
        persistCounters()

        if let ctx = modelContext {
            if let msgs = try? ctx.fetch(FetchDescriptor<AICoachMessage>()) {
                for m in msgs { ctx.delete(m) }
            }
            if let sums = try? ctx.fetch(FetchDescriptor<AICoachWeeklySummary>()) {
                for s in sums { ctx.delete(s) }
            }
            try? ctx.save()
        }

        // Firestore wipe (best-effort)
        do {
            try await FirestoreManager.shared.deleteAllCoachMessages()
            try await FirestoreManager.shared.deleteAllCoachSummaries()
        } catch {
            #if DEBUG
            print("⚠️ AICoachStore.wipeAll Firestore: \(error.localizedDescription)")
            #endif
        }

        objectWillChange.send()
    }

    /// Pulls every message + summary from Firestore and inserts any that
    /// aren't already in the local DB. Idempotent (uses UUID PKs).
    func pullCloudHistory() async {
        guard let ctx = modelContext else { return }
        guard Auth.auth().currentUser != nil else { return }

        do {
            let remoteMessages = try await FirestoreManager.shared.fetchAllCoachMessages()
            guard !remoteMessages.isEmpty else { return }

            // Build a set of local UUIDs to skip duplicates.
            let local = (try? ctx.fetch(FetchDescriptor<AICoachMessage>())) ?? []
            let localIds = Set(local.map { $0.id })

            var inserted = 0
            for dto in remoteMessages {
                guard let m = dto.toModel() else { continue }
                if localIds.contains(m.id) { continue }
                ctx.insert(m)
                inserted += 1
            }
            if inserted > 0 {
                try? ctx.save()
                objectWillChange.send()
                #if DEBUG
                print("☁️ AICoachStore: pulled \(inserted) message(s) from Firestore")
                #endif
            }
        } catch {
            #if DEBUG
            print("⚠️ AICoachStore.pullCloudHistory: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - DB helpers

    private func insertUserMessage(_ text: String, signature: String?) {
        guard let ctx = modelContext else { return }
        let msg = AICoachMessage(
            kind: AICoachMessage.kindUser,
            text: text,
            workoutSignature: signature,
            isCycleAnalysis: false
        )
        ctx.insert(msg)
        try? ctx.save()
        objectWillChange.send()
        scheduleCloudUpload(for: msg)
    }

    private func insertAssistantMessage(_ text: String, signature: String?, isCycleAnalysis: Bool) {
        guard let ctx = modelContext else { return }
        let msg = AICoachMessage(
            kind: AICoachMessage.kindAssistant,
            text: text,
            workoutSignature: signature,
            isCycleAnalysis: isCycleAnalysis
        )
        ctx.insert(msg)
        try? ctx.save()
        objectWillChange.send()
        scheduleCloudUpload(for: msg)
    }

    private func scheduleCloudUpload(for message: AICoachMessage) {
        guard Auth.auth().currentUser != nil else { return }
        // Inherit MainActor isolation so we can safely touch the SwiftData
        // object on completion; Firestore's awaitable APIs handle their own
        // off-main threading internally.
        Task { @MainActor in
            do {
                try await FirestoreManager.shared.saveAsync(coachMessage: message)
                message.isSynced = true
                try? self.modelContext?.save()
            } catch {
                #if DEBUG
                print("⚠️ AICoachStore: cloud upload failed (will retry next session): \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func scheduleCloudUpload(for summary: AICoachWeeklySummary) {
        guard Auth.auth().currentUser != nil else { return }
        Task { @MainActor in
            do {
                try await FirestoreManager.shared.saveAsync(coachSummary: summary)
                summary.isSynced = true
                try? self.modelContext?.save()
            } catch {
                #if DEBUG
                print("⚠️ AICoachStore: summary upload failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func fetchMessages(forSignature sig: String, ascending: Bool) -> [AICoachMessage] {
        guard let ctx = modelContext else { return [] }
        let descriptor = FetchDescriptor<AICoachMessage>(
            predicate: #Predicate { $0.workoutSignature == sig },
            sortBy: [SortDescriptor(\.timestamp, order: ascending ? .forward : .reverse)]
        )
        return (try? ctx.fetch(descriptor)) ?? []
    }

    // MARK: - Weekly summary

    private func currentWeeklySummary() -> AICoachWeeklySummary? {
        guard let ctx = modelContext else { return nil }
        var d = FetchDescriptor<AICoachWeeklySummary>(
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)]
        )
        d.fetchLimit = 1
        return (try? ctx.fetch(d).first)
    }

    private func currentWeeklySummaryText() -> String? {
        currentWeeklySummary()?.text
    }

    /// Re-runs the digest if the cached one is stale or missing.
    /// Silent on failure — token economy is an optimisation, not load-bearing.
    private func refreshWeeklySummaryIfNeeded() async {
        guard let ctx = modelContext else { return }

        let now = Date()
        let weekAgo = now.addingTimeInterval(-7 * 24 * 3600)

        // Pull source messages from the past week.
        let descriptor = FetchDescriptor<AICoachMessage>(
            predicate: #Predicate { $0.timestamp >= weekAgo },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let weekMessages = (try? ctx.fetch(descriptor)) ?? []

        // Nothing to summarise → drop any stale summary so we don't re-inject it forever.
        if weekMessages.isEmpty {
            if let cached = currentWeeklySummary() { ctx.delete(cached); try? ctx.save() }
            return
        }

        // Decide whether to refresh.
        let cached = currentWeeklySummary()
        let needsRefresh: Bool = {
            guard let c = cached else { return true }
            if now.timeIntervalSince(c.generatedAt) > Self.summaryStaleAfter { return true }
            if abs(c.sourceMessageCount - weekMessages.count) >= Self.summaryStaleAfterMessages { return true }
            return false
        }()
        guard needsRefresh else { return }

        // Build the transcript we'll ask Groq to compress.
        let transcript = weekMessages.map { m -> String in
            let role = m.isUser ? "User" : "Coach"
            return "\(role): \(m.text)"
        }.joined(separator: "\n")

        let prompt: [GroqMessage] = [
            .init(role: .system, content: """
            Summarise this fitness coach ↔ client conversation from the last 7 days into 70–100 words. \
            Keep it in the same language(s) as the source. Highlight: goals and progress, working weights/loads, \
            pain or injury complaints, recovery and sleep changes, personal preferences. \
            No greetings or closings — pure digest, will be injected as system context.
            """),
            .init(role: .user, content: transcript)
        ]

        do {
            let summary = try await GroqClient.shared.complete(
                messages: prompt,
                temperature: 0.3,
                maxTokens: 220
            )

            // Replace any previous summary
            if let oldSummaries = try? ctx.fetch(FetchDescriptor<AICoachWeeklySummary>()) {
                for s in oldSummaries { ctx.delete(s) }
            }

            let coversFrom = weekMessages.first?.timestamp ?? weekAgo
            let coversTo = weekMessages.last?.timestamp ?? now
            let newSummary = AICoachWeeklySummary(
                coversFrom: coversFrom,
                coversTo: coversTo,
                text: summary.trimmingCharacters(in: .whitespacesAndNewlines),
                sourceMessageCount: weekMessages.count
            )
            ctx.insert(newSummary)
            try? ctx.save()
            scheduleCloudUpload(for: newSummary)
        } catch {
            // Silently ignore — we'll just send the next prompt without a digest.
        }
    }

    // MARK: - Counter persistence

    private struct Counters: Codable {
        var lastWorkoutSignature: String?
        var followUpQuestionsUsed: Int
        var lastQuestionAt: Date?
    }

    private func loadCountersFromDisk() {
        guard let data = defaults.data(forKey: Self.kCounters) else { return }
        guard let c = try? JSONDecoder().decode(Counters.self, from: data) else { return }
        self.lastWorkoutSignature = c.lastWorkoutSignature
        self.followUpQuestionsUsed = c.followUpQuestionsUsed
        self.lastQuestionAt = c.lastQuestionAt
    }

    private func persistCounters() {
        let c = Counters(
            lastWorkoutSignature: lastWorkoutSignature,
            followUpQuestionsUsed: followUpQuestionsUsed,
            lastQuestionAt: lastQuestionAt
        )
        if let data = try? JSONEncoder().encode(c) {
            defaults.set(data, forKey: Self.kCounters)
        }
    }

    // MARK: - Cycle signature

    private func signature(for session: WorkoutSession) -> String {
        return "\(session.date.timeIntervalSince1970)|\(session.workoutDayName)"
    }

    // MARK: - System prompt + first-message template (language-aware)

    /// Resolves the user-facing language for the very first reply. We map
    /// the app's current locale to a small list of languages we actively
    /// support; everything else falls back to English.
    private static func appLanguageName() -> String {
        let id = LanguageManager.shared.currentLocale.identifier.lowercased()
        if id.hasPrefix("ru") { return "Russian" }
        if id.hasPrefix("uk") { return "Ukrainian" }
        if id.hasPrefix("es") { return "Spanish" }
        if id.hasPrefix("de") { return "German" }
        if id.hasPrefix("fr") { return "French" }
        if id.hasPrefix("pt") { return "Portuguese" }
        if id.hasPrefix("zh") { return "Chinese" }
        return "English"
    }

    private static func systemPrompt() -> String {
        let initialLang = appLanguageName()
        return """
        You are a personal fitness coach with 20 years of experience working with both casual lifters and athletes. \
        Your strengths: physique building, strength training, progressive overload, recovery, and protecting joints \
        and the cardiovascular system.

        Communication principles:
        • Keep replies tight and to the point. Bullet lists are welcome.
        • Rely ONLY on the data you receive (workouts, comments, sensors, profile). Do not invent numbers.
        • Push for progressive overload (load/reps/volume), but always weigh it against recovery, sleep, resting HR \
          and any pain/discomfort comments.
        • If a comment mentions pain, injury, or illness — DO NOT push load. Offer alternative exercises, a regression, \
          or a rest day, and recommend seeing a doctor.
        • Never diagnose or prescribe treatment. You are not a doctor.
        • If data is insufficient for a confident conclusion — say so and ask for clarification.
        • Don't use markdown headings (#, ##) — only short bullets and short paragraphs.

        LANGUAGE RULES (very important):
        • For your VERY FIRST message in this conversation (the post-workout analysis), reply in **\(initialLang)**.
        • From then on, ALWAYS mirror the language the user writes in. If the user switches language mid-conversation, \
          switch with them on the next reply.
        • Localise units, dates and number formatting to that language naturally.
        """
    }

    private static func weeklyDigestSystemPrefix() -> String {
        // English so the model can understand it regardless of user language.
        // The digest text itself is in whichever language(s) the source chat was in.
        return "Digest of the user's last 7 days of conversation with you (use as context but don't quote directly):"
    }

    private static func firstUserPrompt(contextBlock: String) -> String {
        let lang = appLanguageName()
        return """
        Analyse my just-finished workout using the last 4 sessions and sensor data below. \
        Reply in \(lang). Structure:
        1) Quick verdict (1–2 sentences).
        2) What worked well.
        3) What to improve (form, volume, tempo, recovery).
        4) Plan for the next session with concrete numbers (weight/reps/sets) — gentle progressive overload \
           if no health complaints.
        If any comment mentions pain, discomfort or illness — flag it explicitly and suggest alternatives or rest.
        Be specific, no fluff. Maximum 220 words.

        DATA:
        \(contextBlock)
        """
    }
}
