import Foundation
import SwiftData
import Network
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Manages automatic Firestore synchronization with offline support
@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    @Published var isSyncing = false
    @Published var hasUnsyncedWorkouts = false
    
    private var monitor: NWPathMonitor?
    private var syncTask: Task<Void, Never>?
    
    private init() {
        startNetworkMonitoring()
    }
    
    /// Start monitoring network connectivity
    private func startNetworkMonitoring() {
        monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor?.pathUpdateHandler = { path in
            if path.status == .satisfied {
                // Network is available
                // Note: Auto-sync will be triggered from WorkoutTrackerApp with proper context
                Task { @MainActor in
                    // Notify that network is available
                    // Actual sync happens in WorkoutTrackerApp.onAppear
                }
            }
        }
        
        monitor?.start(queue: queue)
    }
    
    /// Sync all unsynced workouts to Firestore
    func syncUnsyncedWorkouts(context: ModelContext) async {
        guard !isSyncing else { return }
        guard Auth.auth().currentUser != nil else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Fetch all completed workouts and filter in Swift
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true }
        )
        
        guard let allCompletedSessions = try? context.fetch(descriptor) else {
            #if DEBUG
            print("❌ SyncManager: Failed to fetch workouts")
            #endif
            return
        }
        
        // Filter unsynced in Swift (avoid complex Predicate)
        let unsyncedSessions = allCompletedSessions.filter { session in
            session.isSynced != true
        }
        
        guard !unsyncedSessions.isEmpty else {
            hasUnsyncedWorkouts = false
            return
        }
        
        #if DEBUG
        print("📤 SyncManager: Found \(unsyncedSessions.count) unsynced workouts")
        #endif
        
        hasUnsyncedWorkouts = true
        
        // Sync each workout
        for session in unsyncedSessions {
            do {
                let workout = Workout(from: session)
                
                // Try to save to Firestore
                try await saveToFirestore(workout)
                
                // Mark as synced
                session.isSynced = true
                
                #if DEBUG
                print("✅ SyncManager: Synced workout from \(session.date)")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ SyncManager: Failed to sync workout: \(error.localizedDescription)")
                #endif
                // Don't mark as synced, will retry later
            }
        }
        
        // Save changes
        try? context.save()
        
        // Update unsynced count - filter in Swift again
        let allCompleted = (try? context.fetch(FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true }
        ))) ?? []
        let remaining = allCompleted.filter { $0.isSynced != true }
        hasUnsyncedWorkouts = !remaining.isEmpty
        
        #if DEBUG
        print("✅ SyncManager: Sync complete. Remaining unsynced: \(remaining.count)")
        #endif
    }
    
    /// Save workout directly to Firestore (async version)
    private func saveToFirestore(_ workout: Workout) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "SyncManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let collectionPath = "users/\(userId)/workouts"
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try FirebaseFirestore.Firestore.firestore()
                    .collection(collectionPath)
                    .addDocument(from: workout) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Manual trigger for sync (can be called from UI)
    func triggerManualSync(context: ModelContext) async {
        await syncUnsyncedWorkouts(context: context)
    }
    
    // MARK: - User Profile Sync
    
    struct WeightRecordDTO: Codable {
        let weight: Double
        let date: Date
    }
    
    struct BodyMeasurementDTO: Codable {
        let date: Date
        let type: String // MeasurementType raw value
        let value: Double
    }
    
    struct UserProfileData: Codable {
        let height: Double
        let weight: Double
        let age: Int
        let activeProgramName: String?
        let lastUpdated: Date
        let weightHistory: [WeightRecordDTO]?
        let bodyMeasurements: [BodyMeasurementDTO]?
    }
    
    /// Sync User Profile and Active Program to Firestore
    func syncUserProfile(profile: UserProfile, activeProgram: Program?, context: ModelContext) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Convert weight history to DTOs
        let weightHistoryDTOs = profile.weightHistory.map { record in
            WeightRecordDTO(weight: record.weight, date: record.date)
        }
        
        // Fetch and convert body measurements to DTOs
        let bodyMeasurementsDTOs: [BodyMeasurementDTO]
        do {
            let descriptor = FetchDescriptor<BodyMeasurement>()
            let allMeasurements = try context.fetch(descriptor)
            bodyMeasurementsDTOs = allMeasurements.map { measurement in
                BodyMeasurementDTO(
                    date: measurement.date,
                    type: measurement.type.rawValue,
                    value: measurement.value
                )
            }
        } catch {
            bodyMeasurementsDTOs = []
        }
        
        // Create DTO
        let data = UserProfileData(
            height: profile.height,
            weight: profile.currentWeight,
            age: profile.age,
            activeProgramName: activeProgram?.name,
            lastUpdated: Date(),
            weightHistory: weightHistoryDTOs,
            bodyMeasurements: bodyMeasurementsDTOs
        )
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try Firestore.firestore()
                        .collection("users")
                        .document(userId)
                        .collection("profile")
                        .document("main")
                        .setData(from: data) { error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume()
                            }
                        }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            #if DEBUG
            print("✅ SyncManager: User Profile & Active Program synced")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ SyncManager: Failed to sync profile: \(error)")
            #endif
        }
    }
    
    /// Fetch User Profile from Firestore
    func fetchUserProfile() async -> UserProfileData? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        
        do {
            let document = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("profile")
                .document("main")
                .getDocument()
            
            return try document.data(as: UserProfileData.self)
        } catch {
            #if DEBUG
            print("⚠️ SyncManager: Failed to fetch profile: \(error)")
            #endif
            return nil
        }
    }
    
    /// Restore User Profile from Firestore (Pull)
    nonisolated func restoreUserProfileFromFirestore(container: ModelContainer) async {
        guard let profileData = await fetchUserProfile() else { return }
        
        // Use a background context to avoid blocking the Main Actor
        let context = ModelContext(container)
        context.autosaveEnabled = false
        
        do {
            // Get or create user profile
            let descriptor = FetchDescriptor<UserProfile>()
            let existingProfile = try context.fetch(descriptor).first
            
            let profile: UserProfile
            if let existing = existingProfile {
                profile = existing
            } else {
                profile = UserProfile(
                    height: profileData.height,
                    initialWeight: profileData.weight
                )
                context.insert(profile)
            }
            
            // Update profile data
            profile.height = profileData.height
            profile.age = profileData.age
            profile.updatedAt = profileData.lastUpdated
            
            // Restore weight history
            if let weightHistory = profileData.weightHistory, !weightHistory.isEmpty {
                // Clear existing weight history
                for record in profile.weightHistory {
                    context.delete(record)
                }
                profile.weightHistory.removeAll()
                
                // Add restored weight history
                for weightDTO in weightHistory {
                    let record = WeightRecord(weight: weightDTO.weight, date: weightDTO.date)
                    record.userProfile = profile
                    profile.weightHistory.append(record)
                    context.insert(record)
                }
            }
            
            // Restore body measurements
            if let measurements = profileData.bodyMeasurements, !measurements.isEmpty {
                // Clear existing measurements
                let measurementDescriptor = FetchDescriptor<BodyMeasurement>()
                let existingMeasurements = try context.fetch(measurementDescriptor)
                for measurement in existingMeasurements {
                    context.delete(measurement)
                }
                
                // Add restored measurements
                for measurementDTO in measurements {
                    if let type = MeasurementType(rawValue: measurementDTO.type) {
                        let measurement = BodyMeasurement(
                            date: measurementDTO.date,
                            type: type,
                            value: measurementDTO.value
                        )
                        context.insert(measurement)
                    }
                }
            }
            
            try context.save()
            
            #if DEBUG
            print("✅ SyncManager: User profile restored from Firestore")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ SyncManager: Failed to restore profile: \(error)")
            #endif
        }
    }
    
    // MARK: - Program Sync
    
    /// Sync all local programs to Firestore (Push)
    func syncAllPrograms(context: ModelContext) async {
        guard Auth.auth().currentUser != nil else { return }
        
        do {
            // Fetch local programs
            let descriptor = FetchDescriptor<Program>()
            let programs = try context.fetch(descriptor)
            
            for program in programs {
                let dto = ProgramDTO(from: program)
                try await FirestoreManager.shared.saveProgram(dto)
            }
            
            #if DEBUG
            print("✅ SyncManager: Pushed \(programs.count) programs to cloud")
            #endif
        } catch {
            print("❌ SyncManager: Failed to push programs: \(error)")
        }
    }
    
    /// Restore programs from Firestore (Pull)
    /// This merges cloud programs into local. Use carefully.
    nonisolated func restoreProgramsFromFirestore(container: ModelContainer) async {
        guard Auth.auth().currentUser != nil else { return }
        
        do {
            let cloudPrograms = try await FirestoreManager.shared.fetchPrograms()
            guard !cloudPrograms.isEmpty else { return }
            
            // Create a background context
            let context = ModelContext(container)
            context.autosaveEnabled = false
            
            // Fetch local programs to compare
            let descriptor = FetchDescriptor<Program>()
            let localPrograms = try context.fetch(descriptor)
            
            var restoredCount = 0
            
            for cloudProgram in cloudPrograms {
                // Check if exists by name
                if localPrograms.first(where: { $0.name == cloudProgram.name }) != nil {
                    // Skip existing to avoid overwriting user's local edits blindly
                    continue
                } else {
                    // Create new
                    let newProgram = Program(
                        name: cloudProgram.name,
                        desc: cloudProgram.desc,
                        startDate: cloudProgram.startDate,
                        isActive: cloudProgram.isActive,
                        displayOrder: cloudProgram.displayOrder
                    )
                    
                    // Add days
                    for dayDto in cloudProgram.days {
                        let workoutType = WorkoutType(rawValue: dayDto.workoutType) ?? .strength
                        let day = WorkoutDay(
                            name: dayDto.name,
                            orderIndex: dayDto.orderIndex,
                            workoutType: workoutType,
                            defaultRestTime: dayDto.defaultRestTime,
                            restTimerEnabled: dayDto.restTimerEnabled
                        )
                        day.program = newProgram
                        
                        // Add exercises
                        for exDto in dayDto.exercises {
                            let type = exDto.customWorkoutType != nil ? WorkoutType(rawValue: exDto.customWorkoutType!) : nil
                            let ex = ExerciseTemplate(
                                name: exDto.name,
                                plannedSets: exDto.plannedSets,
                                orderIndex: exDto.orderIndex,
                                type: type
                            )
                            ex.workoutDay = day
                            day.exercises.append(ex)
                        }
                        
                        newProgram.days.append(day)
                    }
                    
                    context.insert(newProgram)
                    restoredCount += 1
                }
            }
            
            if restoredCount > 0 {
                try context.save()
                #if DEBUG
                print("✅ SyncManager: Restored \(restoredCount) programs from cloud")
                #endif
            }
            
        } catch {
            print("❌ SyncManager: Failed to restore programs: \(error)")
        }
    }
    
    // MARK: - Errors
    
    enum SyncError: LocalizedError {
        case message(String)
        case unauthorized
        
        var errorDescription: String? {
            switch self {
            case .message(let msg): return msg
            case .unauthorized: return "Пользователь не авторизован"
            }
        }
    }

    // MARK: - Workout History Restore
    
    /// Restore workout history from Firestore to SwiftData (Pull)
    nonisolated func restoreWorkoutsFromFirestore(container: ModelContainer) async -> Result<Int, Error> {
        // Ensure user is logged in
        guard Auth.auth().currentUser != nil else {
            #if DEBUG
            print("⚠️ Cannot restore workouts: User not logged in")
            #endif
            return .failure(SyncError.unauthorized)
        }
        
        do {
            let firestoreWorkouts = try await FirestoreManager.shared.fetchHistory()
            
            guard !firestoreWorkouts.isEmpty else {
                #if DEBUG
                print("📭 No workouts found in Firestore to restore")
                #endif
                return .success(0) // Return 0 to indicate no workouts in cloud
            }
            
            // Since we're already called from a detached context, run inline
            // Create a context from the SHARED container for background work
            let bgContext = ModelContext(container)
            
            // Disable autosave for performance
            bgContext.autosaveEnabled = false
            
            // Fetch local sessions
            let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date)])
            var localSessions = try bgContext.fetch(descriptor)
            
            #if DEBUG
            print("📥 Found \(firestoreWorkouts.count) workouts in Firestore, \(localSessions.count) local")
            #endif
            
            var restoredCount = 0
            
            // Convert Firestore workouts to SwiftData sessions
            for (index, workout) in firestoreWorkouts.enumerated() {
                // Always check for duplicates (improved logic)
                let exists = localSessions.contains { session in
                    // Must match workout name
                    guard session.workoutDayName == workout.workoutType else { return false }
                    
                    // Must have similar date (within 5 minutes tolerance)
                    let timeDiff = abs(session.date.timeIntervalSince(workout.date))
                    return timeDiff < 300 // 5 minutes
                }
                
                if !exists {
                    let session = self.convertToWorkoutSession(workout)
                    bgContext.insert(session)
                    
                    // Add to local array to check against in next iteration
                    localSessions.append(session)
                    
                    restoredCount += 1
                    
                    // Batch save every 100 items - balanced for memory vs UI locking
                    if restoredCount % 100 == 0 {
                        try bgContext.save()
                        // Yield to allow other tasks
                        await Task.yield()
                    }
                }
                
                // Yield occasionally (every 20 items) to keep other tasks responsive
                if index % 20 == 0 {
                   await Task.yield()
                }
            }
            
            if restoredCount > 0 {
                try bgContext.save()
                
                #if DEBUG
                print("✅ Restored \(restoredCount) workouts from Firestore")
                #endif
            } else {
                #if DEBUG
                print("ℹ️ All workouts already synced")
                #endif
            }
            
            return .success(restoredCount)
        } catch {
            #if DEBUG
            print("❌ Error during restore: \(error)")
            #endif
            return .failure(SyncError.message("Ошибка загрузки: \(error.localizedDescription)"))
        }
    }
    
    /// Convert Firestore Workout to SwiftData WorkoutSession
    /// Made internal/public for access if needed, but mostly internal helper
    nonisolated func convertToWorkoutSession(_ workout: Workout) -> WorkoutSession {
        // ... (this part is unchanged, assuming it's correct in file)
        // I need to be careful with replace_file_content here.
        // It's safer to just implement the method boundaries properly.
        // But wait, the previous tool call replaced code starting at 540-ish.
        // I'll assume convertToWorkoutSession implementation is effectively empty in my replacement unless I include it?
        // NO, convertToWorkoutSession was below.
        
        // Let's rely on finding `func restoreWorkoutsFromFirestore` line and replacing the whole block down to the end of method.
        // But I also need to update forceUploadToFirestore.
        // It's better to update them separately or use MultiReplace.
        
        let session = WorkoutSession(
            workoutDayName: workout.workoutType,
            programName: "Restored"
        )
        session.date = workout.date
        session.endTime = workout.date.addingTimeInterval(workout.duration)
        session.calories = workout.calories
        session.notes = workout.notes
        session.isCompleted = true
        session.isSynced = true // It came from cloud, so it is synced
        
        // Convert exercises to sets
        for exercise in workout.exercises {
            for set in exercise.sets {
                let workoutSet = WorkoutSet(
                    exerciseName: exercise.name,
                    weight: set.weight,
                    reps: set.reps,
                    setNumber: set.setNumber,
                    date: workout.date, // Pass date
                    isWeighted: set.weight > 0
                )
                workoutSet.comment = set.comment // Map comment
                workoutSet.isCompleted = set.isCompleted
                workoutSet.session = session
                session.sets.append(workoutSet)
            }
        }
        
        return session
    }
    
    // MARK: - Force Upload (Local -> Cloud)
    
    /// Force push local workouts to Firestore (Destructive for Cloud!)
    /// Replaces all cloud data with current local data
    nonisolated func forceUploadToFirestore(container: ModelContainer) async -> Result<Int, Error> {
        guard Auth.auth().currentUser != nil else {
            return .failure(SyncError.unauthorized)
        }
        
        let bgContext = ModelContext(container)
        bgContext.autosaveEnabled = false
        
        do {
            // 1. Fetch all completed local sessions
            let descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { $0.isCompleted } // Only upload completed
            )
            let localSessions = try bgContext.fetch(descriptor)
            
            if localSessions.isEmpty {
                return .failure(SyncError.message("Нет локальных тренировок для выгрузки. Запись в облако отменена."))
            }
            
            // 2. Clear Firestore
            #if DEBUG
            print("🚀 Force Upload: Deleting existing Firestore data...")
            #endif
            _ = try await FirestoreManager.shared.deleteAllWorkouts()
            
            // 3. Upload Local Sessions
            var uploadedCount = 0
            
            for (index, session) in localSessions.enumerated() {
                // Manual mapping to avoid MainActor specific init issues
                var duration: TimeInterval = 0
                if let endTime = session.endTime {
                    duration = endTime.timeIntervalSince(session.date)
                }
                
                // Map exercises
                let groupedSets = Dictionary(grouping: session.sets) { $0.exerciseName }
                let exercises = groupedSets.map { (name, sets) -> Exercise in
                    let exerciseSets = sets.sorted { $0.setNumber < $1.setNumber }.map { set in
                        ExerciseSet(
                            weight: set.weight,
                            reps: set.reps,
                            isCompleted: set.isCompleted,
                            setNumber: set.setNumber,
                            comment: set.comment
                        )
                    }
                    return Exercise(name: name, sets: exerciseSets)
                }
                
                let workoutDTO = Workout(
                    date: session.date,
                    workoutType: session.workoutDayName,
                    duration: duration,
                    calories: session.calories,
                    notes: session.notes,
                    exercises: exercises
                )
                
                try await FirestoreManager.shared.saveAsync(workout: workoutDTO)
                uploadedCount += 1
                
                if index % 10 == 0 {
                    await Task.yield()
                }
            }
            
            // 4. Upload User Profile and Measurements (New)
            #if DEBUG
            print("🚀 Force Upload: Syncing User Profile...")
            #endif
            
            if let profile = try bgContext.fetch(FetchDescriptor<UserProfile>()).last {
                // Reuse existing logic manually to avoid actor hopping
                // Weights
                let weightHistoryDTOs = profile.weightHistory.map { SyncManager.WeightRecordDTO(weight: $0.weight, date: $0.date) }
                
                // Measurements
                let measurementDescriptor = FetchDescriptor<BodyMeasurement>()
                let allMeasurements = try bgContext.fetch(measurementDescriptor)
                let bodyMeasurementsDTOs = allMeasurements.map {
                    SyncManager.BodyMeasurementDTO(date: $0.date, type: $0.type.rawValue, value: $0.value)
                }
                
                // Active Program
                let programDescriptor = FetchDescriptor<Program>(predicate: #Predicate { $0.isActive })
                let activeProgramName = try bgContext.fetch(programDescriptor).first?.name
                
                let profileData = SyncManager.UserProfileData(
                    height: profile.height,
                    weight: profile.currentWeight,
                    age: profile.age,
                    activeProgramName: activeProgramName,
                    lastUpdated: Date(),
                    weightHistory: weightHistoryDTOs,
                    bodyMeasurements: bodyMeasurementsDTOs
                )
                
                // Upload directly using Firestore DTO
                 try await Firestore.firestore()
                    .collection("users")
                    .document(Auth.auth().currentUser!.uid)
                    .collection("profile")
                    .document("main")
                    .setData(from: profileData)
            }
            
            // 5. Upload Programs (New)
            #if DEBUG
            print("🚀 Force Upload: Syncing Programs...")
            #endif
            
            let programs = try bgContext.fetch(FetchDescriptor<Program>())
            for program in programs {
                let dto = ProgramDTO(from: program)
                try await FirestoreManager.shared.saveProgram(dto)
            }
            
            #if DEBUG
            print("✅ Force Upload: Uploaded \(uploadedCount) workouts, profile, and \(programs.count) programs")
            #endif
            
            return .success(uploadedCount)
            
        } catch {
            #if DEBUG
            print("❌ Force Upload Error: \(error)")
            #endif
            return .failure(SyncError.message("Ошибка выгрузки: \(error.localizedDescription)"))
        }
    }
    

    
    // MARK: - Utility: Remove Duplicate Workouts
    
    /// Remove duplicate workout sessions from the database
    nonisolated func removeDuplicateWorkouts(container: ModelContainer) async {
        let bgContext = ModelContext(container)
        bgContext.autosaveEnabled = false
        
        do {
            // Fetch all sessions sorted by date
            let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date)])
            let allSessions = try bgContext.fetch(descriptor)
            
            #if DEBUG
            print("🔍 Total sessions before dedup: \(allSessions.count)")
            #endif
            
            var uniqueSessions: [WorkoutSession] = []
            var duplicatesToDelete: [WorkoutSession] = []
            
            for session in allSessions {
                // Check if we already have a similar session
                let isDuplicate = uniqueSessions.contains { existing in
                    // Same workout day name
                    guard existing.workoutDayName == session.workoutDayName else { return false }
                    
                    // Same date (within 5 minutes tolerance)
                    let timeDiff = abs(existing.date.timeIntervalSince(session.date))
                    guard timeDiff < 300 else { return false }
                    
                    // Same number of sets
                    guard existing.sets.count == session.sets.count else { return false }
                    
                    return true
                }
                
                if isDuplicate {
                    duplicatesToDelete.append(session)
                } else {
                    uniqueSessions.append(session)
                }
            }
            
            #if DEBUG
            print("🗑️ Found \(duplicatesToDelete.count) duplicates to delete")
            #endif
            
            // Delete duplicates
            if !duplicatesToDelete.isEmpty {
                for duplicate in duplicatesToDelete {
                    bgContext.delete(duplicate)
                }
                
                try bgContext.save()
                
                #if DEBUG
                print("✅ Deleted \(duplicatesToDelete.count) duplicate workouts. Remaining: \(uniqueSessions.count)")
                #endif
            }
            
        } catch {
            #if DEBUG
            print("❌ Error removing duplicates: \(error)")
            #endif
        }
    }
    
    deinit {
        monitor?.cancel()
        syncTask?.cancel()
    }
}
