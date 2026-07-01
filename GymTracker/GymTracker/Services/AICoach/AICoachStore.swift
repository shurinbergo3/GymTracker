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
    static let questionCooldown: TimeInterval = 25
    /// Regenerate the weekly digest if it's older than this.
    static let summaryStaleAfter: TimeInterval = 24 * 3600
    /// Or if this many new messages have appeared since the cached digest.
    static let summaryStaleAfterMessages = 5

    // MARK: Public observable state

    @Published private(set) var isAnalyzing = false   // post-workout analysis
    @Published private(set) var isBriefing = false    // pre-workout brief generation
    @Published private(set) var isReplying = false
    /// True while the batched per-exercise recommendations are being generated.
    @Published private(set) var isGeneratingTips = false
    /// Per-exercise coaching tips for the CURRENT workout day, keyed by the
    /// normalized exercise name. Populated by `generateExerciseTips` at workout
    /// start and surfaced inside each `ExerciseCard` as a collapsible box.
    @Published private(set) var exerciseTips: [String: String] = [:]
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

    /// Brief signature the cached `exerciseTips` belong to. When the planned day
    /// changes we drop the tips so a stale set isn't shown for a different workout.
    private var exerciseTipsSignature: String?

    private let defaults = UserDefaults.standard
    private static let kCounters = "AICoachStore.counters.v3"
    /// Old counter keys we migrate from on first launch after the v3 refactor.
    private static let kCountersLegacyV2 = "AICoachStore.counters.v2"
    /// Cached per-exercise tips (JSON: {signature, tips}). Survives relaunch so
    /// reopening the same workout the same day doesn't burn another AI call.
    private static let kExerciseTips = "AICoachStore.exerciseTips.v1"

    // MARK: Lifecycle

    private init() {
        loadCountersFromDisk()
        loadExerciseTipsFromDisk()
        // Only run the 1 Hz tick if a cooldown is already in progress (e.g.
        // restored from disk). Otherwise it stays idle until a question starts
        // one — see `startTickIfNeeded()`.
        startTickIfNeeded()
    }

    deinit {
        tickTimer?.invalidate()
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
            Task { @MainActor in
                guard let self = self else { return }
                self.nowTick = Date()
                // The cooldown countdown is the tick's only consumer. Once it
                // reaches zero, stop ticking so the store isn't running a 1 Hz
                // timer on the main RunLoop for the entire app lifetime.
                if self.cooldownRemaining <= 0 {
                    self.tickTimer?.invalidate()
                    self.tickTimer = nil
                }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        tickTimer = t
    }

    /// Starts the 1 Hz tick only when there is an active cooldown to count
    /// down, and only if it isn't already running.
    private func startTickIfNeeded() {
        guard cooldownRemaining > 0 else { return }
        if tickTimer == nil { startTick() }
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
            limit: 4,
            lastProgressionNudgeAt: loadOrCreateProfile()?.lastProgressionNudgeAt,
            lastDeloadAt: loadOrCreateProfile()?.lastDeloadAt
        )
        let contextBlock = AICoachContextBuilder.renderForPrompt(ctx)
        let nudgeFired = !ctx.progressionNudges.isEmpty
        let deloadFired = !ctx.deloadSuggestions.isEmpty

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
            if nudgeFired { markProgressionNudgeDelivered() }
            if deloadFired { markDeloadDelivered() }
            isBriefing = false
            lastError = nil
        } catch {
            isBriefing = false
            lastError = (error as? GroqError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Per-exercise recommendations

    /// Normalizes an exercise name for use as a tips dictionary key. Lower-cases,
    /// trims and collapses internal whitespace so "Жим  лёжа " and "жим лёжа"
    /// resolve to the same bucket.
    private static func tipKey(_ name: String) -> String {
        name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Recommendation for a single exercise, if one was generated for the
    /// current workout day. Tolerant to minor naming drift from the model:
    /// tries an exact key match first, then a contains-match both ways.
    func exerciseTip(for name: String) -> String? {
        let key = Self.tipKey(name)
        if let exact = exerciseTips[key] { return exact }
        // Fuzzy fallback — model occasionally rewords the name slightly.
        if let fuzzy = exerciseTips.first(where: { key.contains($0.key) || $0.key.contains(key) }) {
            return fuzzy.value
        }
        return nil
    }

    /// Generates one short, data-driven coaching tip per planned exercise in a
    /// SINGLE batched Groq call. Called from `WorkoutManager.startWorkout()` in
    /// parallel with the pre-workout brief. Idempotent per (program, day,
    /// calendar-day): reopening the same workout the same day reuses the cache.
    func generateExerciseTips(plannedDay: WorkoutDay,
                              program: Program?,
                              modelContext: ModelContext,
                              healthManager: HealthManager) async {

        attach(modelContext)

        let signature = preBriefSignature(programName: program?.name, dayName: plannedDay.name)

        // Already generated for this exact workout day today — don't burn tokens.
        if signature == exerciseTipsSignature, !exerciseTips.isEmpty { return }

        // New workout day → clear any stale tips immediately so cards don't show
        // recommendations meant for a different session while we regenerate.
        if signature != exerciseTipsSignature {
            exerciseTips = [:]
            exerciseTipsSignature = signature
        }

        let plannedExercises = plannedDay.exercises.sorted { $0.orderIndex < $1.orderIndex }
        guard !plannedExercises.isEmpty else { return }

        isGeneratingTips = true

        let ctx = await AICoachContextBuilder.build(
            modelContext: modelContext,
            healthManager: healthManager,
            limit: 6,
            lastProgressionNudgeAt: loadOrCreateProfile()?.lastProgressionNudgeAt,
            lastDeloadAt: loadOrCreateProfile()?.lastDeloadAt
        )

        let names = plannedExercises.map { $0.name }
        let historyBlock = Self.renderExerciseHistory(for: names, ctx: ctx)
        let readinessBlock = Self.renderReadinessForTips(ctx.readiness)
        let memory = currentMemoryBlock()
        let style = currentCoachStyle()

        let messages: [GroqMessage] = [
            .init(role: .system, content: Self.exerciseTipsSystemPrompt(style: style, memoryBlock: memory)),
            .init(role: .user, content: Self.exerciseTipsUserPrompt(names: names, historyBlock: historyBlock, readinessBlock: readinessBlock))
        ]

        do {
            let reply = try await GroqClient.shared.complete(
                messages: messages,
                temperature: 0.5,
                maxTokens: 700
            )
            let parsed = Self.parseExerciseTips(reply, plannedNames: names)
            if !parsed.isEmpty {
                exerciseTips = parsed
                exerciseTipsSignature = signature
                persistExerciseTips()
            }
            isGeneratingTips = false
        } catch {
            isGeneratingTips = false
            // Tips are a nicety — never surface an error banner for them.
            #if DEBUG
            print("⚠️ AICoachStore.generateExerciseTips: \(error.localizedDescription)")
            #endif
        }
    }

    /// Compact per-exercise recent-performance digest fed into the tips prompt.
    /// For each planned exercise we surface the last 1–2 logged sessions as
    /// "weight × reps" so the model can apply real progressive overload.
    private static func renderExerciseHistory(for names: [String],
                                              ctx: AICoachContext) -> String {
        var lines: [String] = []
        for name in names {
            let key = tipKey(name)
            // Walk recent workouts (newest first) collecting this exercise's sets.
            var sessionsRendered = 0
            var perSession: [String] = []
            for w in ctx.workouts {
                guard let ex = w.exercises.first(where: { tipKey($0.name) == key }) else { continue }
                let done = ex.sets.filter { $0.isCompleted }
                guard !done.isEmpty else { continue }
                let setStr = done.map { s -> String in
                    if s.weight > 0 {
                        return "\(String(format: "%g", s.weight))×\(s.reps)"
                    } else {
                        return "\(s.reps)"
                    }
                }.joined(separator: ", ")
                perSession.append(setStr)
                sessionsRendered += 1
                if sessionsRendered >= 2 { break }
            }
            if perSession.isEmpty {
                lines.append("\(name): no history")
            } else {
                lines.append("\(name): " + perSession.enumerated().map { idx, s in
                    idx == 0 ? "last [\(s)]" : "prev [\(s)]"
                }.joined(separator: ", "))
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Exercise-tips persistence

    private struct ExerciseTipsCache: Codable {
        var signature: String
        var tips: [String: String]
    }

    private func loadExerciseTipsFromDisk() {
        guard let data = defaults.data(forKey: Self.kExerciseTips),
              let cache = try? JSONDecoder().decode(ExerciseTipsCache.self, from: data) else { return }
        self.exerciseTipsSignature = cache.signature
        self.exerciseTips = cache.tips
    }

    private func persistExerciseTips() {
        guard let sig = exerciseTipsSignature else { return }
        let cache = ExerciseTipsCache(signature: sig, tips: exerciseTips)
        if let data = try? JSONEncoder().encode(cache) {
            defaults.set(data, forKey: Self.kExerciseTips)
        }
    }

    /// Synchronously establish the post-workout analysis cycle for a finished
    /// session. Must run BEFORE the summary screen mounts so `PostWorkoutAICard`
    /// captures the right signature for its @Query (mirrors `prepareBriefSignature`).
    @discardableResult
    func prepareAnalysisSignature(for session: WorkoutSession) -> String {
        let sig = signature(for: session)
        if sig != lastWorkoutSignature {
            followUpQuestionsUsedPost = 0
            lastQuestionAt = nil
            lastWorkoutSignature = sig
            lastError = nil
            persistCounters()
        }
        return sig
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
            limit: 4,
            lastProgressionNudgeAt: loadOrCreateProfile()?.lastProgressionNudgeAt,
            lastDeloadAt: loadOrCreateProfile()?.lastDeloadAt
        )
        let contextBlock = AICoachContextBuilder.renderForPrompt(ctx)
        let nudgeFired = !ctx.progressionNudges.isEmpty
        let deloadFired = !ctx.deloadSuggestions.isEmpty

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
            if nudgeFired { markProgressionNudgeDelivered() }
            if deloadFired { markDeloadDelivered() }
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
        startTickIfNeeded() // begin counting down the freshly-started cooldown
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
        exerciseTips = [:]
        exerciseTipsSignature = nil
        defaults.removeObject(forKey: Self.kExerciseTips)
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

    /// Called after a brief / analysis successfully lands and the prompt
    /// included a PROGRESSION NUDGE block. Resets the 2–3 week clock so the
    /// next nudge fires only after another fortnight of training.
    private func markProgressionNudgeDelivered() {
        guard let p = loadOrCreateProfile() else { return }
        p.lastProgressionNudgeAt = Date()
        p.updatedAt = Date()
        try? modelContext?.save()
    }

    /// Called after a brief / analysis lands carrying a DELOAD SIGNAL. Starts a
    /// ~3-week cooldown so we suggest a deload once per block, not every session.
    private func markDeloadDelivered() {
        guard let p = loadOrCreateProfile() else { return }
        p.lastDeloadAt = Date()
        p.updatedAt = Date()
        try? modelContext?.save()
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
        // Language is part of the signature so switching the app language
        // invalidates cached briefs/tips and regenerates them in the new one.
        let lang = LanguageManager.shared.currentLanguageCode
        return "prebrief|\(prog)|\(dayName)|\(day)|\(lang)"
    }

    /// Render the planned exercises for the upcoming session. Compact format
    /// the model can chew through quickly.
    private func renderPlannedDay(_ day: WorkoutDay) -> String {
        let lines = day.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { ex -> String in
                let sets = max(1, ex.plannedSets)
                return "• \(ex.name.localized()) — \(sets) sets planned"
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
        if id.hasPrefix("pl") { return "Polish" }
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
        You are an elite personal strength & conditioning coach with 20 years of experience taking ordinary people \
        from beginner to genuinely strong, healthy and confident. You coach THIS user one-on-one inside the Body Forge app.

        YOUR TWO NORTH STARS, in priority order:
        1) HEALTH FIRST. Long-term joint, heart, hormonal and mental health always outrank a short-term PR. \
           A user who trains consistently for years beats one who chases ego lifts and burns out or gets hurt. \
           When recovery, sleep, HRV, resting HR or a pain note say "back off" — you back off, every time.
        2) PROGRESSIVE OVERLOAD THAT SHOWS. Your core job is to make the user visibly and measurably stronger and \
           fitter over weeks and months. Whenever recovery allows, move at least one lever forward — load, reps, sets, \
           tempo, range of motion or density. Real, visible results are what keep a person training; earn them honestly.

        HOW YOU COACH (the load-decision hierarchy — apply in this exact order):
        1) READINESS GATE FIRST. The data block opens with a READINESS verdict (GREEN/AMBER/RED) and a load directive. \
           It is computed from real recovery signals and is AUTHORITATIVE. On AMBER hold load; on RED reduce it. You may \
           NEVER prescribe a load/rep increase that contradicts the READINESS directive — not in the brief, not per-exercise.
        2) RECOVERY & PAIN. Beyond the gate, weigh pain/illness notes and weekly load. Pain → regress or swap, never push.
        3) DOUBLE PROGRESSION (only when the gate is GREEN). Progress one lever at a time and in order: first add reps \
           until the top of the exercise's rep range, THEN add load and reset to the bottom of the range. Don't jump weight \
           while reps are still mid-range.
        4) PLANNED DELOAD / PERIODIZATION. You cannot add load every session forever. Accumulate for ~2–3 weeks, then step \
           progression up deliberately — and after a long unbroken climb, take ONE lighter session to consolidate. If the \
           data block contains a DELOAD SIGNAL, honor it; frame the back-off as smart periodization, not a setback.

        ALSO:
        • Be the coach who NOTICES. Anchor every piece of advice to this user's real numbers and trend, never generic \
          theory. "You added 5 kg on bench in 3 weeks — keep the momentum" lands; "bench is good for the chest" does not.
        • Build motivation from truth, not flattery. Surface a concrete win from the data, then hand over the next \
          concrete step. Earned progress is the motivation — no empty hype, no compliments the numbers don't support.
        • Think in trajectories, not single sessions. Use the multi-week history to judge momentum, plateaus and regression.

        TONE: \(style.promptDirective)

        Operating rules:
        • Keep replies tight and to the point.
        • Rely ONLY on the data you receive (workouts, comments, sensors, profile, ACTIVE PROGRAM). Do not invent numbers.
        • Push for progressive overload (load/reps/volume), but ONLY through the load-decision hierarchy above — the \
          READINESS gate wins over the urge to progress, every time.
        • If a comment mentions pain, injury, or illness — DO NOT push load. Offer alternative exercises, a regression, \
          or a rest day, and recommend seeing a doctor.
        • Never diagnose or prescribe treatment. You are not a doctor.
        • If data is insufficient for a confident conclusion — say so and ask for clarification.
        • PROGRAM AWARENESS: an ACTIVE PROGRAM block, if present, is the user's CURRENT plan — know it as background \
          context (its split, the day they're on, exercise selection). Don't lecture about it unprompted. \
          Only mention it when it's clearly relevant: e.g. the user asks for advice on the plan, or you see a real \
          issue worth flagging (gap like "no vertical pull", a plateau the program doesn't address). \
          When you do mention it, propose a CONCRETE swap, not generic advice.
        • PROGRESSION NUDGE: this section appears ONLY on a recovered (GREEN) day. When present, you MUST weave it in — \
          pick 1–2 of the listed exercises and motivate the user with the EXACT suggestion shown \
          (+2.5 kg / +5 kg / +1 rep / +1 set), respecting double progression (fill reps to the range top, THEN add load). \
          Tie it to their recent numbers from "LAST 6 WEEKS — TOP LIFTS" so it feels personal. Do NOT invent your own \
          number — quote the suggestion verbatim. If there is NO such section, do not manufacture a load increase.
        • 6-WEEK MEMORY: when the data block contains "LAST 6 WEEKS — TOP LIFTS", treat that as your long-term \
          memory of the user's training. Reference it when you talk about momentum, regression, progression or a deload — \
          but in plain language, not as a literal table dump.
        • PLAIN TEXT ONLY. Absolutely no markdown: no `*`, no `-`, no `#`, no `**bold**`, no backticks. \
          For lists, start each item on a new line with a short label and a colon (e.g. "Lat pulldown: 82.5 × 10/9/8"). \
          Never prefix lines with `*` or `-` — those characters render literally and look broken.
        \(memorySection)

        LANGUAGE RULES (very important):
        • For your VERY FIRST message in this conversation, reply in **\(initialLang)**.
        • Write your ENTIRE reply in ONE single language. NEVER mix languages inside one reply — \
          not even section labels. Every word, including headings, must be in the SAME language as the rest.
        • From then on, ALWAYS mirror the language the user writes in. If the user switches language mid-conversation, \
          switch with them on the next reply.
        • Localise units, dates and number formatting to that language naturally.
        """
    }

    // MARK: Exercise-tips prompts + parser

    private static let tipDelimiter = "=>|"

    private static func exerciseTipsSystemPrompt(style: AICoachStyle, memoryBlock: String) -> String {
        let lang = appLanguageName()
        let memorySection: String = {
            let trimmed = memoryBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "" }
            return "\n\nWHAT YOU KNOW ABOUT THIS USER (honor across every tip):\n\(trimmed)"
        }()
        return """
        You are an elite strength & conditioning coach writing a one-line, actionable cue for each exercise \
        the user is about to perform TODAY. Reply in \(lang).

        TONE: \(style.promptDirective)

        TODAY'S READINESS IS AUTHORITATIVE. The user prompt opens with a READINESS verdict and load directive computed \
        from real recovery data. It OVERRIDES the urge to progress and every tip must obey it:
        • GREEN → you MAY apply gentle double progression (fill reps to the top of the range, then +2.5/+5 kg). Hold if unsure.
        • AMBER → HOLD at last session's working weight. Do NOT add weight or reps. Cue effort 1–2 reps shy of failure + technique.
        • RED → REDUCE ~10–15% vs last session. No increases of any kind.
        Never write a per-exercise tip that contradicts the readiness directive — the pre-workout brief obeys the same rule, \
        so the two must agree.
        WHENEVER you hold or reduce load (AMBER/RED), state the REASON in a few words, taken from the readiness signals \
        (e.g. "hold the weight — sleep 5.2 h" / "−2.5 kg, poor sleep"). A held/reduced cue must never look arbitrary. \
        Vary the wording across exercises so it doesn't read like a copy-paste; it's fine to give the reason in full on the \
        first 1–2 cues and keep the rest shorter.

        For every exercise produce ONE tip (max 2 short sentences, ≤ 200 characters) that combines, in priority order:
        • A concrete target for today derived from the history given, scaled to the readiness directive above — with a \
          brief reason when you hold or reduce (see above).
        • ONE specific technique or focus cue for that movement (e.g. "scapula retracted", "control the eccentric 2 s", \
          "drive through mid-foot").
        • A safety caution ONLY if the user's injuries/notes make it relevant.

        HARD RULES:
        • Use ONLY the numbers in the history block. If an exercise has "no history", give a sensible conservative \
          starting cue and say it's a starting point — never invent past numbers.
        • Be specific and personal, not generic platitudes. No greetings, no exercise theory lectures.
        • PLAIN TEXT. No markdown, no bullet characters, no emoji.\(memorySection)
        """
    }

    private static func exerciseTipsUserPrompt(names: [String], historyBlock: String, readinessBlock: String) -> String {
        let lang = appLanguageName()
        let list = names.map { "• \($0)" }.joined(separator: "\n")
        return """
        Write today's coaching tip for each of these exercises. Reply in \(lang).

        \(readinessBlock)

        OUTPUT FORMAT — this is critical for parsing:
        • Output EXACTLY one line per exercise, nothing else (no intro, no summary).
        • Each line must be: <exercise name copied verbatim from the list>\(tipDelimiter)<your tip>
        • Keep the exercise name on the left EXACTLY as written in the list.

        EXERCISES:
        \(list)

        RECENT HISTORY (weight×reps; "last" = most recent session):
        \(historyBlock)
        """
    }

    /// Compact readiness header for the tips prompt — same verdict the brief
    /// and full context see, so per-exercise cues can't contradict the brief.
    private static func renderReadinessForTips(_ r: AICoachContext.ReadinessAssessment) -> String {
        var line = "TODAY'S READINESS [\(r.level.rawValue.uppercased())]: \(r.summary). \(r.loadDirective)"
        if !r.drivers.isEmpty {
            line += "\n  signals: " + r.drivers.joined(separator: "; ")
        }
        return line
    }

    /// Parses the delimited tips reply into a normalized [key: tip] map, matching
    /// each returned line back to a planned exercise name.
    private static func parseExerciseTips(_ reply: String, plannedNames: [String]) -> [String: String] {
        var result: [String: String] = [:]
        let plannedKeys = plannedNames.map { tipKey($0) }

        for rawLine in reply.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let range = line.range(of: tipDelimiter) else { continue }
            let namePart = String(line[..<range.lowerBound])
            var tipPart = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            // Strip stray leading markdown the model might emit despite instructions.
            tipPart = tipPart.trimmingCharacters(in: CharacterSet(charactersIn: "-*• "))
            guard !tipPart.isEmpty else { continue }

            let nameKey = tipKey(namePart)
            // Map to a planned key: exact, else fuzzy contains.
            if let match = plannedKeys.first(where: { $0 == nameKey })
                ?? plannedKeys.first(where: { $0.contains(nameKey) || nameKey.contains($0) }) {
                result[match] = tipPart
            }
        }
        return result
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
        Reply in \(lang). Use EXACTLY this structure, with these section labels (translate them to \(lang)):
        1) Verdict — 1–2 sentences. Lead with one genuine, data-backed win (a PR, an added kg/rep, a streak, \
           a trend vs the last 6 weeks) so the user feels their progress — then state the honest bottom line.
        2) What worked well.
        3) What to improve (form, volume, tempo, recovery).
        4) Plan for the NEXT workout (not "today", not "tomorrow" — explicitly the next training session) \
           with concrete numbers (weight × reps/reps/reps for each exercise). Apply double progression: add reps toward \
           the top of the rep range first, then add load. If there are no health complaints, move ONE lever forward so the \
           user keeps progressing; if a DELOAD SIGNAL is present or recovery/complaints say so, plan a lighter consolidation \
           session instead — and tell them why (smart periodization, not a setback).
        If any comment mentions pain, discomfort or illness — flag it explicitly and suggest alternatives or rest.
        Treat the ACTIVE PROGRAM block (if present) as background context — use it for naming exercises and the next \
        day, but do NOT add a dedicated "program review" section unless you see a clear, concrete issue worth flagging.

        FORMATTING (strict):
        • Plain text only. No markdown. No `*`, no `-`, no `#`, no `**bold**`.
        • Start each numbered section on its OWN new line, beginning with the digit and ")" \
          (e.g. a line break before "2)", "3)", "4)"). This is required so the app can render each section as a card.
        • Inside section 4, put each exercise on its own line as: "<Exercise name>: <weight> × <reps>/<reps>/<reps>". \
          Do NOT prefix lines with `*` or `-`.
        • Be specific, no fluff. Maximum 220 words.

        DATA:
        \(contextBlock)
        """
    }

    private static func preWorkoutUserPrompt(contextBlock: String, plannedBlock: String) -> String {
        let lang = appLanguageName()
        return """
        I'm about to start the workout listed below. Build a SHORT, PROACTIVE pre-workout brief in \(lang). \
        Be hyper-personalized: don't just describe state — prescribe a concrete adjustment.

        Structure:
        1) Readiness verdict — 1 line. The DATA block opens with a READINESS verdict (GREEN/AMBER/RED) and its driving \
           signal — restate it for the user in plain language, naming the signal (e.g. "sleep 5.2 h vs your 7.1 h norm"). \
           Do NOT compute your own verdict and do NOT invent an HRV/resting-HR comparison; trust the READINESS block.
        2) Intensity adjustment — 1 line, ALWAYS present, and it MUST match the READINESS load directive: \
           RED → reduce ~10–15%; AMBER → hold at last session's weights, no increases; GREEN → hold, or push only if a \
           PROGRESSION NUDGE is present. Examples: "Cutting intensity 15% — sleep 5.2 h, protecting the CNS", \
           "Holding last session's weights — recovery incomplete", "Recovery is on track — you can add load as planned".
        3) Targets for the 3 most important exercises — consistent with step 2. \
           Format each on its own line as: "<Exercise name>: <weight> × <reps> × <sets>". \
           No invented numbers — base on history. If history is empty, suggest a conservative starting point and label it as such.
        4) One technique focus for today (1 line).
        5) Optional warm-up tip (1 line).

        FORMATTING (strict):
        • Plain text only. No markdown. No `*`, no `-`, no `#`, no `**bold**`. \
          Do NOT prefix lines with `*` or `-`.
        • No greetings, no farewells. Keep it under 160 words.

        \(plannedBlock)

        HISTORY & SENSORS:
        \(contextBlock)
        """
    }
}
