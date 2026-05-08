//  WorkoutTrackerApp.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import UIKit

// MARK: - AppDelegate

/// Минимальный AppDelegate. Нужен чтобы убрать предупреждение
/// `[GoogleUtilities/AppDelegateSwizzler] App Delegate does not conform to UIApplicationDelegate protocol`
/// и дать Firebase правильную точку инициализации (важно для Auth listener'ов и URL handling).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // FirebaseApp уже сконфигурирован в WorkoutTrackerApp.init() — не дублируем,
        // иначе будет лог "Default app has already been configured".
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return true
    }
}

/// Гарантированно конфигурим Firebase ДО того, как любой код в App обратится к Auth/Firestore.
/// Static let вычисляется один раз при первом обращении — мы дёргаем его в init() ПЕРВОЙ строкой,
/// до того как @StateObject AuthManager.shared триггерит Auth.auth().
private let _firebaseBootstrap: Void = {
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
}()

@main
struct WorkoutTrackerApp: App {

    // Подключаем AppDelegate к SwiftUI App — без этого Firebase swizzler ругается.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // ВАЖНО: эти @StateObject объявлены БЕЗ default-значения, чтобы их инициализация
    // случилась внутри init() — после FirebaseApp.configure(). Иначе AuthManager.shared
    // дёрнет Auth.auth() ДО конфигурации Firebase и приложение виснет.
    @StateObject private var authManager: AuthManager
    @StateObject private var languageManager: LanguageManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var isCheckingAuth = true
    @State private var isRestoringData = false
    @State private var dbError: Error? = nil
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    init() {
        let t0 = CFAbsoluteTimeGetCurrent()
        // 1) Сначала Firebase — обращение к static let форсит configure() до всего остального.
        _ = _firebaseBootstrap
        // 2) Только теперь поднимаем менеджеры, которые используют Firebase.
        _authManager = StateObject(wrappedValue: AuthManager.shared)
        _languageManager = StateObject(wrappedValue: LanguageManager.shared)
        #if DEBUG
        let dt = (CFAbsoluteTimeGetCurrent() - t0) * 1000
        print(String(format: "⏱ App.init() took %.1fms", dt))
        #endif
    }
    
