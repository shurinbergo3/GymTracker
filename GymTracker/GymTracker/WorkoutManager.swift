//
//  WorkoutManager.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import HealthKit

// MARK: - Workout State

enum WorkoutState {
    case idle       // Dashboard - ready to start
    case briefing   // Pre-workout AI brief — shows targets and lets the user ask up to 5 Qs
    case countdown  // 3-2-1 Countdown
    case active     // Workout in progress
    case summary    // Finished, showing results
}

// MARK: - Workout Manager

@MainActor
class WorkoutManager: ObservableObject {
    @Published var selectedDay: WorkoutDay?
    @Published var workoutState: WorkoutState = .idle
    @Published var currentSession: WorkoutSession?
    @Published var activeProgram: Program?
    
    // Live Stats
    @Published var currentHeartRate: Int = 0
    @Published var currentActiveCalories: Int = 0

    // Real-time gamification triggers (driven by ExerciseCard.saveCurrentSet)
    @Published var setCompletionTick: Int = 0
    @Published var prFlashTrigger: Int = 0

    func notifySetCompleted(isPR: Bool) {
        setCompletionTick &+= 1
        if isPR {
            prFlashTrigger &+= 1
        }
    }
    
    // HealthKit workout type selection
    private var selectedActivityType: HKWorkoutActivityType = .functionalStrengthTraining

    /// Подбирает HKWorkoutActivityType исходя из РЕАЛЬНОГО состава упражнений дня:
    /// - все силовые → functionalStrengthTraining
    /// - все кардио → конкретный кардио-тип по имени упражнения / дня (бег, велик, ходьба) либо mixedCardio
    /// - смешанный (силовая + кардио) → mixedCardio (даёт более честную оценку калорий)
    nonisolated static func resolveActivityType(
        for day: WorkoutDay?,
        sessionName: String
    ) -> HKWorkoutActivityType {
        guard let day else { return .functionalStrengthTraining }

        let exerciseTypes = day.exercises.map { $0.resolvedWorkoutType }
        let hasCardio = exerciseTypes.contains(.duration)
        let hasStrength = exerciseTypes.contains { $0 == .strength || $0 == .repsOnly }

        // Смешанный день — пусть HealthKit считает по mixedCardio (учитывает HR-зоны).
        if hasCardio && hasStrength { return .mixedCardio }

        // Чистое кардио — попробуем определить конкретный вид по названиям упражнений.
        if hasCardio {
            let names = day.exercises
                .filter { $0.resolvedWorkoutType == .duration }
                .map { $0.name.lowercased() }
                .joined(separator: " ")
            let combined = (names + " " + sessionName.lowercased())
            if combined.contains("run") || combined.contains("бег") { return .running }
            if combined.contains("walk") || combined.contains("ходьб") { return .walking }
            if combined.contains("bike") || combined.contains("cycl") || combined.contains("велосип") || combined.contains("вело") {
                return .cycling
            }
            if combined.contains("row") || combined.contains("греб") { return .rowing }
            if combined.contains("swim") || combined.contains("плав") { return .swimming }
            if combined.contains("elliptical") || combined.contains("эллипс") { return .elliptical }
            if combined.contains("stair") || combined.contains("степ") { return .stairs }
            if combined.contains("jump") || combined.contains("скакалк") { return .jumpRope }
            return .mixedCardio
        }

        // Чистая силовая.
        return .functionalStrengthTraining
    }
    
    private var liveActivityTimer: Timer?
    private var programObserver: NSObjectProtocol?
    
    @preconcurrency private let modelContext: ModelContext
    
    // Injected Dependencies
    private let healthProvider: HealthProvider
    private let activityProvider: ActivityProvider
    
    // Helper ID for safe async passing via Countdown (prevents invalidation crash)
    private var pendingWorkoutDayID: PersistentIdentifier?
    
