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
//  Two cycle types live side-by-side:
//  • **pre**  — the AI brief generated *before* a workout starts. Has its own
//    signature (`lastBriefSignature`) and follow-up budget (5 Qs, 60 s cooldown).
//  • **post** — the analysis generated *after* the workout finishes. Same as
//    before, just with more headroom (12 Qs, 60 s cooldown).
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

// MARK: - Chat mode

enum AICoachChatMode: String {
    case pre   // before the workout starts (brief screen)
    case post  // after the workout finishes (analysis screen)
}

// MARK: - Store

@MainActor
final class AICoachStore: ObservableObject {

    static let shared = AICoachStore()

    // Tunables
    static let maxPreQuestions  = 5
    static let maxPostQuestions = 12
    static let questionCooldown: TimeInterval = 60
    /// Regenerate the weekly digest if it's older than this.
    static let summaryStaleAfter: TimeInterval = 24 * 3600
    /// Or if this many new messages have appeared since the cached digest.
    static let summaryStaleAfterMessages = 5

    // MARK: Public observable state

    @Published private(set) var isAnalyzing = false   // post-workout analysis
    @Published private(set) var isBriefing = false    // pre-workout brief generation
    @Published private(set) var isReplying = false
    @Published private(set) var followUpQuestionsUsedPre: Int = 0
    @Published private(set) var followUpQuestionsUsedPost: Int = 0
    @Published private(set) var lastError: String?
    @Published private(set) var lastWorkoutSignature: String?
    @Published private(set) var lastBriefSignature: String?
    @Published private(set) var lastQuestionAt: Date?
    /// Drives the cooldown countdown UI. Updated by a 1 Hz timer.
    @Published private(set) var nowTick: Date = Date()

    // MARK: Private

    private weak var modelContext: ModelContext?
    private var tickTimer: Timer?
    private var didPullCloudThisSession = false

    private let defaults = UserDefaults.standard
    private static let kCounters = "AICoachStore.counters.v3"
    /// Old counter keys we migrate from on first launch after the v3 refactor.
    private static let kCountersLegacyV2 = "AICoachStore.counters.v2"

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

    func canAskQuestion(mode: AICoachChatMode) -> Bool {
        guard !isAnalyzing && !isBriefing && !isReplying else { return false }
        guard cooldownRemaining <= 0 else { return false }
        guard hasInsight(for: mode) else { return false }
        return questionsRemaining(mode: mode) > 0
    }

    func questionsRemaining(mode: AICoachChatMode) -> Int {
        switch mode {
        case .pre:  return max(0, Self.maxPreQuestions - followUpQuestionsUsedPre)
        case .post: return max(0, Self.maxPostQuestions - followUpQuestionsUsedPost)
        }
    }

    func maxQuestions(mode: AICoachChatMode) -> Int {
        mode == .pre ? Self.maxPreQuestions : Self.maxPostQuestions
    }

    /// True iff we've recorded at least one assistant message for the active
    /// cycle of the given mode.
    func hasInsight(for mode: AICoachChatMode) -> Bool {
        guard let ctx = modelContext else { return false }
        guard let sig = (mode == .pre) ? lastBriefSignature : lastWorkoutSignature else { return false }
        var d = FetchDescriptor<AICoachMessage>(
            predicate: #Predicate { $0.workoutSignature == sig && $0.kind == "assistant" }
        )
        d.fetchLimit = 1
        return ((try? ctx.fetch(d).first) != nil)
    }

    // MARK: - Public actions

    /// Synchronously establish the pre-brief cycle for today's workout.
    ///
    /// Critical: this must run *before* `PreWorkoutBriefView` is mounted,
    /// because the view's @Query is filtered by `lastBriefSignature` at init
    /// time. If we relied on `generatePreWorkoutBrief` to set the signature
    /// (its first sync line), the view would still init *before* the async
    /// task body runs — capturing a stale signature and never showing the
    /// brief that gets inserted under the new one.
    ///
    /// Returns the signature so callers can pass it to a sibling Task without
    /// re-deriving it. Idempotent: if today's brief already exists we return
    /// the existing signature and DON'T reset the follow-up budget.
    @discardableResult
    func prepareBriefSignature(plannedDay: WorkoutDay, program: Program?) -> String {
        let signature = preBriefSignature(programName: program?.name, dayName: plannedDay.name)
        // Same day, same workout, already briefed — keep the cycle as-is so
        // we don't refund follow-ups they've already used.
        if signature == lastBriefSignature, hasInsight(for: .pre) {
            return signature
        }
        followUpQuestionsUsedPre = 0
        lastBriefSignature = signature
        lastError = nil
        persistCounters()
        return signature
    }