    var sharedModelContainer: ModelContainer = {
        let t0 = CFAbsoluteTimeGetCurrent()
        let schema = Schema([
            UserProfile.self,
            WorkoutSession.self,
            WorkoutSet.self,
            BodyMeasurement.self,
            WeightRecord.self,
            Program.self,
            WorkoutDay.self,
            ExerciseTemplate.self,
            AICoachMessage.self,
            AICoachWeeklySummary.self,
            AICoachUserProfile.self
        ])

        do {
            let container = try ModelContainer(for: schema)
            #if DEBUG
            let dt = (CFAbsoluteTimeGetCurrent() - t0) * 1000
            print(String(format: "✅ ModelContainer initialized in %.0fms", dt))
            #endif
            return container
        } catch {
            #if DEBUG
            print("⚠️ Error: \(error). Attempting DB reset...")
            #endif

            // Reset database on error
            let config = ModelConfiguration(schema: schema)
            try? FileManager.default.removeItem(at: config.url)
            #if DEBUG
            print("🗑️ DB reset")
            #endif

            do {
                let container = try ModelContainer(for: schema)
                #if DEBUG
                print("✅ Fresh DB created")
                #endif
                return container
            } catch {
                // Return a minimal in-memory container so app doesn't crash
                let memConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                return (try? ModelContainer(for: schema, configurations: memConfig))
                    ?? { fatalError("Cannot create even in-memory ModelContainer: \(error)") }()
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Главный контент — ВСЕГДА присутствует, чтобы splash не блокировал переход.
                Group {
                    if !hasSeenOnboarding {
                        // Онбординг показываем ДО проверки авторизации, иначе после
                        // переустановки приложения Firebase автоматически восстанавливает
                        // сессию из Keychain (Keychain переживает удаление приложения),
                        // и пользователь ни разу не увидит обучение.
                        OnboardingView(hasSeenOnboarding: Binding(
                            get: { hasSeenOnboarding },
                            set: { hasSeenOnboarding = $0 }
                        ))
                    } else if authManager.isLoggedIn {
                        if isRestoringData {
                            RestoringDataView(isRestoring: $isRestoringData, onFinish: {
                                isRestoringData = false
                            })
                        } else {
                            ContentViewWrapper()
                                .environmentObject(authManager)
                        }
                    } else {
                        LoginView()
                    }
                }

                // Сплеш — поверх контента, исчезает по таймеру.
                // Мы НЕ ждём auth listener — он отрабатывает в фоне и поменяет isLoggedIn,
                // а контент под сплешем уже готов отрисоваться сразу как сплеш уйдёт.
                if isCheckingAuth {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(.dark)
            .id(languageManager.refreshID)
            .modelContainer(sharedModelContainer)
            .task {
                // Гарантированный таймер на 0.8с — даже если Task будет cancelled
                // (resume из background и пр.), DispatchQueue ниже всё равно сработает.
                try? await Task.sleep(nanoseconds: 800_000_000)
                #if DEBUG
                print("⏱ Splash dismiss via .task")
                #endif
                withAnimation(.easeOut(duration: 0.3)) {
                    isCheckingAuth = false
                }
            }
            .onAppear {
                // Дублирующий путь сброса сплеша — DispatchQueue не зависит от
                // SwiftUI Task lifecycle, гарантированно фаерится через 1.5с.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if isCheckingAuth {
                        #if DEBUG
                        print("⏱ Splash dismiss via DispatchQueue fallback")
                        #endif
                        withAnimation(.easeOut(duration: 0.3)) {
                            isCheckingAuth = false
                        }
                    }
                }
                // Notifications-разрешение запрашиваем СПУСТЯ задержку, чтобы системный
                // алерт не появлялся одновременно со сплешем (это создаёт ощущение зависона).
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    InactivityNotificationService.requestAuthorizationIfNeeded()
                    // After the OS prompt, schedule any AI-coach pushes that history allows.
                    let ctx = sharedModelContainer.mainContext
                    Task { @MainActor in
                        await AICoachNotificationService.rescheduleSmartReminder(modelContext: ctx)
                        await AICoachNotificationService.rescheduleRecoveryAlertIfNeeded(
                            healthManager: HealthManager.shared
                        )
                        await AICoachNotificationService.rescheduleWeeklyWrappedPush()
                    }
                }
            }
            .onChange(of: authManager.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    checkForFreshInstall()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    InactivityNotificationService.rescheduleOnAppOpen()
                    rescheduleDecayWarningsFromLatestSession()
                }
            }
        }
    }
    
    /// Reads the most-recent completed session and re-schedules decay warnings.
    /// Called on app foreground so notifications stay aligned with real workout history.
    private func rescheduleDecayWarningsFromLatestSession() {
        let context = sharedModelContainer.mainContext
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let latest = try? context.fetch(descriptor).first else {
            InactivityNotificationService.rescheduleDecayWarnings(lastWorkoutDate: nil, peakLevel: 1)
            return
        }

        let countDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true }
        )
        let total = (try? context.fetchCount(countDescriptor)) ?? 0
        let peak = GamificationCalculator.peakLevel(totalWorkouts: total)

        InactivityNotificationService.rescheduleDecayWarnings(
            lastWorkoutDate: latest.date,
            peakLevel: peak
        )
    }

    // checkAuthStatus() удалён — splash теперь снимается через `.task` с фиксированным
    // таймером 1.2с. Auth-listener работает параллельно и обновляет isLoggedIn в фоне,
    // что переключает контент под уже снятым сплешем.
    
    /// Check if DB is empty on login to trigger auto-restore
    private func checkForFreshInstall() {
        // Only trigger if we are NOT already checking auth (i.e. this is a user-initiated login)
        // OR if it's auto-login but database is wiped.
        
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<WorkoutSession>()
        
        do {
            let count = try context.fetchCount(descriptor)
            if count == 0 {
                // Database is empty! Assume fresh install or wipe.
                // Trigger Restore Flow
                #if DEBUG
                print("🆕 Fresh install detected. Triggering auto-restore.")
                #endif
                withAnimation {
                    isRestoringData = true
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to check DB count: \(error)")
            #endif
        }
    }
}

// MARK: - Content View Wrapper

struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeeded = false
    @State private var hasRestored = false
    
    var body: some View {
        ContentView()
            .task {
                let container = modelContext.container
                let needsSeed = !hasSeeded
                let needsRestore = !hasRestored
                
                Task.detached(priority: .userInitiated) {
                    if needsSeed {
                        let bgContext = ModelContext(container)
                        ProgramSeeder.seedProgramsIfNeeded(context: bgContext)
                        await ExerciseLibrary.migrateExerciseTypes(container: container)
                        await MainActor.run {
                            hasSeeded = true
                        }
                    }
                    
                    if needsRestore {
                        await restoreUserProfileFromFirestore()
                        await MainActor.run {
                            hasRestored = true
                        }
                    }
                }
            }
    }
    
    // restoreWorkoutsFromFirestore moved to SyncManager
    
    // convertToWorkoutSession moved to SyncManager
    
    /// Restore User Profile & Active Program from Firestore
    private func restoreUserProfileFromFirestore() async {
        guard let profileData = await SyncManager.shared.fetchUserProfile() else { return }
        
        // 1. Update or Create UserProfile
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        let profile: UserProfile
        
        if let existing = profiles.last {
            profile = existing
            // Only update if cloud is newer? Or just overwrite?
            // For now, trust cloud if fetching
            profile.height = profileData.height
            profile.age = profileData.age
            // Weight logic is complex (history), maybe skip or add new record
        } else {
            profile = UserProfile(height: profileData.height, initialWeight: profileData.weight, age: profileData.age)
            modelContext.insert(profile)
        }
        
        // 2. Activate Program
        if let activeName = profileData.activeProgramName {
            // Find program by name
            let progDescriptor = FetchDescriptor<Program>() // Fetch all to be safe
            if let allPrograms = try? modelContext.fetch(progDescriptor) {
                
                var found = false
                for program in allPrograms {
                    if program.name == activeName {
                        program.isActive = true
                        found = true
                        #if DEBUG
                        print("✅ Restored Active Program: \(activeName)")
                        #endif
                    } else {
                        // Deactivate others to ensure single source of truth
                        program.isActive = false
                    }
                }
                
                if !found {
                    #if DEBUG
                    print("⚠️ Active program '\(activeName)' not found locally")
                    #endif
                }
            }
        }
        
        try? modelContext.save()
        
        // Notify app to refresh (WorkoutManager listens to this)
        await MainActor.run {
            NotificationCenter.default.post(name: Notification.Name("ActiveProgramChanged"), object: nil)
        }
    }
}