    @MainActor
    init(
        modelContext: ModelContext,
        healthProvider: HealthProvider,
        activityProvider: ActivityProvider
    ) {
        let t0 = CFAbsoluteTimeGetCurrent()
        self.modelContext = modelContext
        self.healthProvider = healthProvider
        self.activityProvider = activityProvider

        let tLoad = CFAbsoluteTimeGetCurrent()
        loadActiveProgram()
        #if DEBUG
        print(String(format: "  └─ loadActiveProgram %.0fms", (CFAbsoluteTimeGetCurrent() - tLoad) * 1000))
        #endif

        let tInit = CFAbsoluteTimeGetCurrent()
        initializeSelectedDay()
        #if DEBUG
        print(String(format: "  └─ initializeSelectedDay %.0fms", (CFAbsoluteTimeGetCurrent() - tInit) * 1000))
        #endif

        // Listen for active program changes
        programObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("ActiveProgramChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.refreshActiveProgram()

                // Trigger Cloud Sync for Active Program persistence
                if let profile = try? self.modelContext.fetch(FetchDescriptor<UserProfile>()).last {
                    await SyncManager.shared.syncUserProfile(
                        profile: profile,
                        activeProgram: self.activeProgram,
                        context: self.modelContext
                    )
                }
            }
        }

        let tRestore = CFAbsoluteTimeGetCurrent()
        restoreActiveSession()
        #if DEBUG
        print(String(format: "  └─ restoreActiveSession %.0fms", (CFAbsoluteTimeGetCurrent() - tRestore) * 1000))
        let total = (CFAbsoluteTimeGetCurrent() - t0) * 1000
        print(String(format: "⏱ WorkoutManager.init total %.0fms", total))
        #endif

        // requestHealthAccess() - Removed from init to prevent UI freeze (called in onAppear instead)
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Stop timer to prevent memory leak
        liveActivityTimer?.invalidate()
        liveActivityTimer = nil
        