    /// Generate a pre-workout brief: short forecast for today's session based on
    /// the last 4 sessions, sensors and any saved goals/injuries. Idempotent
    /// per day — calling it twice the same day for the same workout day reuses
    /// the existing brief instead of burning tokens.
    ///
    /// Caller is expected to have already invoked `prepareBriefSignature(...)`
    /// synchronously before mounting the brief view. This function tolerates
    /// the case where it wasn't (idempotent), but the view will then race with
    /// the signature update and may show empty until next mount.
    func generatePreWorkoutBrief(plannedDay: WorkoutDay,
                                 program: Program?,
                                 modelContext: ModelContext,
                                 healthManager: HealthManager) async {

        attach(modelContext)

        let signature = prepareBriefSignature(plannedDay: plannedDay, program: program)

        // Already briefed today — don't burn tokens.
        if hasInsight(for: .pre), signature == lastBriefSignature {
            return
        }

        isBriefing = true

        // Bump profile timestamp so other features (e.g. push) know we showed a brief.
        if let profile = loadOrCreateProfile() {
            profile.lastPreBriefAt = Date()
            profile.updatedAt = Date()
            try? modelContext.save()
        }

        let ctx = await AICoachContextBuilder.build(
            modelContext: modelContext,
            healthManager: healthManager,
            limit: 4
        )
        let contextBlock = AICoachContextBuilder.renderForPrompt(ctx)

        // Plan summary: which exercises today, planned sets per exercise.
        let plannedBlock = renderPlannedDay(plannedDay)

        let style = currentCoachStyle()
        let memory = currentMemoryBlock()

        var initialMessages: [GroqMessage] = [
            .init(role: .system, content: Self.systemPrompt(style: style, memoryBlock: memory))
        ]
        if let digest = currentWeeklySummaryText(), !digest.isEmpty {
            initialMessages.append(.init(role: .system, content: Self.weeklyDigestSystemPrefix() + "\n" + digest))
        }
        initialMessages.append(.init(role: .user, content: Self.preWorkoutUserPrompt(
            contextBlock: contextBlock,
            plannedBlock: plannedBlock
        )))

        do {
            let reply = try await GroqClient.shared.complete(
                messages: initialMessages,
                temperature: 0.5,
                maxTokens: 500
            )
            insertAssistantMessage(reply, signature: signature, isCycleAnalysis: true)
            isBriefing = false
            lastError = nil
        } catch {
            isBriefing = false
            lastError = (error as? GroqError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Called from `WorkoutManager.finishWorkout()` after a session is saved.
    func analyzeFinishedWorkout(session: WorkoutSession,
                                modelContext: ModelContext,
                                healthManager: HealthManager) async {

        attach(modelContext)
        let signature = signature(for: session)

        if signature == lastWorkoutSignature, hasInsight(for: .post) {
            return  // already analysed
        }

        // Reset post-cycle
        followUpQuestionsUsedPost = 0
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
        let style = currentCoachStyle()
        let memory = currentMemoryBlock()

        // Compose first prompt — language pinned to current app language.
        var initialMessages: [GroqMessage] = [
            .init(role: .system, content: Self.systemPrompt(style: style, memoryBlock: memory))
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

    /// User's free-form follow-up question. Hard guards depend on mode:
    /// • pre  — 5 Qs, 60 s cooldown
    /// • post — 12 Qs, 60 s cooldown
    /// Rebuilds the conversation from DB so we don't keep a parallel in-memory copy.
    func askFollowUp(_ rawText: String, mode: AICoachChatMode) async {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard canAskQuestion(mode: mode) else { return }
        guard modelContext != nil else { return }

        let sig: String?
        switch mode {
        case .pre:  sig = lastBriefSignature
        case .post: sig = lastWorkoutSignature
        }
        guard let signature = sig else { return }

        switch mode {
        case .pre:  followUpQuestionsUsedPre  += 1
        case .post: followUpQuestionsUsedPost += 1
        }
        lastQuestionAt = Date()
        isReplying = true
        lastError = nil
        persistCounters()

        // Persist the user's question right away — even if Groq fails, we want
        // the chat to show what they typed.
        insertUserMessage(text, signature: signature)

        let style = currentCoachStyle()
        let memory = currentMemoryBlock()

        // Reconstruct the conversation: system + (optional weekly digest) +
        // every message in the current cycle, oldest first.
        var convo: [GroqMessage] = [
            .init(role: .system, content: Self.systemPrompt(style: style, memoryBlock: memory))
        ]
        if let digest = currentWeeklySummaryText(), !digest.isEmpty {
            convo.append(.init(role: .system, content: Self.weeklyDigestSystemPrefix() + "\n" + digest))
        }
        let cycleMsgs = fetchMessages(forSignature: signature, ascending: true)
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
            insertAssistantMessage(reply, signature: signature, isCycleAnalysis: false)
            isReplying = false
        } catch {
            isReplying = false
            lastError = (error as? GroqError)?.errorDescription ?? error.localizedDescription
            // Refund the question on hard failure so users aren't punished for network issues.
            switch mode {
            case .pre:  followUpQuestionsUsedPre  = max(0, followUpQuestionsUsedPre  - 1)
            case .post: followUpQuestionsUsedPost = max(0, followUpQuestionsUsedPost - 1)
            }
            persistCounters()
        }
    }

    /// Manually wipe everything (counters + every persisted message + summaries),
    /// locally **and** in Firestore. Used by Settings → "Очистить историю".
    func wipeAll() async {
        followUpQuestionsUsedPre = 0
        followUpQuestionsUsedPost = 0
        lastQuestionAt = nil
        lastWorkoutSignature = nil
        lastBriefSignature = nil
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

    // MARK: - Profile (long-term memory)

    /// Returns the singleton profile, creating it on first call.
    /// On first creation we honor the coach style picked during onboarding
    /// (stashed in @AppStorage `onboarding.coachStyle`) so the very first
    /// brief / analysis already uses the user's chosen tone.
    @discardableResult
    func loadOrCreateProfile() -> AICoachUserProfile? {
        guard let ctx = modelContext else { return nil }
        // Capture into a local — SwiftData's #Predicate macro can't reference
        // static members directly (compiler error: cannot convert value...).
        let pid = AICoachUserProfile.singletonID
        var d = FetchDescriptor<AICoachUserProfile>(
            predicate: #Predicate { $0.id == pid }
        )
        d.fetchLimit = 1
        if let existing = try? ctx.fetch(d).first {
            return existing
        }
        let onboardingPick = defaults.string(forKey: "onboarding.coachStyle")
            .flatMap(AICoachStyle.init(rawValue:)) ?? .friendly
        let fresh = AICoachUserProfile(coachStyle: onboardingPick)
        ctx.insert(fresh)
        try? ctx.save()
        return fresh
    }

    func updateCoachStyle(_ style: AICoachStyle) {
        guard let p = loadOrCreateProfile() else { return }
        p.coachStyle = style
        try? modelContext?.save()
        objectWillChange.send()
    }

    func updateGoals(_ text: String) {
        guard let p = loadOrCreateProfile() else { return }
        p.goalsNote = text
        p.updatedAt = Date()
        try? modelContext?.save()
        objectWillChange.send()
    }

    func updateInjuries(_ text: String) {
        guard let p = loadOrCreateProfile() else { return }
        p.injuriesNote = text
        p.updatedAt = Date()
        try? modelContext?.save()
        objectWillChange.send()
    }

    private func currentCoachStyle() -> AICoachStyle {
        loadOrCreateProfile()?.coachStyle ?? .friendly
    }

    /// Builds a small "what the coach knows about you" block to inject into the
    /// system prompt. Empty string if the user hasn't filled anything in.
    private func currentMemoryBlock() -> String {
        guard let p = loadOrCreateProfile() else { return "" }
        var lines: [String] = []
        let goals = p.goalsNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let injuries = p.injuriesNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !goals.isEmpty    { lines.append("Goals: \(goals)") }
        if !injuries.isEmpty { lines.append("Injuries / sensitivities: \(injuries)") }
        return lines.joined(separator: "\n")
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
        var lastBriefSignature: String?
        var followUpQuestionsUsedPre: Int
        var followUpQuestionsUsedPost: Int
        var lastQuestionAt: Date?
    }

    /// Legacy v2 layout — read once on first launch after the v3 refactor so
    /// we don't surprise users with a reset budget mid-cycle.
    private struct LegacyCountersV2: Codable {
        var lastWorkoutSignature: String?
        var followUpQuestionsUsed: Int
        var lastQuestionAt: Date?
    }

    private func loadCountersFromDisk() {
        if let data = defaults.data(forKey: Self.kCounters),
           let c = try? JSONDecoder().decode(Counters.self, from: data) {
            self.lastWorkoutSignature      = c.lastWorkoutSignature
            self.lastBriefSignature        = c.lastBriefSignature
            self.followUpQuestionsUsedPre  = c.followUpQuestionsUsedPre
            self.followUpQuestionsUsedPost = c.followUpQuestionsUsedPost
            self.lastQuestionAt            = c.lastQuestionAt
            return
        }
        // One-time migration from v2.
        if let data = defaults.data(forKey: Self.kCountersLegacyV2),
           let c = try? JSONDecoder().decode(LegacyCountersV2.self, from: data) {
            self.lastWorkoutSignature      = c.lastWorkoutSignature
            self.lastBriefSignature        = nil
            self.followUpQuestionsUsedPre  = 0
            self.followUpQuestionsUsedPost = min(c.followUpQuestionsUsed, Self.maxPostQuestions)
            self.lastQuestionAt            = c.lastQuestionAt
            persistCounters()
            defaults.removeObject(forKey: Self.kCountersLegacyV2)
        }
    }

    private func persistCounters() {
        let c = Counters(
            lastWorkoutSignature: lastWorkoutSignature,
            lastBriefSignature: lastBriefSignature,
            followUpQuestionsUsedPre: followUpQuestionsUsedPre,
            followUpQuestionsUsedPost: followUpQuestionsUsedPost,
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

    /// Pre-brief signature: stable per (program, day, calendar-day). Reopening
    /// the app the same day reuses the same brief; tomorrow regenerates.
    private func preBriefSignature(programName: String?, dayName: String) -> String {
        let cal = Calendar.current
        let day = cal.startOfDay(for: Date()).timeIntervalSince1970
        let prog = programName ?? "no_program"
        return "prebrief|\(prog)|\(dayName)|\(day)"
    }

    /// Render the planned exercises for the upcoming session. Compact format
    /// the model can chew through quickly.
    private func renderPlannedDay(_ day: WorkoutDay) -> String {
        let lines = day.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { ex -> String in
                let sets = max(1, ex.plannedSets)
                return "• \(ex.name) — \(sets) sets planned"
            }
        if lines.isEmpty { return "PLAN: (no exercises listed)" }
        return "PLAN — \(day.name):\n" + lines.joined(separator: "\n")
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

    private static func systemPrompt(style: AICoachStyle, memoryBlock: String) -> String {
        let initialLang = appLanguageName()
        let memorySection: String = {
            let trimmed = memoryBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "" }
            return """

            WHAT YOU REMEMBER ABOUT THIS USER (from their profile — keep in mind across all replies):
            \(trimmed)
            """
        }()

        return """
        You are a personal fitness coach with 20 years of experience working with both casual lifters and athletes. \
        Your strengths: physique building, strength training, progressive overload, recovery, and protecting joints \
        and the cardiovascular system.

        TONE: \(style.promptDirective)

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
        \(memorySection)

        LANGUAGE RULES (very important):
        • For your VERY FIRST message in this conversation, reply in **\(initialLang)**.
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

    private static func preWorkoutUserPrompt(contextBlock: String, plannedBlock: String) -> String {
        let lang = appLanguageName()
        return """
        I'm about to start the workout listed below. Build a SHORT pre-workout brief in \(lang). Structure:
        1) Readiness check (1 line, based on sleep/HRV/resting HR if present; otherwise skip).
        2) Today's targets — for the 3 most important exercises, give a concrete weight × reps × sets target \
           that's a small progression vs the last sessions. No invented numbers — base on history. If history is \
           empty, suggest a conservative starting point and label it as such.
        3) One thing to focus on technically today (1 line).
        4) Optional warm-up tip (1 line).
        Keep it under 140 words. No greetings, no farewells, no markdown headings — just bullets and short lines.

        \(plannedBlock)

        HISTORY & SENSORS:
        \(contextBlock)
        """
    }
}
