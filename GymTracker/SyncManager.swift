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
        
        monitor?.pathUpdateHandler = { [weak self] path in
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
    
    deinit {
        monitor?.cancel()
        syncTask?.cancel()
    }
}