        // Remove NotificationCenter observer
        if let observer = programObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Clear HealthKit callbacks (nonisolated context)
        Task { @MainActor [weak healthProvider] in
            healthProvider?.onHeartRateUpdate = nil
            healthProvider?.onCalorieUpdate = nil
        }
    }
    
    // MARK: - Initialization
    
    func restoreActiveSession() {
        // Look for incomplete session
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == false },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let session = try? modelContext.fetch(descriptor).first {
            // Check for stale session (older than 24 hours)
            let timeSinceStart = Date().timeIntervalSince(session.date)
            if timeSinceStart > 86400 { // 24 hours in seconds
                #if DEBUG
                print("Found stale session from \(session.date). Deleting.")
                #endif
                modelContext.delete(session)
                try? modelContext.save()
                return 
            }
            
            // Restore state if valid
            currentSession = session
            workoutState = .active
            
            // Try to match selectedDay if possible (active program)
            if let program = activeProgram {
                 selectedDay = program.days.first(where: { $0.name == session.workoutDayName })
            }
            
            // Resume live data fetch
            startActivityUpdates(startDate: session.date)
        }
    }
    
    func loadActiveProgram() {
        let descriptor = FetchDescriptor<Program>(
            predicate: #Predicate { $0.isActive == true }
        )
        activeProgram = try? modelContext.fetch(descriptor).first
    }
    
    // MARK: - Deduplication
    
    /// One-time migration to remove duplicate sessions from history
    /// One-time migration to remove duplicate sessions from history
    func cleanupDuplicateSessions() {
        let migrationKey = "hasPerformedOneTimeDeduplication_v6" // Bumped to v6
        if UserDefaults.standard.bool(forKey: migrationKey) { return }

        // Используем существующий ModelContainer (через modelContext.container),
        // а не создаём новый — два контейнера на одну SQLite-базу могут привести
        // к рассинхронизации кэша SwiftData.
        let container = modelContext.container
        Task.detached(priority: .background) {
            do {
                #if DEBUG
                print("🧹 Starting duplicate cleanup (v6) - Aggressive Mode...")
                #endif
                let context = ModelContext(container)
                context.autosaveEnabled = false

                // Fetch ALL sessions
                let descriptor = FetchDescriptor<WorkoutSession>(
                     sortBy: [SortDescriptor(\.date, order: .reverse)]
                )

                let sessions = try context.fetch(descriptor)

                if sessions.isEmpty {
                     await MainActor.run { UserDefaults.standard.set(true, forKey: migrationKey) }
                     return
                }

                var uniqueKeys = Set<String>()
                var sessionsToDelete: [PersistentIdentifier] = []

                // Keep only ONE session per (Type + Date-Minute)
                // Filter duplicates by checking a "signature"
                for session in sessions {
                    let dateKey = Int(session.date.timeIntervalSince1970 / 60) // Down to minute resolution
                    let key = "\(session.workoutDayName)-\(dateKey)"

                    if uniqueKeys.contains(key) {
                        // Already saw one like this? Delete this one.
                        sessionsToDelete.append(session.persistentModelID)
                    } else {
                        uniqueKeys.insert(key)
                    }
                }

                if !sessionsToDelete.isEmpty {
                    #if DEBUG
                    print("🗑️ Found \(sessionsToDelete.count) duplicates (Aggressive v6). Deleting...")
                    #endif

                    // Batch delete
                    for id in sessionsToDelete {
                        if let model = context.model(for: id) as? WorkoutSession {
                            context.delete(model)
                        }
                    }
                    try context.save()
                    #if DEBUG
                    print("✅ cleanupDuplicateSessions (v6) complete. Removed \(sessionsToDelete.count) sessions.")
                    #endif
                } else {
                    #if DEBUG
                    print("✅ No duplicates found (v6).")
                    #endif
                }

                await MainActor.run {
                     UserDefaults.standard.set(true, forKey: migrationKey)
                }

            } catch {
                #if DEBUG
                print("❌ Cleanup error: \(error)")
                #endif
            }
        }
    }
    
    func refreshActiveProgram() {
        loadActiveProgram()
        initializeSelectedDay()
    }
    
    func initializeSelectedDay() {
        selectedDay = activeProgram?.currentWorkoutDay()
    }
    
    // MARK: - Day Selection
    
    func selectDay(_ day: WorkoutDay) {
        selectedDay = day
    }
    
    /// Automatically selects the next day in the program sequence
    /// Cycles back to first day after the last day
    func selectNextWorkoutDay() {
        guard let program = activeProgram,
              let currentDay = selectedDay else { return }
        
        let sortedDays = program.days.sorted { $0.orderIndex < $1.orderIndex }
        guard !sortedDays.isEmpty else { return }
        
        // Find current day's position
        if let currentIndex = sortedDays.firstIndex(where: { $0.id == currentDay.id }) {
            // Select next day, or cycle to first
            let nextIndex = (currentIndex + 1) % sortedDays.count
            selectedDay = sortedDays[nextIndex]
            #if DEBUG
            print("✅ Auto-selected next day: \(sortedDays[nextIndex].name)")
            #endif
        } else {
            // Fallback: if current day not found, select first day
            selectedDay = sortedDays.first
        }
    }
    
    // MARK: - Workflow Methods
    
    func startWorkout() {
        guard let day = selectedDay else { return }
        // Store ID safely before countdown starts
        self.pendingWorkoutDayID = day.persistentModelID

        // Establish the pre-brief signature SYNCHRONOUSLY before the view is
        // mounted — PreWorkoutBriefView captures this signature at init time
        // for its @Query filter. If we let `generatePreWorkoutBrief` set it
        // asynchronously the view would init with a stale value and never
        // show the incoming assistant message.
        AICoachStore.shared.attach(modelContext)
        _ = AICoachStore.shared.prepareBriefSignature(plannedDay: day, program: activeProgram)

        // Route through the AI brief first; the brief screen calls
        // `proceedToCountdown()` (or `cancelBriefing()`) when the user is ready.
        workoutState = .briefing

        // Kick off the brief generation in parallel with the screen transition.
        // generatePreWorkoutBrief is idempotent per (program, day, calendar-day),
        // so reopening the same brief the same day reuses the cached one.
        let healthMgr = (healthProvider as? HealthManager) ?? HealthManager.shared
        Task { [weak self] in
            guard let self else { return }
            await AICoachStore.shared.generatePreWorkoutBrief(
                plannedDay: day,
                program: self.activeProgram,
                modelContext: self.modelContext,
                healthManager: healthMgr
            )
        }
    }

    /// Called from `PreWorkoutBriefView` when the user taps "Поехали".
    func proceedToCountdown() {
        workoutState = .countdown
    }

    /// User backed out of the brief — go back to dashboard, do nothing else.
    func cancelBriefing() {
        pendingWorkoutDayID = nil
        workoutState = .idle
    }
    
    func beginActiveSession() {
        // Use pending ID if available, otherwise fallback to selectedDay?.id (risky)
        guard let dayID = pendingWorkoutDayID ?? selectedDay?.persistentModelID else { return }
        
        // 1. Refresh object directly from ID to avoid using potentially invalidated 'selectedDay' reference
        guard let freshDay = modelContext.model(for: dayID) as? WorkoutDay else {
            #if DEBUG
            print("❌ Failed to refresh WorkoutDay from context")
            #endif
            workoutState = .idle // Reset state on error
            return
        }
        
        if freshDay.isDeleted {
             #if DEBUG
             print("❌ WorkoutDay was deleted")
             #endif
             workoutState = .idle
             return
        }
        
        // Update selectedDay reference to the fresh one
        self.selectedDay = freshDay
        self.pendingWorkoutDayID = nil // Clear pending ID
        
        // 2. Log exercises count (warning if empty, but continue anyway)
        // Accessing .exercises here should now be safe on freshDay
        if freshDay.exercises.isEmpty {
            #if DEBUG
            print("⚠️ No exercises in this workout day")
            #endif
        } else {
            #if DEBUG
            print("✅ Loaded \(freshDay.exercises.count) exercises")
            #endif
        }
        
        // Guard against duplicate starts (Rapid tapping)
        // Check if we already have a session for this day created in the last 60 seconds
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        let dayName = freshDay.name
        let duplicateDescriptor = FetchDescriptor<WorkoutSession>(
             predicate: #Predicate { $0.workoutDayName == dayName && $0.date > oneMinuteAgo }
        )
        
        if let existingRecent = try? modelContext.fetch(duplicateDescriptor).first {
             #if DEBUG
             print("⚠️ Preventing duplicate session start. Using existing session from \(existingRecent.date)")
             #endif
             currentSession = existingRecent
             workoutState = .active
             // Ensure live activity is running for this existing session
             if activityProvider is LiveActivityManager { // Optional check
                 let startDate = existingRecent.date
                 activityProvider.start(workoutType: existingRecent.workoutDayName, startDate: startDate)
                 startActivityUpdates(startDate: startDate)
             }
             return
        }
        
        // Create new session
        let session = WorkoutSession(
            date: Date(),
            workoutDayName: freshDay.name,
            programName: activeProgram?.name
        )
        modelContext.insert(session)
        currentSession = session
        workoutState = .active
        
        // Start Live Activity
        let startDate = Date()
        activityProvider.start(workoutType: session.workoutDayName, startDate: startDate)
        startActivityUpdates(startDate: startDate)
        
            // Start HealthKit Session with smart type selection
        let shouldSync = UserDefaults.standard.object(forKey: "isHealthSyncEnabled") as? Bool ?? true
        if shouldSync {
            Task {
                // Smart workout type selection — анализируем РЕАЛЬНЫЕ упражнения дня,
                // а не общий тип, чтобы Apple Fitness корректно считал калории
                // (mixedCardio учитывает вариативный пульс, тогда как strength занижает).
                let type = Self.resolveActivityType(
                    for: self.selectedDay,
                    sessionName: session.workoutDayName
                )

                // Save for later use in finishWorkout
                self.selectedActivityType = type

                await self.healthProvider.startWorkout(workoutType: type)
            }
            
            
            // Subscribe to real-time updates
            Task { @MainActor in
                self.healthProvider.onHeartRateUpdate = { [weak self] hr in
                    self?.currentHeartRate = hr
                    Task {
                        await self?.updateLiveActivity(startDate: startDate)
                    }
                }
                
                self.healthProvider.onCalorieUpdate = { [weak self] cals in
                    self?.currentActiveCalories = cals
                    Task {
                        await self?.updateLiveActivity(startDate: startDate)
                    }
                }
            }
        }
    }
    
    func cancelWorkout() {
        Task { @MainActor in
            // Stop Live Activity
            stopActivityUpdates()
            activityProvider.end()
            
            // Discard HealthKit Session
            await healthProvider.discardWorkout()
            
            // Delete current session without saving
            if let session = currentSession {
                modelContext.delete(session)
                try? modelContext.save()
            }
            
            currentSession = nil
            workoutState = .idle
        }
    }
    
    func finishWorkout() async {
        guard let session = currentSession else { return }
        
        // Prevent double-saving (race condition protection)
        // If finishWorkout is called twice (e.g. double tap), the first call sets isCompleted = true synchronously.
        // Subsequent calls will hit this guard and exit before saving duplicates.
        if session.isCompleted { return }
        
        // 1. Stop live updates immediately
        stopActivityUpdates()
        await MainActor.run {
            healthProvider.onHeartRateUpdate = nil
            healthProvider.onCalorieUpdate = nil
        }
        activityProvider.end()
        
        // 2. Set end time and completion status locally
        let endDate = Date()
        session.endTime = endDate
        session.isCompleted = true
        
        // Optimistically set values if we have them
        if currentActiveCalories > 0 { session.calories = currentActiveCalories }
        if currentHeartRate > 0 { session.averageHeartRate = currentHeartRate }
        
        // 3. Complete HealthKit session and fetch accurate data
        // Explicitly pass start and end dates to ensure robust saving even if app was restarted
        await healthProvider.endWorkout(activityType: selectedActivityType, startDate: session.date, endDate: endDate)
        
        if healthProvider.isAuthorized {
            let calories = await healthProvider.fetchCaloriesForWorkout(start: session.date, end: endDate)
            let avgHeartRate = await healthProvider.fetchAverageHeartRate(start: session.date, end: endDate)

            if avgHeartRate > 0 { session.averageHeartRate = Int(avgHeartRate) }

            var profile: WorkoutCaloriesResolver.Profile?
            if let user = try? modelContext.fetch(FetchDescriptor<UserProfile>()).last {
                profile = .init(weightKg: user.currentWeight, age: Double(user.age))
            }

            let finalCalories = WorkoutCaloriesResolver.resolve(
                healthKitCalories: calories,
                heartRate: Double(session.averageHeartRate ?? 0),
                durationMinutes: endDate.timeIntervalSince(session.date) / 60.0,
                activityType: selectedActivityType,
                profile: profile
            )

            if finalCalories > 0 { session.calories = Int(finalCalories) }
        }
        
        // 4. Save data to SwiftData
        do {
            try modelContext.save()
            #if DEBUG
            print("✅ Workout saved successfully. HR: \(session.averageHeartRate ?? 0), Calories: \(session.calories ?? 0)")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ Error saving workout: \(error.localizedDescription)")
            #endif
            // Even on error, we should transition to summary to not block user
        }
        
        // 5. Sync to Firestore; SyncManager retries automatically if offline
        let workout = Workout(from: session)
        Task {
            do {
                try await FirestoreManager.shared.saveAsync(workout: workout)
                // Mark as synced on success
                await MainActor.run {
                    session.isSynced = true
                    try? modelContext.save()
                }
                #if DEBUG
                print("✅ Workout synced to Firestore")
                #endif
            } catch {
                // Failed to sync - leave isSynced = false
                // SyncManager will retry automatically when network available
                #if DEBUG
                print("⚠️ Firestore sync failed (will retry later): \(error.localizedDescription)")
                #endif
            }
        }
        
        // 6. Auto-select next workout day for next session
        selectNextWorkoutDay()

        // 7. AI Coach analysis in background — widget observes AICoachStore.shared
        if let healthMgr = healthProvider as? HealthManager {
            let ctx = modelContext
            let aiSession = session
            Task { @MainActor in
                await AICoachStore.shared.analyzeFinishedWorkout(
                    session: aiSession,
                    modelContext: ctx,
                    healthManager: healthMgr
                )
            }
        }

        // 8. Transition UI to summary
        self.workoutState = .summary
    }
    
    func requestHealthAccess() {
        Task {
            _ = await healthProvider.requestAuthorization()
        }
    }
    
    func closeWorkout() {
        // Final save just in case
        try? modelContext.save()

        // Re-schedule decay warnings off the just-finished session.
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let completed = (try? modelContext.fetch(descriptor)) ?? []
        if let latest = completed.first {
            let peak = GamificationCalculator.peakLevel(totalWorkouts: completed.count)
            InactivityNotificationService.rescheduleDecayWarnings(
                lastWorkoutDate: latest.date,
                peakLevel: peak
            )
        }

        // AI-coach pushes: smart reminder + recovery alert + streak celebration.
        let ctx = modelContext
        let healthMgr = healthProvider as? HealthManager
        Task { @MainActor in
            await AICoachNotificationService.rescheduleSmartReminder(modelContext: ctx)
            if let h = healthMgr {
                await AICoachNotificationService.rescheduleRecoveryAlertIfNeeded(healthManager: h)
            }
            let days = AICoachNotificationService.currentStreakDays(modelContext: ctx)
            await AICoachNotificationService.celebrateStreakIfMilestone(streakDays: days)
        }

        currentSession = nil
        workoutState = .idle
    }
    
    // MARK: - Previous Session
    
    func getPreviousSession(for day: WorkoutDay) -> WorkoutSession? {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let allSessions = (try? modelContext.fetch(descriptor)) ?? []
        
        // Filter for this workout day, completed, and not current session
        return allSessions.first { session in
            session.workoutDayName == day.name &&
            session.isCompleted &&
            session != currentSession
        }
    }
    
    // MARK: - Progress Comparison
    
    // MARK: - Progress Comparison (Delegated to AnalyticsService)
    
    func comparePerformance(
        exercise: ExerciseTemplate,
        currentSession: WorkoutSession,
        previousSession: WorkoutSession?
    ) -> ProgressState {
        return AnalyticsService.comparePerformance(
            exercise: exercise,
            currentSession: currentSession,
            previousSession: previousSession
        )
    }
    
    // MARK: - Get Progress Data (Delegated to AnalyticsService)
    
    func getProgressData(for session: WorkoutSession, comparedTo previousSession: WorkoutSession?) -> [ExerciseProgress] {
        guard let day = selectedDay else { return [] }
        
        return AnalyticsService.getProgressData(
            for: session,
            comparedTo: previousSession,
            workoutDay: day
        )
    }
    
    func getPreviewProgressData() -> [ExerciseProgress] {
        guard let day = selectedDay else { return [] }
        let previousSession = getPreviousSession(for: day)
        
        return AnalyticsService.getPreviewProgressData(
            workoutDay: day,
            previousSession: previousSession
        )
    }
    
    // MARK: - Growth Analysis (Delegated to AnalyticsService)
    
    func calculateGrowthTrend(history: [WorkoutSession]) -> GrowthTrend {
        return AnalyticsService.calculateGrowthTrend(history: history)
    }
    
    // MARK: - Live Activity Updates
    
    private func startActivityUpdates(startDate: Date) {
        liveActivityTimer?.invalidate()
        liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateLiveActivity(startDate: startDate)
            }
        }
    }
    
    private func stopActivityUpdates() {
        liveActivityTimer?.invalidate()
        liveActivityTimer = nil
    }
    
    private func updateLiveActivity(startDate: Date) async {
        // We attempt to fetch data regardless of cached 'isAuthorized' state.
        // HealthManager handles errors gracefully and returns 0 if access is denied/unavailable.
        
        let now = Date()
        async let calories = healthProvider.fetchCaloriesForWorkout(start: startDate, end: now)
        async let heartRate = healthProvider.fetchLatestHeartRate(since: nil)
        
        let (calValue, hrValue) = await (calories, heartRate)
        
        // Live Estimate Fallback.
        //
        // HK alone gives 0 kcal for the entire gym session if the user has
        // no Apple Watch — Apple Fitness in this case uses MET-driven estimates
        // on iPhone, which is what we replicate here via `smartEstimate`.
        //
        // Keep `max(HK, smart)` so a real Watch never gets undercounted.
        var displayCalories = Int(calValue)
        let durationMinutes = now.timeIntervalSince(startDate) / 60.0

        if durationMinutes > 0.5 && displayCalories < Int(durationMinutes * 1.5) {
            let descriptor = FetchDescriptor<UserProfile>()
            if let profile = try? modelContext.fetch(descriptor).last,
               profile.currentWeight > 0 {
                let estimatedTotal = CalorieCalculator.smartEstimate(
                    heartRate: hrValue,
                    weightKg: profile.currentWeight,
                    age: Double(profile.age),
                    durationMinutes: durationMinutes,
                    activityType: selectedActivityType
                )
                if estimatedTotal > Double(displayCalories) {
                    displayCalories = Int(estimatedTotal)
                }
            }
        }

        activityProvider.update(heartRate: Int(hrValue), calories: displayCalories)
        
        // Update local state for UI
        self.currentHeartRate = Int(hrValue)
        self.currentActiveCalories = displayCalories
    }
}
